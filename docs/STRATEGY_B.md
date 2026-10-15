# Stratégie B retenue : Tout Dart

Depuis 2026-10-15, la production est **100 % Dart/Flutter** (local, offline).

- Package : `dart/`
- `client_platform_hint` = `"local_flutter_payload"`
- `confidence` ∈ {high, medium, low}
- `jurisdiction` = `"unknown"`
- **Aucun backend Python recommandé** pour la prod

Le code Python historique reste uniquement comme référence de logique. Ne pas le déployer comme serveur.
