import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:legal_torrent_indexer/legal_torrent_indexer.dart';

import 'status_badge.dart';

class ResultCard extends StatelessWidget {
  final ParseResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final jsonPretty =
        const JsonEncoder.withIndent('  ').convert(result.toJson());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résultat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge.legal(result.isLegalRequest),
                StatusBadge.adult(result.isAdult),
                StatusBadge.confidence(result.confidence.value),
                StatusBadge(
                  label: result.category.value,
                  color: scheme.primary,
                  icon: Icons.category_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section(context, 'Requête', result.originalQuery),
            _section(context, 'Raison', result.reason),
            if (result.keywords.isNotEmpty)
              _section(context, 'Mots-clés', result.keywords.join(', ')),
            if (result.isLegalRequest) ...[
              const SizedBox(height: 8),
              Text(
                'Search payload',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (result.searchPayload.broadQuery != null)
                _kv(context, 'broad_query', result.searchPayload.broadQuery!),
              if (result.searchPayload.archiveOrgQuery != null)
                _kv(context, 'archive_org_query',
                    result.searchPayload.archiveOrgQuery!),
              if (result.searchPayload.academicQuery != null)
                _kv(context, 'academic_query',
                    result.searchPayload.academicQuery!),
              if (result.searchPayload.linuxSoftwareQuery != null)
                _kv(context, 'linux_software_query',
                    result.searchPayload.linuxSoftwareQuery!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'JSON',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: jsonPretty));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('JSON copié'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copier'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                jsonPretty,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: scheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'platform: ${result.clientPlatformHint} · jurisdiction: ${result.jurisdiction}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              k,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              v,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
