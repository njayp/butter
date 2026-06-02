import 'package:flutter/foundation.dart';

import '../string_extensions.dart';

/// An immutable view of a single Pokémon, parsed from the pokeapi.co response.
///
/// Keeping the JSON parsing here (out of the UI) makes it easy to unit-test
/// without touching the network or building any widgets.
class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.moves,
  });

  final int id;
  final String name;

  /// Official artwork URL; null when PokéAPI has no artwork for this entry.
  final String? imageUrl;
  final List<String> types;
  final List<LearnedMove> moves;

  /// Builds a [Pokemon] from the `GET /api/v2/pokemon/{id}` JSON shape.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final artwork =
        json['sprites']['other']['official-artwork']['front_default']
            as String?;
    final types = (json['types'] as List)
        .map((t) => t['type']['name'] as String)
        .toList();
    final moves = (json['moves'] as List)
        .map((m) => LearnedMove.fromJson(m as Map<String, dynamic>))
        .toList();
    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: artwork,
      types: types,
      moves: moves,
    );
  }

  /// Name with its first letter capitalized, e.g. `pikachu` → `Pikachu`.
  String get displayName => name.capitalised;

  /// Zero-padded Pokédex number, e.g. id `25` → `#0025`.
  String get number => '#${id.toString().padLeft(4, '0')}';

  @override
  bool operator ==(Object other) =>
      other is Pokemon &&
      other.id == id &&
      other.name == name &&
      other.imageUrl == imageUrl &&
      listEquals(other.types, types) &&
      listEquals(other.moves, moves);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    imageUrl,
    Object.hashAll(types),
    Object.hashAll(moves),
  );
}

/// One entry from a Pokémon's `moves` array: the move plus how this Pokémon
/// learns it. The move's type isn't here — it needs a /move/{id} fetch.
class LearnedMove {
  const LearnedMove({
    required this.name,
    required this.url,
    required this.level,
    required this.method,
  });

  final String name;
  final String url;

  /// Level-up level; null for TM/egg/tutor moves.
  final int? level;

  /// How the move is learned: 'level-up' | 'machine' | 'egg' | 'tutor' …
  final String method;

  factory LearnedMove.fromJson(Map<String, dynamic> json) {
    final details = json['version_group_details'] as List;
    // Use the most recent game (last entry) as the representative row.
    final last = details.last as Map<String, dynamic>;
    final method = last['move_learn_method']['name'] as String;
    final lvl = last['level_learned_at'] as int;
    return LearnedMove(
      name: json['move']['name'] as String,
      url: json['move']['url'] as String,
      level: (method == 'level-up' && lvl > 0) ? lvl : null,
      method: method,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LearnedMove &&
      other.name == name &&
      other.url == url &&
      other.level == level &&
      other.method == method;

  @override
  int get hashCode => Object.hash(name, url, level, method);
}
