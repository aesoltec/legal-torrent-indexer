/// Moteur de parsing local — pure Dart.
/// Stratégie B : aucun backend Python, aucun serveur.

import 'models.dart';

// ---------------------------------------------------------------------------
// Listes de détection (conservatrices — en cas de doute on refuse)
// ---------------------------------------------------------------------------

const _adultKeywords = {
  'xxx',
  'porn',
  'porno',
  'nude',
  'nudes',
  'hentai',
  'nsfw',
  'adulte',
  'adult',
  'sex',
  'sexe',
  'erotic',
  'érotique',
  'onlyfans',
  'camgirl',
  'escort',
  'jav',
  'milf',
  'blowjob',
  'anal',
  'fetish',
};

const _copyrightedIndicators = {
  'netflix',
  'disney+',
  'disney plus',
  'hbo',
  'hulu',
  'amazon prime',
  'paramount+',
  'apple tv',
  'crunchyroll',
  'spotify',
  'apple music',
  'steam',
  'epic games',
  'playstation',
  'xbox',
  'nintendo',
  'house of the dragon',
  'game of thrones',
  'the last of us',
  'stranger things',
  'the boys',
  'wednesday',
  'oppenheimer',
  'barbie',
  'dune part',
  'avatar 2',
  'marvel',
  'star wars',
  'windows 11',
  'windows 10',
  'macos',
  'office 365',
  'photoshop',
  'premiere pro',
  'after effects',
  'final cut',
};

const _freeSoftware = {
  'ubuntu',
  'debian',
  'fedora',
  'arch linux',
  'linux mint',
  'manjaro',
  'opensuse',
  'gentoo',
  'kali',
  'tails',
  'centos',
  'almalinux',
  'rocky linux',
  'pop!_os',
  'elementary os',
  'zorin',
  'mx linux',
  'libreoffice',
  'gimp',
  'inkscape',
  'blender',
  'krita',
  'audacity',
  'vlc',
  'firefox',
  'thunderbird',
  'obs studio',
  'godot',
  'kdenlive',
  'shotcut',
  'darktable',
  'rawtherapee',
  'scribus',
  'qgis',
  'postgresql',
  'mysql community',
  'mariadb',
  'nginx',
  'apache httpd',
  'docker',
  'kubernetes',
  'python',
  'node.js',
  'golang',
  'rust',
};

const _publicDomainHints = {
  'night of the living dead',
  'george romero',
  'nosferatu',
  'metropolis',
  'charlie chaplin',
  'buster keaton',
  'public domain',
  'domaine public',
  'internet archive',
  'archive.org',
  'project gutenberg',
  'librivox',
  'creative commons',
  'cc0',
  'cc-by',
  'cc-by-sa',
};

const _academicHints = {
  'dataset',
  'données ouvertes',
  'open data',
  'scientific',
  'scientifique',
  'arxiv',
  'pubmed',
  'wikipedia dump',
  'wikidata',
  'openstreetmap',
  'cours',
  'mooc',
  'leçon',
  'tutoriel libre',
  'documentation libre',
};

String _normalize(String text) =>
    text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

bool _containsAny(String text, Set<String> keywords) =>
    keywords.any((k) => text.contains(k));

bool _detectAdult(String query) {
  final q = _normalize(query);
  // Mot exact "x" / "xxx" / etc. (évite faux positifs comme "vieux")
  if (RegExp(r'\b(x|xxx|porn|porno|nsfw|hentai|sexe?|erotic|érotique)\b')
      .hasMatch(q)) {
    return true;
  }
  final longAdult = _adultKeywords.where((k) => k.length > 3).toSet();
  return _containsAny(q, longAdult);
}

Category _detectCategory(String query) {
  final q = _normalize(query);
  if (['film', 'movie', 'cinéma', 'cinema', 'pelicula']
      .any((w) => q.contains(w))) {
    return Category.movies;
  }
  if (['série', 'serie', 'episode', 'épisode', 'season', 'saison', 'tv show']
      .any((w) => q.contains(w))) {
    return Category.tv;
  }
  if (['iso', 'ubuntu', 'debian', 'linux', 'software', 'logiciel', 'os ', 'distribution']
      .any((w) => q.contains(w))) {
    return Category.software;
  }
  if (_containsAny(q, _freeSoftware)) return Category.software;
  return Category.other;
}

/// Retourne (isLegal, reason, confidence).
(bool, String, Confidence) _isClearlyLegal(String query) {
  final q = _normalize(query);

  if (_detectAdult(q)) {
    return (false, 'Contenu adulte exclu.', Confidence.high);
  }

  if (_containsAny(q, _copyrightedIndicators)) {
    return (
      false,
      'Requête refusée : contenu protégé par le droit d\'auteur ou non autorisé.',
      Confidence.high,
    );
  }

  if (_containsAny(q, _freeSoftware) ||
      q.contains('official torrent') ||
      q.contains('iso officiel')) {
    return (
      true,
      'Distribution ou logiciel libre officiellement autorisé.',
      Confidence.high,
    );
  }

  if (_containsAny(q, _publicDomainHints)) {
    return (
      true,
      'Contenu potentiellement domaine public ou source officielle (vérification licence requise).',
      Confidence.medium,
    );
  }

  if (_containsAny(q, _academicHints)) {
    return (
      true,
      'Contenu éducatif ou données ouvertes (licence permissive présumée).',
      Confidence.medium,
    );
  }

  return (
    false,
    'Légalité incertaine ou contenu non explicitement autorisé → refus par précaution.',
    Confidence.high,
  );
}

SearchPayload _buildPayload(String query, Category category, bool isLegal) {
  if (!isLegal) return SearchPayload.empty();

  final q = query.trim();
  final qNorm = _normalize(q);

  String? broad = '$q torrent';
  String? archive;
  String? academic;
  String? linux;

  if (category == Category.software || _containsAny(qNorm, _freeSoftware)) {
    final suffix = qNorm.contains('official') ? '' : ' official';
    linux = '$q$suffix torrent download';
    broad = '$q$suffix torrent';
  } else if (category == Category.movies &&
      _containsAny(qNorm, _publicDomainHints)) {
    broad = '$q public domain torrent';
    final titleGuess = q
        .replaceAll(
          RegExp(r'(vieux film|film|movie|de |by )', caseSensitive: false),
          '',
        )
        .trim();
    archive = 'title:("$titleGuess") AND mediatype:(movies)';
  } else if (_containsAny(qNorm, _academicHints)) {
    academic = '$q open data OR public domain';
    broad = '$q open data torrent';
  } else if (_containsAny(qNorm, _publicDomainHints)) {
    broad = '$q public domain torrent';
    archive = '$q mediatype:(movies OR texts OR audio)';
  }

  return SearchPayload(
    broadQuery: broad,
    archiveOrgQuery: archive,
    academicQuery: academic,
    linuxSoftwareQuery: linux,
  );
}

List<String> _extractKeywords(String query, bool isLegal) {
  if (!isLegal) return [];
  const stop = {
    'de', 'du', 'des', 'le', 'la', 'les', 'un', 'une', 'et', 'ou', 'à', 'a',
    'the', 'of', 'for',
  };
  final words = RegExp(r'[a-z0-9.]+')
      .allMatches(_normalize(query))
      .map((m) => m.group(0)!)
      .where((w) => !stop.contains(w) && w.length > 1)
      .take(12)
      .toList();
  return words;
}

/// Point d'entrée unique du moteur local Flutter/Dart.
///
/// Produit exclusivement le JSON décrit par le prompt (variante local).
/// Aucun appel réseau. Aucune dépendance Python.
ParseResult parseQuery(String rawQuery) {
  final original = rawQuery.trim();

  if (original.isEmpty) {
    return const ParseResult(
      originalQuery: '',
      category: Category.other,
      isAdult: false,
      isLegalRequest: false,
      searchPayload: SearchPayload(),
      keywords: [],
      reason: 'Requête vide.',
      confidence: Confidence.high,
      jurisdiction: 'unknown',
    );
  }

  final isAdult = _detectAdult(original);
  final category = _detectCategory(original);

  if (isAdult) {
    return ParseResult(
      originalQuery: original,
      category: category,
      isAdult: true,
      isLegalRequest: false,
      searchPayload: SearchPayload.empty(),
      keywords: const [],
      reason: 'Contenu adulte exclu.',
      confidence: Confidence.high,
      jurisdiction: 'unknown',
    );
  }

  final (isLegal, reason, confidence) = _isClearlyLegal(original);
  final payload = _buildPayload(original, category, isLegal);
  final keywords = _extractKeywords(original, isLegal);

  return ParseResult(
    originalQuery: original,
    category: category,
    isAdult: false,
    isLegalRequest: isLegal,
    searchPayload: payload,
    keywords: keywords,
    reason: reason,
    confidence: confidence,
    jurisdiction: 'unknown',
  );
}
