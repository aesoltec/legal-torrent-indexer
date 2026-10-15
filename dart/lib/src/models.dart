/// Modèles strictement conformes au format JSON du prompt (variante local Flutter).

/// Niveau de confiance de la décision.
enum Confidence {
  high,
  medium,
  low;

  String get value => name;

  static Confidence fromString(String s) {
    switch (s.toLowerCase()) {
      case 'high':
        return Confidence.high;
      case 'medium':
        return Confidence.medium;
      case 'low':
        return Confidence.low;
      default:
        return Confidence.low;
    }
  }
}

/// Catégories autorisées.
enum Category {
  movies,
  tv,
  software,
  other;

  String get value => name;

  static Category fromString(String s) {
    switch (s.toLowerCase()) {
      case 'movies':
        return Category.movies;
      case 'tv':
        return Category.tv;
      case 'software':
        return Category.software;
      default:
        return Category.other;
    }
  }
}

/// Payload de recherche (nullifié en cas de refus).
class SearchPayload {
  final String? broadQuery;
  final String? archiveOrgQuery;
  final String? academicQuery;
  final String? linuxSoftwareQuery;

  const SearchPayload({
    this.broadQuery,
    this.archiveOrgQuery,
    this.academicQuery,
    this.linuxSoftwareQuery,
  });

  /// Payload vide (refus).
  factory SearchPayload.empty() => const SearchPayload();

  Map<String, dynamic> toJson() => {
        'broad_query': broadQuery,
        'archive_org_query': archiveOrgQuery,
        'academic_query': academicQuery,
        'linux_software_query': linuxSoftwareQuery,
      };

  factory SearchPayload.fromJson(Map<String, dynamic> json) => SearchPayload(
        broadQuery: json['broad_query'] as String?,
        archiveOrgQuery: json['archive_org_query'] as String?,
        academicQuery: json['academic_query'] as String?,
        linuxSoftwareQuery: json['linux_software_query'] as String?,
      );
}

/// Résultat complet du parsing (format obligatoire).
class ParseResult {
  final String originalQuery;
  final Category category;
  final bool isAdult;
  final bool isLegalRequest;
  final SearchPayload searchPayload;
  final List<String> keywords;
  final String targetExtension;
  final String clientPlatformHint;
  final String reason;
  final Confidence confidence;
  final String jurisdiction;

  const ParseResult({
    required this.originalQuery,
    required this.category,
    required this.isAdult,
    required this.isLegalRequest,
    required this.searchPayload,
    required this.keywords,
    this.targetExtension = 'torrent',
    this.clientPlatformHint = 'local_flutter_payload',
    required this.reason,
    required this.confidence,
    this.jurisdiction = 'unknown',
  });

  Map<String, dynamic> toJson() => {
        'original_query': originalQuery,
        'category': category.value,
        'is_adult': isAdult,
        'is_legal_request': isLegalRequest,
        'search_payload': searchPayload.toJson(),
        'keywords': keywords,
        'target_extension': targetExtension,
        'client_platform_hint': clientPlatformHint,
        'reason': reason,
        'confidence': confidence.value,
        'jurisdiction': jurisdiction,
      };

  factory ParseResult.fromJson(Map<String, dynamic> json) => ParseResult(
        originalQuery: json['original_query'] as String? ?? '',
        category: Category.fromString(json['category'] as String? ?? 'other'),
        isAdult: json['is_adult'] as bool? ?? false,
        isLegalRequest: json['is_legal_request'] as bool? ?? false,
        searchPayload: SearchPayload.fromJson(
          (json['search_payload'] as Map<String, dynamic>?) ?? {},
        ),
        keywords: List<String>.from(json['keywords'] as List? ?? []),
        targetExtension: json['target_extension'] as String? ?? 'torrent',
        clientPlatformHint:
            json['client_platform_hint'] as String? ?? 'local_flutter_payload',
        reason: json['reason'] as String? ?? '',
        confidence: Confidence.fromString(
          json['confidence'] as String? ?? 'low',
        ),
        jurisdiction: json['jurisdiction'] as String? ?? 'unknown',
      );
}
