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

import 'hive_test_setup.dart';

/// Builds a minimal pokeapi-shaped JSON body for [id]/[name].
String _body(int id, String name) =>
    '''
{
  "id": $id,
  "name": "$name",
  "types": [ { "slot": 1, "type": { "name": "electric" } } ],
  "sprites": { "other": { "official-artwork": { "front_default": "https://example.com/$id.png" } } },
  "moves": [
    {
      "move": { "name": "thunder-shock", "url": "https://pokeapi.co/api/v2/move/84/" },
      "version_group_details": [ { "level_learned_at": 1, "move_learn_method": { "name": "level-up" } } ]
    }
  ]
}
''';

/// A minimal /move/{id} body — only the `type.name` the resolver reads.
const _moveBody = '{ "type": { "name": "normal" } }';

void main() {
  useTempHive(); // the moves test touches the persistent box; keep it offline

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
    await tester.pump(); // the typed number lights the Go button
    await tester.tap(find.byTooltip('Go'));
    await tester.pump(); // process setState + start fetch
    await tester.pump(); // future resolved → FutureBuilder shows data

    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('#0025'), findsOneWidget);
  });

  testWidgets('Go button is lit only when the typed number differs', (
    tester,
  ) async {
    final requested = <int>[];
    final service = PokemonService(
      client: MockClient((req) async {
        final id = int.parse(req.url.pathSegments.last);
        requested.add(id);
        return http.Response(_body(id, 'pokemon$id'), 200);
      }),
    );
    await tester.pumpWidget(MaterialApp(home: PokemonPage(service: service)));
    await tester.pump(); // initial random fetch resolves; box stays empty

    IconButton go() => tester.widget<IconButton>(find.byType(IconButton));
    final currentId = requested.last;

    // At rest the box is empty (no typed number) → disabled.
    expect(go().onPressed, isNull);

    // A different number → enabled ("lit up").
    final other = currentId == 1 ? 2 : 1;
    await tester.enterText(find.byType(TextField), '$other');
    await tester.pump();
    expect(go().onPressed, isNotNull);

    // After the go resolves, the box clears → disabled again.
    await tester.tap(find.byTooltip('Go'));
    await tester.pump(); // setState + fetch start
    await tester.pump(); // future resolved
    expect(go().onPressed, isNull);
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
    // The box clears; the card shows the clamped id that was actually fetched.
    expect(find.text('#1025'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
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

  testWidgets('tapping Moves opens the moves table', (tester) async {
    // Branch on the URL: /pokemon/... → the Pokémon body; /move/... → a move.
    final service = PokemonService(
      client: MockClient((req) async {
        if (req.url.path.contains('/move/')) {
          return http.Response(_moveBody, 200);
        }
        final id = int.parse(req.url.pathSegments.last);
        return http.Response(_body(id, 'pikachu'), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: PokemonPage(service: service)));
    await tester.pump(); // initial fetch resolves → card with Moves button

    // getMoves opens a real Hive box (dart:io), which only advances on the real
    // clock — drive the whole Moves flow inside runAsync so the box open and
    // move fetches actually resolve, then settle the frame that draws the table.
    await tester.runAsync(() async {
      await tester.tap(find.text('Moves'));
      await tester.pump(); // push the route so MovesScreen starts getMoves
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump(); // rebuild the FutureBuilder with the resolved moves
    });
    await tester.pumpAndSettle(); // finish the route transition → the table

    // The table headers render.
    expect(find.text('Move'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Level'), findsOneWidget);
    expect(find.text('Method'), findsOneWidget);
    // The known move, with hyphens turned into spaces.
    expect(find.text('thunder shock'), findsOneWidget);
  });
}
