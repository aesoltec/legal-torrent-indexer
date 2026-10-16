import 'package:flutter/material.dart';
import 'package:legal_torrent_indexer/legal_torrent_indexer.dart';
import '../widgets/result_card.dart';
import '../widgets/search_hits_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _searchClient = LegalSearchClient();
  ParseResult? _result;
  LegalSearchResult? _search;
  bool _loading = false;

  static const _examples = [
    'ISO Ubuntu 24.04',
    'vieux film Night of the Living Dead de George Romero',
    'partition de Bach',
    'Dernier épisode de House of the Dragon',
    'films x',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _searchClient.close();
    super.dispose();
  }

  Future<void> _parse([String? override]) async {
    final q = (override ?? _controller.text).trim();
    if (override != null) _controller.text = override;
    if (q.isEmpty) {
      setState(() {
        _result = null;
        _search = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _search = null;
    });
    final parsed = parseQuery(q);
    if (!mounted) return;
    setState(() => _result = parsed);
    final searchResult = (parsed.isLegalRequest && !parsed.isAdult)
        ? await _searchClient.search(parsed)
        : LegalSearchResult.skipped(
            parsed.isAdult
                ? 'Recherche bloquée : contenu adulte.'
                : 'Recherche bloquée : ${parsed.reason}',
          );
    if (!mounted) return;
    setState(() {
      _search = searchResult;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.shield_moon_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          const Flexible(child: Text('Legal Torrent Indexer')),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(Icons.public, size: 16, color: scheme.primary),
              label: const Text('Archive.org'),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: wide ? _desktop() : _mobile(),
          ),
        ),
      ),
    );
  }

  Widget _results() => Column(children: [
        if (_result != null) ResultCard(result: _result!),
        if (_search != null) ...[
          const SizedBox(height: 16),
          SearchHitsList(search: _search!),
        ],
      ]);

  Widget _mobile() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(),
          const SizedBox(height: 16),
          _box(),
          const SizedBox(height: 12),
          _examples(),
          if (_loading) const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          if (!_loading && _result != null) ...[
            const SizedBox(height: 16),
            _results(),
          ],
        ],
      );

  Widget _desktop() => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ListView(children: [
                _hero(),
                const SizedBox(height: 20),
                _box(),
                const SizedBox(height: 16),
                _examples(),
              ]),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 6,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _result == null
                      ? const Card(
                          child: SizedBox(
                            height: 200,
                            child: Center(child: Text('Lancez une analyse légale')),
                          ),
                        )
                      : SingleChildScrollView(child: _results()),
            ),
          ],
        ),
      );

  Widget _hero() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Indexation strictement légale',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Parseur local + recherche Internet Archive (contenu ouvert uniquement).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );

  Widget _box() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Votre requête',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _parse(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : () => _parse(),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(_loading ? 'Recherche…' : 'Analyser & chercher'),
              ),
            ),
          ]),
        ),
      );

  Widget _examples() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _examples
            .map((e) => ActionChip(
                  label: Text(e, style: const TextStyle(fontSize: 12)),
                  onPressed: _loading ? null : () => _parse(e),
                ))
            .toList(),
      );
}
