import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/pokemon.dart';
import 'moves_screen.dart';
import 'services/pokemon_service.dart';
import 'type_palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Pokémon',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const PokemonPage(),
    );
  }
}

/// Shows a random Pokémon on launch, with a button to fetch another.
class PokemonPage extends StatefulWidget {
  /// [service] is injectable so widget tests can supply a mocked HTTP client.
  const PokemonPage({super.key, this.service});

  final PokemonService? service;

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  late final PokemonService _service = widget.service ?? PokemonService();
  final _controller = TextEditingController();
  late Future<Pokemon> _future = _show(_service.randomPokemon());

  /// The id currently shown, so re-submitting the same number doesn't refetch.
  /// A notifier so the "Go" button can light up only when the typed id differs.
  final _currentId = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _controller.dispose();
    _currentId.dispose();
    super.dispose();
  }

  /// Shows [future], syncing [_currentId] once it resolves.
  Future<Pokemon> _show(Future<Pokemon> future) {
    future.then((pokemon) {
      if (!mounted) return;
      _currentId.value = pokemon.id;
    });
    return future;
  }

  void _loadAnother() {
    setState(() {
      _future = _show(_service.randomPokemon());
    });
  }

  /// Fetches the Pokédex number typed into the box, clamped to a valid id.
  void _loadById(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) return;
    final id = parsed.clamp(1, PokemonService.maxId);
    _controller.clear(); // box returns to its hint; the card shows the result
    // no redundant refetch when re-submitting the shown id
    if (id == _currentId.value) return;
    setState(() {
      _future = _show(_service.getPokemon(id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Random Pokémon'),
      ),
      body: Column(
        children: [
          _PokedexSearchField(
            controller: _controller,
            currentId: _currentId,
            onSubmit: _loadById,
          ),
          Expanded(
            child: _PokemonResult(future: _future, service: _service),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAnother,
        tooltip: 'Another',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

/// Material 3 search bar for the Pokédex number, with a trailing filled round
/// "Go" button; submits on tap or enter. Holds no state —
/// [controller] and [onSubmit] are owned by the page.
class _PokedexSearchField extends StatelessWidget {
  const _PokedexSearchField({
    required this.controller,
    required this.currentId,
    required this.onSubmit,
  });

  final TextEditingController controller;

  /// The id currently shown; the "Go" button lights up only when the typed
  /// number differs from this.
  final ValueListenable<int?> currentId;
  final ValueChanged<String> onSubmit;

  /// Matches any non-digit, for stripping pasted/typed junk in [onChanged].
  static final RegExp _nonDigits = RegExp(r'[^0-9]');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SearchBar(
        controller: controller,
        hintText: 'Pokédex number',
        keyboardType: TextInputType.number, // compact iOS number pad
        // Relax SearchBar's default minWidth: 360 so it fits the padded slot
        // on narrow devices instead of overflowing.
        constraints: const BoxConstraints(minHeight: 56),
        leading: const Icon(Icons.tag),
        onChanged: (raw) {
          // SearchBar has no inputFormatters, so strip non-digits here.
          final digits = raw.replaceAll(_nonDigits, '');
          if (digits != raw) {
            controller.value = TextEditingValue(
              text: digits,
              selection: TextSelection.collapsed(offset: digits.length),
            );
          }
        },
        onSubmitted: onSubmit, // enter / keyboard "done"
        trailing: [
          ListenableBuilder(
            listenable: Listenable.merge([controller, currentId]),
            builder: (context, _) {
              final typed = int.tryParse(controller.text.trim());
              final isDifferent = typed != null && typed != currentId.value;
              return IconButton.filled(
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Go', // tests rely on this tooltip
                onPressed: isDifferent ? () => onSubmit(controller.text) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The result region: a spinner while loading, a retry message on error, or
/// the resolved Pokémon's card.
class _PokemonResult extends StatelessWidget {
  const _PokemonResult({required this.future, required this.service});

  final Future<Pokemon> future;
  final PokemonService service;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Pokemon>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "Couldn't load a Pokémon.\nTap the button to try again.",
                textAlign: .center,
              ),
            );
          }
          return _PokemonCard(pokemon: snapshot.requireData, service: service);
        },
      ),
    );
  }
}

/// Displays one Pokémon's artwork, name, number, and type chips.
class _PokemonCard extends StatelessWidget {
  const _PokemonCard({required this.pokemon, required this.service});

  final Pokemon pokemon;
  final PokemonService service;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: .center,
      children: [
        Image.network(
          pokemon.imageUrl,
          height: 200,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox(height: 200, child: Icon(Icons.broken_image)),
        ),
        Text(pokemon.displayName, style: textTheme.headlineMedium),
        Text(pokemon.number, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final type in pokemon.types)
              Chip(
                // White symbol for contrast on the saturated chip fill.
                avatar: TypeIcon(type, color: Colors.white),
                label: Text(type),
                backgroundColor: typeColor(type),
                labelStyle: const TextStyle(color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.list_alt),
          label: const Text('Moves'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MovesScreen(pokemon: pokemon, service: service),
            ),
          ),
        ),
      ],
    );
  }
}
