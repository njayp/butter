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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.pokemon.displayName}’s moves')),
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
          final moves = snapshot.requireData;
          // Tight spacing so all four columns fit a phone width without a
          // sideways scroll; the rows still scroll vertically.
          return SingleChildScrollView(
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: Text('Move')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Level'), numeric: true),
                DataColumn(label: Text('Method')),
              ],
              rows: [
                for (final m in moves)
                  DataRow(
                    // Faint type tint keeps the default text legible across
                    // many stacked rows while still cueing the move's type.
                    color: WidgetStateProperty.all(
                      typeColor(m.type).withValues(alpha: 0.14),
                    ),
                    cells: [
                      DataCell(Text(m.name.replaceAll('-', ' '))),
                      DataCell(_TypeLabel(type: m.type)),
                      DataCell(Text(m.level?.toString() ?? '—')),
                      DataCell(Text(m.method.replaceAll('-', ' '))),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Compact type cell: the tinted official type symbol (or a Poké Ball fallback
/// for an unknown type) followed by the lowercase type name.
class _TypeLabel extends StatelessWidget {
  const _TypeLabel({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [TypeIcon(type), const SizedBox(width: 6), Text(type)],
  );
}
