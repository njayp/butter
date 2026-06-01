# butter

A small Flutter learning app that shows a random Pokémon from
[pokeapi.co](https://pokeapi.co), with lookup by Pokédex number.

## What it does

- Fetches and shows a random Pokémon on launch — artwork, name, number, and
  type chips.
- Tap the refresh button to load another random Pokémon.
- Type a Pokédex number (1–1025) into the search bar to look up a specific one;
  out-of-range numbers clamp to the valid range.

## Project layout

| Path | Responsibility |
| ---- | -------------- |
| [lib/main.dart](lib/main.dart) | `PokemonPage` and its small private widgets (`_PokedexSearchField`, `_PokemonResult`, `_PokemonCard`). |
| [lib/models/pokemon.dart](lib/models/pokemon.dart) | Immutable `Pokemon` model with `fromJson`, `displayName`, and `number` helpers — UI-free and unit-tested. |
| [lib/services/pokemon_service.dart](lib/services/pokemon_service.dart) | `PokemonService` wrapping the pokeapi HTTP calls (`getPokemon`, `randomPokemon`); takes an injectable `http.Client` for offline tests. |
| [test/pokemon_test.dart](test/pokemon_test.dart) | Unit tests for the model's JSON parsing and display helpers. |
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
