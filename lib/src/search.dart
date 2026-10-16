/// Recherche réelle — sources légales uniquement (Internet Archive).
/// Ne s'exécute QUE si ParseResult.isLegalRequest == true.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class LegalSearchHit {
  final String identifier;
  final String title;
  final String? creator;
  final String? mediatype;
  final String? description;
  final int? downloads;
  final String detailsUrl;
  final String? torrentUrl;

  const LegalSearchHit({
    required this.identifier,
    required this.title,
    this.creator,
    this.mediatype,
    this.description,
    this.downloads,
    required this.detailsUrl,
    this.torrentUrl,
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'title': title,
        'creator': creator,
        'mediatype': mediatype,
        'description': description,
        'downloads': downloads,
        'details_url': detailsUrl,
        'torrent_url': torrentUrl,
        'source': 'internet_archive',
      };
}

class LegalSearchResult {
  final bool performed;
  final String? queryUsed;
  final String source;
  final List<LegalSearchHit> hits;
  final String? error;
  final int totalFound;

  const LegalSearchResult({
    required this.performed,
    this.queryUsed,
    this.source = 'internet_archive',
    this.hits = const [],
    this.error,
    this.totalFound = 0,
  });

  factory LegalSearchResult.skipped(String reason) => LegalSearchResult(
        performed: false,
        error: reason,
      );
}

class LegalSearchClient {
  LegalSearchClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  static const _endpoint = 'https://archive.org/advancedsearch.php';

  Future<LegalSearchResult> search(ParseResult parsed, {int rows = 12}) async {
    if (parsed.isAdult) {
      return LegalSearchResult.skipped('Recherche bloquée : contenu adulte.');
    }
    if (!parsed.isLegalRequest) {
      return LegalSearchResult.skipped(
        'Recherche bloquée : requête non autorisée (${parsed.reason}).',
      );
    }

    final q = _buildArchiveQuery(parsed);
    if (q == null || q.trim().isEmpty) {
      return LegalSearchResult.skipped('Aucun query Archive.org généré.');
    }

    try {
      final url = Uri.parse(
        '$_endpoint?q=${Uri.encodeQueryComponent(q)}'
        '&fl[]=identifier&fl[]=title&fl[]=creator&fl[]=mediatype'
        '&fl[]=description&fl[]=downloads&fl[]=publicdate'
        '&sort[]=downloads+desc&rows=$rows&page=1&output=json',
      );

      final response = await _http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        return LegalSearchResult(
          performed: true,
          queryUsed: q,
          error: 'HTTP ${response.statusCode} depuis Internet Archive',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final responseObj = body['response'] as Map<String, dynamic>? ?? {};
      final numFound = (responseObj['numFound'] as num?)?.toInt() ?? 0;
      final docs = (responseObj['docs'] as List?) ?? [];

      final hits = <LegalSearchHit>[];
      for (final raw in docs) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final id = '${map['identifier'] ?? ''}';
        if (id.isEmpty) continue;
        hits.add(LegalSearchHit(
          identifier: id,
          title: _asString(map['title']) ?? id,
          creator: _asString(map['creator']),
          mediatype: _asString(map['mediatype']),
          description: _asString(map['description']),
          downloads: (map['downloads'] as num?)?.toInt(),
          detailsUrl: 'https://archive.org/details/$id',
          torrentUrl: 'https://archive.org/download/$id',
        ));
      }

      return LegalSearchResult(
        performed: true,
        queryUsed: q,
        hits: hits,
        totalFound: numFound,
      );
    } catch (e) {
      return LegalSearchResult(
        performed: true,
        queryUsed: q,
        error: 'Erreur réseau : $e',
      );
    }
  }

  String? _buildArchiveQuery(ParseResult parsed) {
    final p = parsed.searchPayload;
    if (p.archiveOrgQuery != null && p.archiveOrgQuery!.trim().isNotEmpty) {
      return p.archiveOrgQuery;
    }
    final base = p.linuxSoftwareQuery ??
        p.academicQuery ??
        p.broadQuery ??
        parsed.originalQuery;
    if (base == null || base.trim().isEmpty) return null;
    return '($base) AND (licenseurl:* OR collection:opensource OR collection:opensource_movies OR collection:opensource_audio OR collection:opensource_software OR mediatype:texts OR mediatype:movies OR mediatype:software)';
  }

  String? _asString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is List && v.isNotEmpty) return v.first.toString();
    return v.toString();
  }

  void close() => _http.close();
}
