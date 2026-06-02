import 'package:flutter/material.dart';

import 'models/move.dart';
import 'models/pokemon.dart';
import 'services/pokemon_service.dart';
import 'string_extensions.dart';
import 'type_palette.dart';

/// Display form of a raw pokeapi string — hyphens become spaces
/// (`mega-punch` → `mega punch`). Filter *values* keep the raw form; only
/// labels and cells are prettified.
String _pretty(String raw) => raw.replaceAll('-', ' ');

/// Combined "how it's learned" label for the merged column: `Level 15` when the
/// move has a level, otherwise the capitalised method name (`Machine`, `Egg`).
String _learned(Move m) =>
    m.level != null ? 'Level ${m.level}' : _pretty(m.method).capitalised;

/// Full-screen table of every move a [Pokemon] learns, with columns
/// Move · Type · Learned. Mirrors the loading/error/data pattern from
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

  /// Active filters; null means "All". Compared against the raw API strings
  /// (`electric`, `level-up`), so they stay un-prettified.
  String? _typeFilter;
  String? _methodFilter;

  /// Moves passing both facets (AND across facets, e.g. Fire *and* level-up).
  /// Keeps the service's default order since it never reorders.
  List<Move> _filtered(List<Move> moves) => [
    for (final m in moves)
      if ((_typeFilter == null || m.type == _typeFilter) &&
          (_methodFilter == null || m.method == _methodFilter))
        m,
  ];

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
          final all = snapshot.requireData;
          // Options reflect only the types/methods this Pokémon actually has,
          // so the dropdowns never offer a choice that yields nothing.
          final types = {for (final m in all) m.type}.toList()..sort();
          final methods = {for (final m in all) m.method}.toList()..sort();
          final moves = _filtered(all);

          return Column(
            children: [
              _MovesFilterBar(
                types: types,
                methods: methods,
                typeFilter: _typeFilter,
                methodFilter: _methodFilter,
                onType: (v) => setState(() => _typeFilter = v),
                onMethod: (v) => setState(() => _methodFilter = v),
                visible: moves.length,
                total: all.length,
              ),
              Expanded(
                child: moves.isEmpty
                    ? const Center(child: Text('No moves match these filters.'))
                    : _MovesTable(moves: moves, textTheme: textTheme),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Slim Type + Method filter bar above the table. Each facet is a Material 3
/// filter chip whose value is the raw API string (so it matches [Move] fields)
/// and whose label is the de-hyphenated, human-readable form.
class _MovesFilterBar extends StatelessWidget {
  const _MovesFilterBar({
    required this.types,
    required this.methods,
    required this.typeFilter,
    required this.methodFilter,
    required this.onType,
    required this.onMethod,
    required this.visible,
    required this.total,
  });

  final List<String> types;
  final List<String> methods;
  final String? typeFilter;
  final String? methodFilter;
  final ValueChanged<String?> onType;
  final ValueChanged<String?> onMethod;
  final int visible;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FacetChip(
            label: 'Type',
            options: types,
            value: typeFilter,
            onSelected: onType,
            icon: TypeIcon.new,
          ),
          _FacetChip(
            label: 'Method',
            options: methods,
            value: methodFilter,
            onSelected: onMethod,
          ),
          Text(
            '$visible of $total',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// A single filter facet: an M3 [FilterChip] that opens a [MenuAnchor] menu of
/// options. The chip shows the active selection (prettified) and a selected
/// tint; picking "All" clears the facet (value `null`).
class _FacetChip extends StatelessWidget {
  const _FacetChip({
    required this.label,
    required this.options,
    required this.value,
    required this.onSelected,
    this.icon,
  });

  final String label; // "Type" / "Method" — shown when unselected
  final List<String> options; // raw API strings
  final String? value; // active filter, null = All
  final ValueChanged<String?> onSelected;
  final Widget Function(String)? icon; // TypeIcon.new for the Type facet

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: () => onSelected(null),
          child: const Text('All'),
        ),
        for (final o in options)
          MenuItemButton(
            leadingIcon: icon?.call(o),
            onPressed: () => onSelected(o),
            child: Text(_pretty(o)),
          ),
      ],
      builder: (context, controller, _) {
        // Promote to a local so the body has no `!` (CLAUDE.md: strict
        // null-safety, no bang operator).
        final v = value;
        return FilterChip(
          avatar: v == null ? null : icon?.call(v),
          showCheckmark: v == null ? false : icon == null,
          label: Text(v == null ? label : _pretty(v)),
          selected: v != null,
          onSelected: (_) =>
              controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}

/// The scrolling moves table: vertical always, horizontal only when the columns
/// can't fit. The per-row type tint reaches the right edge by filling the width.
class _MovesTable extends StatelessWidget {
  const _MovesTable({required this.moves, required this.textTheme});

  final List<Move> moves;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    // Built once here rather than inside the LayoutBuilder so layout passes
    // don't rebuild the whole row list.
    final rows = [
      for (final m in moves)
        DataRow(
          // Faint type tint keeps the default text legible across many stacked
          // rows while still cueing the move's type.
          color: WidgetStateProperty.all(
            typeColor(m.type).withValues(alpha: 0.14),
          ),
          cells: [
            DataCell(Text(_pretty(m.name))),
            DataCell(TypeIcon(m.type)),
            DataCell(Text(_learned(m))),
          ],
        ),
    ];
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
                dataTextStyle: textTheme.bodyLarge,
                headingTextStyle: textTheme.titleSmall,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('Move')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Learned')),
                ],
                rows: rows,
              ),
            ),
          );
        },
      ),
    );
  }
}
