import 'package:flutter/material.dart';
import 'package:legal_torrent_indexer/legal_torrent_indexer.dart';

import '../widgets/result_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  ParseResult? _result;
  bool _loading = false;

  static const _examples = [
    'ISO Ubuntu 24.04',
    'vieux film Night of the Living Dead de George Romero',
    'partition de Bach',
    'Ubuntu vs Windows 11 benchmark',
    'Dernier épisode de House of the Dragon',
    'films x',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _parse([String? override]) {
    final q = (override ?? _controller.text).trim();
    if (override != null) {
      _controller.text = override;
    }
    if (q.isEmpty) {
      setState(() => _result = null);
      return;
    }
    setState(() => _loading = true);
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      final r = parseQuery(q);
      if (!mounted) return;
      setState(() {
        _result = r;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 840;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield_moon_outlined, color: scheme.primary),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Legal Torrent Indexer',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(Icons.offline_bolt, size: 16, color: scheme.primary),
              label: const Text('Offline'),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: wide ? _desktopLayout() : _mobileLayout(),
          ),
        ),
      ),
    );
  }

  Widget _mobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _hero(),
        const SizedBox(height: 16),
        _searchBox(),
        const SizedBox(height: 12),
        _examplesWrap(),
        if (_loading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_result != null) ...[
          const SizedBox(height: 16),
          ResultCard(result: _result!),
        ],
        const SizedBox(height: 24),
        _footer(),
      ],
    );
  }

  Widget _desktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: ListView(
              children: [
                _hero(),
                const SizedBox(height: 20),
                _searchBox(),
                const SizedBox(height: 16),
                _examplesWrap(),
                const SizedBox(height: 24),
                _footer(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 6,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _result == null
                    ? _emptyState()
                    : SingleChildScrollView(
                        child: ResultCard(result: _result!),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indexation strictement légale',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Parseur local Flutter/Dart — open source, domaine public, Creative Commons. '
          'Aucun serveur, aucun backend Python.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _searchBox() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Votre requête',
                hintText: 'Ex. ISO Ubuntu 24.04, partition de Bach…',
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
                label: const Text('Analyser'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _examplesWrap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exemples',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples
              .map(
                (e) => ActionChip(
                  label: Text(e, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _parse(e),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Card(
      child: SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.manage_search_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Lancez une analyse pour voir le JSON',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Text(
      'client_platform_hint = local_flutter_payload · 100 % local',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
    );
  }
}
