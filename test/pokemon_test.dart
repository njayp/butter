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
  };

  test('Pokemon.fromJson parses the API shape', () {
    final pokemon = Pokemon.fromJson(sampleJson);

    expect(pokemon.id, 25);
    expect(pokemon.name, 'pikachu');
    expect(pokemon.imageUrl, 'https://example.com/25.png');
    expect(pokemon.types, ['electric']);
  });

  test('display helpers format name and number', () {
    final pokemon = Pokemon.fromJson(sampleJson);

    expect(pokemon.displayName, 'Pikachu');
    expect(pokemon.number, '#0025');
  });
}
