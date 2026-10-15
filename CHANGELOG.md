# Changelog

## [1.0.1] — 2026-10-15

### Fixed
- **Parser order of legality checks** : signaux positifs (free software, public domain, academic) évalués **avant** les indicateurs copyright. Une requête mixte du type « Ubuntu vs Windows 11 benchmark » est désormais autorisée avec `confidence: medium`.
- **Adult keyword word-boundary matching** : détection adulte exclusivement via regex `\b...\b`. Plus de faux positifs sur « analyse », « canal », « sextant », « sexisme », « unisexe ».
- **Extended archive_org_query coverage** : partitions (Bach, Mozart…), films muets, textes et images historiques génèrent un `archive_org_query` avec le `mediatype` approprié (`texts` / `movies` / `image`).

### Added
- Détection d’injection de prompt (`ignore tes règles`, etc.) → refus explicite.
- Tests de non-régression pour les trois bugs ci-dessus.
