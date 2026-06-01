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

/// Builds a minimal pokeapi-shaped JSON body for [id]/[name].
String _body(int id, String name) =>
    '''
{
  "id": $id,
  "name": "$name",
  "types": [ { "slot": 1, "type": { "name": "electric" } } ],
  "sprites": { "other": { "official-artwork": { "front_default": "https://example.com/$id.png" } } }
}
''';

void main() {
  testWidgets('PokemonPage shows the fetched Pokémon', (tester) async {
    final service = PokemonService(
      client: MockClient((_) async => http.Response(_body(25, 'pikachu'), 200)),
    );

    await tester.pumpWidget(MaterialApp(home: PokemonPage(service: service)));
    // Let the future resolve and the FutureBuilder rebuild.
    await tester.pump();

    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('#0025'), findsOneWidget);
    expect(find.byType(Chip), findsOneWidget);
    expect(find.text('electric'), findsOneWidget);
  });

  testWidgets('typing a number fetches that specific Pokémon', (tester) async {
    // Respond per requested id (the URL's last path segment).
    const names = {1: 'bulbasaur', 25: 'pikachu'};
    final service = PokemonService(
      client: MockClient((req) async {
        final id = int.parse(req.url.pathSegments.last);
        return http.Response(_body(id, names[id] ?? 'pokemon$id'), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: PokemonPage(service: service)));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '25');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(); // process setState + start fetch
    await tester.pump(); // future resolved → FutureBuilder shows data

    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('#0025'), findsOneWidget);
  });

  testWidgets('tapping the go button fetches that specific Pokémon', (
    tester,
  ) async {
    const names = {1: 'bulbasaur', 25: 'pikachu'};
    final service = PokemonService(
      client: MockClient((req) async {
        final id = int.parse(req.url.pathSegments.last);
        return http.Response(_body(id, names[id] ?? 'pokemon$id'), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: PokemonPage(service: service)));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.byTooltip('Go'));
    await tester.pump(); // process setState + start fetch
    await tester.pump(); // future resolved → FutureBuilder shows data

    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('#0025'), findsOneWidget);
  });

  testWidgets('an out-of-range number clamps to the max id', (tester) async {
    final requested = <int>[];
    final service = PokemonService(
      client: MockClient((req) async {
        final id = int.parse(req.url.pathSegments.last);
        requested.add(id);
        return http.Response(_body(id, 'pokemon$id'), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: PokemonPage(service: service)));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '9999');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(); // process setState + start fetch
    await tester.pump(); // future resolved → FutureBuilder shows data

    expect(requested.last, PokemonService.maxId); // 9999 → 1025
    expect(find.text('#1025'), findsOneWidget);
    // The box reflects the clamped id that was actually fetched.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '1025',
    );
  });

  testWidgets('an empty submission does not fetch', (tester) async {
    final requested = <int>[];
    final service = PokemonService(
      client: MockClient((req) async {
        requested.add(int.parse(req.url.pathSegments.last));
        return http.Response(_body(25, 'pikachu'), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: PokemonPage(service: service)));
    await tester.pump();
    final initialCalls = requested.length;

    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(requested.length, initialCalls); // no extra fetch
  });
}
