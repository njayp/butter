/// A move row ready for the moves table — a [LearnedMove] with its type
/// resolved from the move's own /move/{id} endpoint.
class Move {
  const Move({
    required this.name,
    required this.type,
    required this.level,
    required this.method,
  });

  final String name;

  /// The move's type, from /move/{id} → `type.name`.
  final String type;

  /// Level-up level; null for TM/egg/tutor moves.
  final int? level;

  /// How the move is learned: 'level-up' | 'machine' | 'egg' | 'tutor' …
  final String method;

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.name == name &&
      other.type == type &&
      other.level == level &&
      other.method == method;

  @override
  int get hashCode => Object.hash(name, type, level, method);
}
