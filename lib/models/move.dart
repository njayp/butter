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

  /// Orders level-up moves first (by level), then the rest alphabetically;
  /// null levels (TM/egg/tutor) always sort last. Used by the service to set
  /// the moves table's default order.
  static int compareLevelThenName(Move a, Move b) {
    final aLevel = a.level;
    final bLevel = b.level;
    if (aLevel != null && bLevel != null) return aLevel.compareTo(bLevel);
    if (aLevel != null) return -1;
    if (bLevel != null) return 1;
    return a.name.compareTo(b.name);
  }

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
