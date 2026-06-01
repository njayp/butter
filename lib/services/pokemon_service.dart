import 'dart:convert';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../models/move.dart';
import '../models/pokemon.dart';

/// Fetches Pokémon from pokeapi.co.
class PokemonService {
  /// The optional [client] is dependency injection: production code uses a real
  /// [http.Client], while tests can pass a `MockClient` so no real network call
  /// is made. https://docs.flutter.dev/cookbook/testing/unit/mocking
  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// The total number of Pokémon (Pokédex ids `1–1025`).
  static const int maxId = 1025;

  /// Max simultaneous /move/{id} requests, so a big moveset doesn't open ~200
  /// sockets at once. PokeAPI has no hard rate limit; this is for politeness.
  static const int _maxConcurrentMoveFetches = 8;

  static const String _boxName = 'moveTypes';

  /// Caches move-url → type, persisted across launches. Caching the Future
  /// dedupes the box-open across the concurrent getMoves workers.
  Future<Box<String>>? _boxFuture;

  Future<Box<String>> _moveBox() =>
      _boxFuture ??= Hive.openBox<String>(_boxName);

  /// Fetches the Pokémon with the given Pokédex [id].
  Future<Pokemon> getPokemon(int id) async {
    final res = await _client.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon/$id'),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load Pokémon (HTTP ${res.statusCode})');
    }
    return Pokemon.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Pokemon> randomPokemon() => getPokemon(Random().nextInt(maxId) + 1);

  /// Resolves each [moves] entry to a [Move] with its type from /move/{id}.
  /// Runs at most [_maxConcurrentMoveFetches] requests at a time via a small
  /// worker pool; cached types skip the network entirely.
  Future<List<Move>> getMoves(List<LearnedMove> moves) async {
    final rows = List<Move?>.filled(moves.length, null);
    var next = 0; // shared cursor; safe because Dart async is single-threaded
    // and each read+increment happens before any await.
    Future<void> worker() async {
      while (true) {
        final i = next++;
        if (i >= moves.length) break;
        final m = moves[i];
        final type = await _typeFor(m.url);
        rows[i] = Move(
          name: m.name,
          type: type,
          level: m.level,
          method: m.method,
        );
      }
    }

    await Future.wait([
      for (var w = 0; w < _maxConcurrentMoveFetches; w++) worker(),
    ]);

    final result = rows.cast<Move>();
    result.sort(Move.compareLevelThenName);
    return result;
  }

  /// Fetches a move's type, using the persisted [_moveBox] to avoid refetches.
  Future<String> _typeFor(String url) async {
    final box = await _moveBox();
    final cached = box.get(url);
    if (cached != null) return cached;
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to load move (HTTP ${res.statusCode})');
    }
    final type =
        (jsonDecode(res.body) as Map<String, dynamic>)['type']['name']
            as String;
    await box.put(url, type);
    return type;
  }
}
