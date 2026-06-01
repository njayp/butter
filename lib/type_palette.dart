/// Single source of truth for Pokémon type colors and icons, shared by the
/// detail-card chips and the moves table so both stay visually consistent.
///
/// Keys are the lowercase type names returned by pokeapi.co (e.g. 'electric').
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Canonical type → brand color.
const _typeColors = <String, Color>{
  'normal': Color(0xFFA8A77A),
  'fire': Color(0xFFEE8130),
  'water': Color(0xFF6390F0),
  'electric': Color(0xFFF7D02C),
  'grass': Color(0xFF7AC74C),
  'ice': Color(0xFF96D9D6),
  'fighting': Color(0xFFC22E28),
  'poison': Color(0xFFA33EA1),
  'ground': Color(0xFFE2BF65),
  'flying': Color(0xFFA98FF3),
  'psychic': Color(0xFFF95587),
  'bug': Color(0xFFA6B91A),
  'rock': Color(0xFFB6A136),
  'ghost': Color(0xFF735797),
  'dragon': Color(0xFF6F35FC),
  'dark': Color(0xFF705746),
  'steel': Color(0xFFB7B7CE),
  'fairy': Color(0xFFD685AD),
};

/// Brand color for [type]; grey for anything unrecognized.
Color typeColor(String type) => _typeColors[type] ?? const Color(0xFF9E9E9E);

/// Path to the official type-symbol SVG for [type], or null for an
/// unrecognized type (the 18 keys above are exactly the bundled files).
String? typeIconAsset(String type) =>
    _typeColors.containsKey(type) ? 'assets/types/$type.svg' : null;

/// The official type symbol for [type], sized 18×18 and tinted with [color]
/// (the type's brand color by default). Falls back to a Poké Ball glyph for an
/// unrecognized type. Source: duiker101/pokemon-type-svg-icons ("for any use").
class TypeIcon extends StatelessWidget {
  const TypeIcon(this.type, {super.key, this.color});

  final String type;

  /// Tint for the symbol; defaults to the type's brand color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? typeColor(type);
    final asset = typeIconAsset(type);
    if (asset == null) {
      return Icon(Icons.catching_pokemon, size: 18, color: tint);
    }
    return SvgPicture.asset(
      asset,
      width: 18,
      height: 18,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
