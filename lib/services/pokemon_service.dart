import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

/// Fetches a random Pokémon from pokeapi.co.
class PokemonService {
  /// The optional [client] is dependency injection: production code uses a real
  /// [http.Client], while tests can pass a `MockClient` so no real network call
  /// is made. https://docs.flutter.dev/cookbook/testing/unit/mocking
  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// The total number of Pokémon (Pokédex ids `1–1025`).
  static const int _maxId = 1025;

  Future<Pokemon> randomPokemon() async {
    final id = Random().nextInt(_maxId) + 1;
    final res = await _client.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon/$id'),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load Pokémon (HTTP ${res.statusCode})');
    }
    return Pokemon.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
