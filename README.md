# Legal Torrent Indexer (Dart / Flutter)

Moteur de parsing **100 % local** + interface Flutter **Mobile / PC**  
pour métadonnées `.torrent` strictement légales.

> Offline-first — aucun serveur, aucun backend Python.

## Lancer l’interface Flutter

```bash
cd app
flutter pub get
flutter run -d chrome      # PC / navigateur
flutter run -d windows
flutter run                # mobile
```

## Structure

- `lib/` — package parseur Dart
- `app/` — interface Flutter (Material 3, responsive)
- `dart/` — copie package (git path)
- `test/` — tests unitaires

## Package seul

```yaml
dependencies:
  legal_torrent_indexer:
    git:
      url: https://github.com/aesoltec/legal-torrent-indexer.git
      path: dart
```

## Licence

MIT
