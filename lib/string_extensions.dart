/// Small display-formatting helpers shared across the app.
extension Capitalise on String {
  /// First letter upper-cased, e.g. `pikachu` → `Pikachu`.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
