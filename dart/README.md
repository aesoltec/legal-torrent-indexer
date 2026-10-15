# Legal Torrent Indexer (Dart / Flutter) — Stratégie B

Moteur de parsing **100 % local** pour indexation de métadonnées `.torrent`  
strictement légales (open source, domaine public, Creative Commons autorisé).

- **Offline-first** — aucun serveur, aucun backend Python
- **Flutter / Dart** — mobile + desktop (Windows, macOS, Linux)
- `client_platform_hint` = `"local_flutter_payload"`
- `confidence` ∈ `{high, medium, low}`
- `jurisdiction` = `"unknown"` par défaut

## Installation

```yaml
# pubspec.yaml
dependencies:
  legal_torrent_indexer:
    path: ../legal-torrent-indexer-dart   # ou git:
    # git:
    #   url: https://github.com/aesoltec/legal-torrent-indexer.git
    #   path: dart
```

```bash
dart pub get
```

## Utilisation (local, hors ligne)

```dart
import 'package:legal_torrent_indexer/legal_torrent_indexer.dart';

final result = parseQuery('ISO Ubuntu 24.04');
print(result.toJson());
// client_platform_hint == "local_flutter_payload"
// confidence == "high"
// jurisdiction == "unknown"
```

### CLI d’exemple

```bash
dart run example/main.dart "ISO Ubuntu 24.04"
dart run example/main.dart "films x"
```

### Tests

```bash
dart test
```

## Format JSON produit

```json
{
  "original_query": "...",
  "category": "movies | tv | software | other",
  "is_adult": false,
  "is_legal_request": true,
  "search_payload": { ... },
  "keywords": ["..."],
  "target_extension": "torrent",
  "client_platform_hint": "local_flutter_payload",
  "reason": "...",
  "confidence": "high | medium | low",
  "jurisdiction": "unknown"
}
```

## Règles strictes (inchangées)

1. Adulte / NSFW → `is_adult = true`
2. Contenu protégé / propriétaire / douteux → `is_legal_request = false`
3. Si refus → `search_payload` nullifié + `keywords = []`
4. Jamais d’invention de licence
5. En cas de doute → **refus**

## Licence

MIT
