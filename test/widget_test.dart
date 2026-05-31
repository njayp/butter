// Widget test for PokemonPage. We inject a PokemonService backed by a
// MockClient so the test runs offline and deterministically.
//
// Note: Image.network fires a real GET during a widget test, which fails
// offline — so we assert only on the text/Chip, never the image.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:butter/main.dart';
import 'package:butter/services/pokemon_service.dart';

void main() {
  testWidgets('PokemonPage shows the fetched Pokémon', (tester) async {
    const body = '''
{
  "id": 25,
  "name": "pikachu",
  "types": [ { "slot": 1, "type": { "name": "electric" } } ],
  "sprites": { "other": { "official-artwork": { "front_default": "https://example.com/25.png" } } }
}
''';
    final service = PokemonService(
      client: MockClient((_) async => http.Response(body, 200)),
    );

    await tester.pumpWidget(MaterialApp(home: PokemonPage(service: service)));
    // Let the future resolve and the FutureBuilder rebuild.
    await tester.pump();

    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('#0025'), findsOneWidget);
    expect(find.byType(Chip), findsOneWidget);
    expect(find.text('electric'), findsOneWidget);
  });
}
