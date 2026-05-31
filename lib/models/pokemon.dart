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
  });

  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;

  /// Builds a [Pokemon] from the `GET /api/v2/pokemon/{id}` JSON shape.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final artwork =
        json['sprites']['other']['official-artwork']['front_default'] as String;
    final types = (json['types'] as List)
        .map((t) => t['type']['name'] as String)
        .toList();
    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: artwork,
      types: types,
    );
  }

  /// Name with its first letter capitalized, e.g. `pikachu` → `Pikachu`.
  String get displayName =>
      name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}';

  /// Zero-padded Pokédex number, e.g. id `25` → `#0025`.
  String get number => '#${id.toString().padLeft(4, '0')}';
}
