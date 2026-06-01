import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/pokemon.dart';
import 'services/pokemon_service.dart';

void main() {
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

  /// The id currently shown, so a redundant click-away doesn't refetch.
  int? _currentId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Shows [future], syncing [_currentId] and the input box once it resolves.
  Future<Pokemon> _show(Future<Pokemon> future) {
    future.then((pokemon) {
      if (!mounted) return;
      _currentId = pokemon.id;
      _controller.text = pokemon.id.toString();
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
    _controller.text = id.toString(); // reflect what was actually fetched
    if (id == _currentId) return; // no redundant refetch on click-away
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number, // compact iOS number pad
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Pokédex number',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Go',
                    onPressed: () => _loadById(_controller.text),
                  ),
                ),
                onTapOutside: (_) => _loadById(_controller.text), // submit
                onSubmitted: _loadById, // fallback where the keyboard has a key
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: FutureBuilder<Pokemon>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Couldn't load a Pokémon.\nTap the button to try again.",
                        textAlign: .center,
                      ),
                    );
                  }
                  return _PokemonCard(pokemon: snapshot.requireData);
                },
              ),
            ),
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

/// Displays one Pokémon's artwork, name, number, and type chips.
class _PokemonCard extends StatelessWidget {
  const _PokemonCard({required this.pokemon});

  final Pokemon pokemon;

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
          children: [for (final type in pokemon.types) Chip(label: Text(type))],
        ),
      ],
    );
  }
}
