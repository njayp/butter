// Proves the move-type cache persists per-key across PokemonService instances:
// a put on one instance is read back from disk by a second, with no refetch.
// Uses a MockClient so it runs offline, and a temp Hive dir per test.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:butter/models/pokemon.dart';
import 'package:butter/services/pokemon_service.dart';

import 'hive_test_setup.dart';

/// A minimal /move/{id} body — only the `type.name` the resolver reads.
const _moveBody = '{ "type": { "name": "electric" } }';

/// Two learned moves, each a distinct /move/{id} url.
final _moves = [
  const LearnedMove(
    name: 'thunder-shock',
    url: 'https://pokeapi.co/api/v2/move/84/',
    level: 1,
    method: 'level-up',
  ),
  const LearnedMove(
    name: 'tackle',
    url: 'https://pokeapi.co/api/v2/move/33/',
    level: 1,
    method: 'level-up',
  ),
];

void main() {
  useTempHive();

  test('move types persist across service instances, per key', () async {
    var moveHits = 0;
    http.Client countingClient() => MockClient((req) async {
      if (req.url.path.contains('/move/')) moveHits++;
      return http.Response(_moveBody, 200);
    });

    // First instance: a cold box, so each move costs one /move/ request.
    final first = PokemonService(client: countingClient());
    final firstResult = await first.getMoves(_moves);
    expect(moveHits, _moves.length); // every move fetched once
    expect(firstResult.every((m) => m.type == 'electric'), isTrue);

    // Force the next open to read from disk, not the still-open in-memory box.
    await Hive.box<String>('moveTypes').close();

    // Second instance: same urls already on disk → zero new /move/ requests.
    final before = moveHits;
    final second = PokemonService(client: countingClient());
    final secondResult = await second.getMoves(_moves);
    expect(moveHits, before); // nothing refetched
    expect(secondResult.every((m) => m.type == 'electric'), isTrue);
  });
}
