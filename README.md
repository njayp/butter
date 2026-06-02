# butter

A small Flutter learning app that shows a random Pokémon from
[pokeapi.co](https://pokeapi.co): look one up by Pokédex number, see its type
chips, and open a per-Pokémon table of every move it learns.

## What it does

- Fetches and shows a random Pokémon on launch — artwork, name, number, and
  type chips.
- Tap the refresh button to load another random Pokémon.
- Type a Pokédex number (1–1025) into the search bar to look up a specific one;
  out-of-range numbers clamp to the valid range.
- Tap "Moves" to open a table of every move the Pokémon learns (Move · Type ·
  Learned), filterable by Type and Method with a live "X of Y" count.

## Project layout

| Path | Responsibility |
| ---- | -------------- |
| [lib/main.dart](lib/main.dart) | `PokemonPage` and its small private widgets — search field, result region, and the card with its type chips and "Moves" button. |
| [lib/moves_screen.dart](lib/moves_screen.dart) | The full-screen moves table and its Type/Method filter bar. |
| [lib/type_palette.dart](lib/type_palette.dart) | The per-type colour (`typeColor`) and SVG `TypeIcon` widget, shared by the chips, filters, and table. |
| [lib/string_extensions.dart](lib/string_extensions.dart) | `String.capitalised` — small text helper used by the "Learned" column. |
| [lib/models/pokemon.dart](lib/models/pokemon.dart) | Immutable `Pokemon` model (artwork, types, and its `LearnedMove` list) with `fromJson` and display helpers — UI-free and unit-tested. |
| [lib/models/move.dart](lib/models/move.dart) | The `Move` model — a move resolved with its type, plus level-then-name sorting (`compareLevelThenName`). |
| [lib/services/pokemon_service.dart](lib/services/pokemon_service.dart) | `PokemonService` wrapping the pokeapi HTTP calls (`getPokemon`, `randomPokemon`, `getMoves`); takes an injectable `http.Client` for offline tests. |
| [assets/types/](assets/types/) | One SVG type symbol per pokeapi type name, tinted via `TypeIcon`. |
| [test/pokemon_test.dart](test/pokemon_test.dart) | Unit tests for the model's JSON parsing and display helpers. |
| [test/pokemon_service_test.dart](test/pokemon_service_test.dart) | Service test proving move types persist per-key across instances (Hive disk cache, no refetch). |
| [test/widget_test.dart](test/widget_test.dart) | Widget tests for `PokemonPage`, backed by a `MockClient` so they run offline. |

## Getting started

```sh
flutter pub get
```

Then run it on a simulator (the human's F5 in VS Code) or a physical device.
The app is currently iOS-only — only an [ios/](ios/) platform folder exists.

## Running & testing

```sh
flutter test       # unit + widget tests
dart format .      # format
flutter analyze    # static analysis
make iphone        # build a release copy and run on a physical iPhone
```

For Claude's own simulator run loop, see [scripts/dev.sh](scripts/dev.sh) and
the table in [CLAUDE.md](CLAUDE.md) rather than duplicating it here.

## Tech notes

- Built with Flutter / Dart, using the official
  [`http`](https://docs.flutter.dev/cookbook/networking/fetch-data) client for
  REST calls to pokeapi.co.
- `PokemonService` takes a dependency-injected `http.Client`, so widget tests
  swap in a [`MockClient`](https://docs.flutter.dev/cookbook/testing/unit/mocking)
  and run entirely offline.
- A Pokémon's move list only names each move, so `getMoves` resolves every
  move's type from `/move/{id}`. Those fetches run through a bounded concurrent
  worker pool (politeness to pokeapi) so a big moveset doesn't open hundreds of
  sockets. Move types are immutable reference data, so they're cached locally in
  a [Hive](https://docs.hivedb.dev/) box (move-url → type) with per-key writes —
  the moves screen needs no network after a move's been seen once, even across
  launches.
- Type symbols render from local SVG assets via
  [`flutter_svg`](https://pub.dev/packages/flutter_svg), tinted from the shared
  palette in [lib/type_palette.dart](lib/type_palette.dart).
