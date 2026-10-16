import 'package:flutter/material.dart';
import 'package:legal_torrent_indexer/legal_torrent_indexer.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchHitsList extends StatelessWidget {
  final LegalSearchResult search;
  const SearchHitsList({super.key, required this.search});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!search.performed) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.block, color: scheme.error),
          title: const Text('Recherche non effectuée'),
          subtitle: Text(search.error ?? 'Requête refusée par le parseur'),
        ),
      );
    }
    if (search.error != null && search.hits.isEmpty) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.cloud_off, color: scheme.error),
          title: const Text('Erreur de recherche'),
          subtitle: Text(search.error!),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Internet Archive · ${search.totalFound} résultat(s)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (search.queryUsed != null)
              Text('Query: ${search.queryUsed}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
            const SizedBox(height: 12),
            if (search.hits.isEmpty)
              const Text('Aucun item trouvé.')
            else
              ...search.hits.map((h) => ListTile(
                    title: Text(h.title),
                    subtitle: Text([h.mediatype, h.creator].whereType<String>().join(' · ')),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () async {
                      final u = Uri.parse(h.detailsUrl);
                      if (await canLaunchUrl(u)) {
                        await launchUrl(u, mode: LaunchMode.externalApplication);
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }
}
