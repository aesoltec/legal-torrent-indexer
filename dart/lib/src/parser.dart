/// Moteur de parsing local — pure Dart.
/// Stratégie B : aucun backend Python, aucun serveur.
///
/// Ordre des vérifications (DECISIONS.md) :
///   1. Adulte (word-boundary) → refus
///   2. Signaux POSITIFS de légalité → autorisé
///   3. Signaux NÉGATIFS copyright → refus si aucun positif
///   4. Doute → refus par précaution

import 'models.dart';

const _adultKeywords = {
  'xxx', 'porn', 'porno', 'nude', 'nudes', 'hentai', 'nsfw', 'adulte', 'adult',
  'sex', 'sexe', 'erotic', 'érotique', 'onlyfans', 'camgirl', 'escort', 'jav',
  'milf', 'blowjob', 'anal', 'fetish',
};

/// Regex précompilée avec limites de mot (\b) pour TOUS les mots adultes.
final RegExp _adultRegex = RegExp(
  r'\b(?:' + _adultKeywords.map(RegExp.escape).join('|') + r'|x)\b',
  caseSensitive: false,
);

const _copyrightedIndicators = {
  'netflix', 'disney+', 'disney plus', 'hbo', 'hulu', 'amazon prime', 'paramount+',
  'apple tv', 'crunchyroll', 'spotify', 'apple music', 'steam', 'epic games',
  'playstation', 'xbox', 'nintendo', 'house of the dragon', 'game of thrones',
  'the last of us', 'stranger things', 'the boys', 'wednesday', 'oppenheimer',
  'barbie', 'dune part', 'avatar 2', 'marvel', 'star wars', 'windows 11',
  'windows 10', 'macos', 'office 365', 'photoshop', 'premiere pro',
  'after effects', 'final cut',
};

const _freeSoftware = {
  'ubuntu', 'debian', 'fedora', 'arch linux', 'linux mint', 'manjaro', 'opensuse',
  'gentoo', 'kali', 'tails', 'centos', 'almalinux', 'rocky linux', 'pop!_os',
  'elementary os', 'zorin', 'mx linux', 'libreoffice', 'gimp', 'inkscape',
  'blender', 'krita', 'audacity', 'vlc', 'firefox', 'thunderbird', 'obs studio',
  'godot', 'kdenlive', 'shotcut', 'darktable', 'rawtherapee', 'scribus', 'qgis',
  'postgresql', 'mysql community', 'mariadb', 'nginx', 'apache httpd', 'docker',
  'kubernetes', 'python', 'node.js', 'golang', 'rust',
};

const _publicDomainHints = {
  'night of the living dead', 'george romero', 'nosferatu', 'metropolis',
  'charlie chaplin', 'buster keaton', 'public domain', 'domaine public',
  'internet archive', 'archive.org', 'project gutenberg', 'librivox',
  'creative commons', 'cc0', 'cc-by', 'cc-by-sa',
  'bach', 'mozart', 'beethoven', 'chopin', 'vivaldi', 'handel', 'schubert',
  'brahms', 'tchaikovsky', 'partition', 'film muet', 'silent film',
  'carte ancienne', 'manuscrit', 'sextant',
};

const _academicHints = {
  'dataset', 'données ouvertes', 'open data', 'scientific', 'scientifique',
  'arxiv', 'pubmed', 'wikipedia dump', 'wikidata', 'openstreetmap', 'cours',
  'mooc', 'leçon', 'tutoriel libre', 'documentation libre',
};

const _injectionHints = {
  'ignore tes règles', 'ignore your rules', 'ignore previous', 'ignore all rules',
  'disregard your', 'bypass your', 'jailbreak', 'dan mode',
  'oublie tes instructions', 'oublie tes règles',
};

String _normalize(String text) =>
    text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

bool _containsAny(String text, Set<String> keywords) =>
    keywords.any((k) => text.contains(k));

bool _detectAdult(String query) {
  final q = _normalize(query);
  return _adultRegex.hasMatch(q);
}

bool _isPromptInjection(String query) {
  final q = _normalize(query);
  return _containsAny(q, _injectionHints);
}

Category _detectCategory(String query) {
  final q = _normalize(query);
  if (['film', 'movie', 'cinéma', 'cinema', 'pelicula', 'film muet', 'silent']
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

/// Ordre : adulte → injection → POSITIFS → copyright → doute
(bool, String, Confidence) _isClearlyLegal(String query) {
  final q = _normalize(query);

  if (_detectAdult(q)) {
    return (false, 'Contenu adulte exclu.', Confidence.high);
  }
  if (_isPromptInjection(q)) {
    return (false, 'Requête refusée : tentative d\'injection ou contournement des règles.', Confidence.high);
  }

  final hasFree = _containsAny(q, _freeSoftware) ||
      q.contains('official torrent') ||
      q.contains('iso officiel');
  final hasPublicDomain = _containsAny(q, _publicDomainHints);
  final hasAcademic = _containsAny(q, _academicHints);
  final hasCopyright = _containsAny(q, _copyrightedIndicators);

  if (hasFree) {
    if (hasCopyright) {
      return (true, 'Mention copyright détectée mais signal libre dominant.', Confidence.medium);
    }
    return (true, 'Distribution ou logiciel libre officiellement autorisé.', Confidence.high);
  }
  if (hasPublicDomain) {
    if (hasCopyright) {
      return (true, 'Mention copyright détectée mais signal domaine public dominant.', Confidence.medium);
    }
    return (true, 'Contenu potentiellement domaine public ou source officielle (vérification licence requise).', Confidence.medium);
  }
  if (hasAcademic) {
    if (hasCopyright) {
      return (true, 'Mention copyright détectée mais signal éducatif/open data dominant.', Confidence.medium);
    }
    return (true, 'Contenu éducatif ou données ouvertes (licence permissive présumée).', Confidence.medium);
  }
  if (hasCopyright) {
    return (false, 'Requête refusée : contenu protégé par le droit d\'auteur ou non autorisé.', Confidence.high);
  }
  return (false, 'Légalité incertaine ou contenu non explicitement autorisé → refus par précaution.', Confidence.high);
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
  } else if (_containsAny(qNorm, _academicHints)) {
    academic = '$q open data OR public domain';
    broad = '$q open data torrent';
  }

  if (_containsAny(qNorm, _publicDomainHints) || category == Category.movies) {
    if (!broad!.contains('public domain')) {
      broad = '$q public domain torrent';
    }
    final isMusic = ['partition', 'bach', 'mozart', 'beethoven', 'chopin', 'vivaldi', 'handel', 'schubert', 'brahms', 'tchaikovsky']
        .any((w) => qNorm.contains(w));
    final isImage = ['carte ancienne', 'sextant', 'manuscrit', 'image historique']
        .any((w) => qNorm.contains(w));
    final isMovie = category == Category.movies ||
        ['film', 'movie', 'keaton', 'chaplin', 'nosferatu', 'metropolis', 'romero', 'film muet', 'silent']
            .any((w) => qNorm.contains(w));

    final mediatype = isMusic
        ? 'texts'
        : isImage
            ? 'image'
            : isMovie
                ? 'movies'
                : 'movies OR texts OR audio OR image';

    String? creator;
    for (final name in ['bach', 'mozart', 'beethoven', 'chopin', 'keaton', 'chaplin', 'romero']) {
      if (qNorm.contains(name)) {
        creator = name;
        break;
      }
    }
    if (creator != null) {
      archive = 'creator:($creator) AND mediatype:($mediatype)';
    } else {
      final titleGuess = q
          .replaceAll(RegExp(r'(vieux film|film muet|film|movie|partition de|partition|de |by )', caseSensitive: false), '')
          .trim();
      archive = titleGuess.isNotEmpty
          ? 'title:("$titleGuess") AND mediatype:($mediatype)'
          : '$q AND mediatype:($mediatype)';
    }
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
  const stop = {'de', 'du', 'des', 'le', 'la', 'les', 'un', 'une', 'et', 'ou', 'à', 'a', 'the', 'of', 'for', 'vs'};
  return RegExp(r'[a-z0-9.]+')
      .allMatches(_normalize(query))
      .map((m) => m.group(0)!)
      .where((w) => !stop.contains(w) && w.length > 1)
      .take(12)
      .toList();
}

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
