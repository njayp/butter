import 'package:flutter/material.dart';

import 'models/move.dart';
import 'models/pokemon.dart';
import 'services/pokemon_service.dart';
import 'type_palette.dart';

/// Full-screen table of every move a [Pokemon] learns, with columns
/// Move · Type · Level · Method. Mirrors the loading/error/data pattern from
/// the page's result region; the per-move type fetches happen in [getMoves].
class MovesScreen extends StatefulWidget {
  const MovesScreen({super.key, required this.pokemon, required this.service});

  final Pokemon pokemon;
  final PokemonService service;

  @override
  State<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends State<MovesScreen> {
  /// Computed once so rebuilds don't re-trigger the fetch.
  late final Future<List<Move>> _moves = widget.service.getMoves(
    widget.pokemon.moves,
  );

  /// Active sort column, or null to keep the service's default order
  /// (level-up first by level, then alphabetical).
  int? _sortColumnIndex;
  bool _sortAscending = true;

  void _onSort(int index, bool ascending) => setState(() {
    _sortColumnIndex = index;
    _sortAscending = ascending;
  });

  /// Returns [moves] in the order the table should render: the service's
  /// default when no header is active, otherwise a copy sorted by the chosen
  /// column. Nulls (level-less moves) always sort last regardless of direction.
  List<Move> _sorted(List<Move> moves) {
    final index = _sortColumnIndex;
    if (index == null) return moves;

    // Cases match the column order: 0 Move · 1 Type · 2 Level · 3 Method.
    int byName(Move a, Move b) => a.name.compareTo(b.name);
    int compare(Move a, Move b) {
      switch (index) {
        case 1: // Type — group by type, tiebreak by name.
          final byType = a.type.compareTo(b.type);
          return byType != 0 ? byType : byName(a, b);
        case 2: // Level — numeric, nulls last (shared with the default order).
          return Move.compareLevelThenName(a, b);
        case 3: // Method.
          final byMethod = a.method.compareTo(b.method);
          return byMethod != 0 ? byMethod : byName(a, b);
        default: // Move.
          return byName(a, b);
      }
    }

    final sorted = [...moves]..sort(compare);
    return _sortAscending ? sorted : sorted.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('${widget.pokemon.displayName}’s moves'),
      ),
      body: FutureBuilder<List<Move>>(
        future: _moves,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Couldn't load moves.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final moves = _sorted(snapshot.requireData);
          // Built once here rather than inside the LayoutBuilder so layout
          // passes don't rebuild the whole row list.
          final rows = [
            for (final m in moves)
              DataRow(
                // Faint type tint keeps the default text legible across many
                // stacked rows while still cueing the move's type.
                color: WidgetStateProperty.all(
                  typeColor(m.type).withValues(alpha: 0.14),
                ),
                cells: [
                  DataCell(Text(m.name.replaceAll('-', ' '))),
                  DataCell(TypeIcon(m.type)),
                  DataCell(Text(m.level?.toString() ?? '—')),
                  DataCell(Text(m.method.replaceAll('-', ' '))),
                ],
              ),
          ];
          // The table fills the available width so the per-row type tint reaches
          // the right edge; it scrolls vertically, and only sideways if the
          // columns can't fit.
          return SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: 16,
                      horizontalMargin: 16,
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      dataTextStyle: textTheme.bodyLarge,
                      headingTextStyle: textTheme.titleSmall,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 64,
                      columns: [
                        DataColumn(label: const Text('Move'), onSort: _onSort),
                        DataColumn(label: const Text('Type'), onSort: _onSort),
                        DataColumn(
                          label: const Text('Level'),
                          numeric: true,
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text('Method'),
                          onSort: _onSort,
                        ),
                      ],
                      rows: rows,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
