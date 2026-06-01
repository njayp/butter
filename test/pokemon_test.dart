import 'package:flutter_test/flutter_test.dart';

import 'package:butter/models/pokemon.dart';

void main() {
  // A trimmed-down copy of the `GET /api/v2/pokemon/25` response.
  final sampleJson = <String, dynamic>{
    'id': 25,
    'name': 'pikachu',
    'types': [
      {
        'slot': 1,
        'type': {'name': 'electric'},
      },
    ],
    'sprites': {
      'other': {
        'official-artwork': {'front_default': 'https://example.com/25.png'},
      },
    },
    'moves': [
      {
        'move': {
          'name': 'thunder-shock',
          'url': 'https://pokeapi.co/api/v2/move/84/',
        },
        'version_group_details': [
          {
            'level_learned_at': 1,
            'move_learn_method': {'name': 'level-up'},
          },
        ],
      },
      {
        'move': {
          'name': 'thunderbolt',
          'url': 'https://pokeapi.co/api/v2/move/85/',
        },
        'version_group_details': [
          {
            'level_learned_at': 0,
            'move_learn_method': {'name': 'machine'},
          },
        ],
      },
    ],
  };

  test('Pokemon.fromJson parses the API shape', () {
    final pokemon = Pokemon.fromJson(sampleJson);

    expect(pokemon.id, 25);
    expect(pokemon.name, 'pikachu');
    expect(pokemon.imageUrl, 'https://example.com/25.png');
    expect(pokemon.types, ['electric']);
  });

  test('Pokemon.fromJson parses learned moves with level and method', () {
    final pokemon = Pokemon.fromJson(sampleJson);

    expect(pokemon.moves.length, 2);
    expect(pokemon.moves.map((m) => m.name), ['thunder-shock', 'thunderbolt']);

    final levelUp = pokemon.moves[0];
    expect(levelUp.method, 'level-up');
    expect(levelUp.level, 1); // level-up move keeps its level

    final machine = pokemon.moves[1];
    expect(machine.method, 'machine');
    expect(machine.level, isNull); // non-level-up move has no level
  });

  test('display helpers format name and number', () {
    final pokemon = Pokemon.fromJson(sampleJson);

    expect(pokemon.displayName, 'Pikachu');
    expect(pokemon.number, '#0025');
  });

  test('Pokemon.fromJson tolerates null official artwork', () {
    final json = <String, dynamic>{
      ...sampleJson,
      'sprites': {
        'other': {
          'official-artwork': {'front_default': null},
        },
      },
    };

    final pokemon = Pokemon.fromJson(json); // must not throw
    expect(pokemon.imageUrl, isNull);
  });

  test('parsing the same JSON twice yields equal Pokémon', () {
    expect(Pokemon.fromJson(sampleJson), Pokemon.fromJson(sampleJson));
    expect(
      Pokemon.fromJson(sampleJson).hashCode,
      Pokemon.fromJson(sampleJson).hashCode,
    );
  });
}
