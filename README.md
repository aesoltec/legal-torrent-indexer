# Legal Torrent Metadata Indexer (Hybrid Mobile/PC)

Application hybride **Mobile + PC** d'indexation de métadonnées `.torrent`  
**strictement limitée** au contenu légal : open source, domaine public, Creative Commons autorisé, sources officielles.

## Fonctionnalités

- Interface web responsive (téléphone, tablette, ordinateur)
- PWA-ready (installable sur mobile)
- Moteur de parsing conforme aux règles strictes du prompt
- API JSON (`POST /parse`) pour intégration native Mobile/PC
- Refus automatique de tout contenu adulte, propriétaire ou douteux

## Périmètre autorisé

| Autorisé | Refusé |
|----------|--------|
| Logiciels & OS libres (GPL, MIT, Apache, BSD…) | Contenu adulte / NSFW |
| Domaine public confirmé | Films / séries / jeux récents protégés |
| Creative Commons (partage torrent autorisé) | Logiciels propriétaires (Windows, Photoshop…) |
| Sources officielles (Internet Archive, distros Linux…) | Toute légalité incertaine → refus |

## Architecture

```
legal-torrent-indexer/
├── web/                    # Frontend hybride (Mobile + PC)
│   ├── index.html
│   ├── css/styles.css
│   ├── js/app.js
│   └── manifest.json       # PWA
├── src/
│   ├── parser.py           # Moteur de décision
│   ├── schema.py           # Validation JSON
│   └── api.py              # FastAPI (API + static)
├── tests/
├── docs/
├── examples/
├── main.py
└── requirements.txt
```

## Installation

```bash
cd legal-torrent-indexer
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

## Lancement (Mobile + PC)

```bash
python main.py --server
```

Puis ouvrir dans le navigateur :

- **PC** : http://localhost:8000
- **Mobile** (même réseau) : http://<IP-de-votre-PC>:8000

L'interface s'adapte automatiquement (responsive + safe-area iOS/Android).

### CLI (sans interface)

```bash
python main.py "ISO Ubuntu 24.04"
python main.py "vieux film Night of the Living Dead de George Romero"
python main.py "films x"
```

### API pure

```
POST /parse
Content-Type: application/json
{"query": "votre requête"}
```

Réponse = **exactement** le JSON défini dans le prompt (aucun texte autour).

## Règles de décision

1. Adulte / NSFW / ambigu → `is_adult = true`
2. Contenu protégé / propriétaire / récent / douteux → `is_legal_request = false`
3. Si `is_adult` **ou** `!is_legal_request` → `search_payload = null` et `keywords = []`
4. Jamais d'invention de licence ou de source officielle
5. En cas de doute → **refus**

## Licence

MIT – libre d'utilisation et de modification.
