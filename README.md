# Legal Torrent Metadata Indexer (Hybrid Mobile/PC)

Moteur de parsing et d'expansion de requêtes pour une application hybride (Mobile/PC) d'indexation de fichiers de métadonnées (.torrent).

## Périmètre strictement autorisé

- Logiciels et OS sous licence libre (GPL, MIT, Apache, BSD, MPL…)
- Contenus Creative Commons **uniquement** si la licence autorise explicitement le partage sous forme de torrent
- Œuvres confirmées dans le domaine public (vérification œuvre + pays)
- Torrents publiés par une source officielle (projet, éditeur, ayant droit, Internet Archive, distribution Linux officielle…)
- Contenus éducatifs, scientifiques ou data ouverts sous licence permissive

## Exclusions absolues

- Tout contenu adulte / NSFW / sexuellement ambigu
- Films, séries, jeux, logiciels propriétaires ou musique récents protégés par le droit d’auteur
- Toute requête dont la légalité n’est pas claire → **refus**
- Aucune contournement de protection, aucun lien direct, aucune aide au téléchargement illégal

## Architecture

```
legal-torrent-indexer/
├── src/
│   ├── parser.py          # Moteur de décision (cœur du prompt)
│   ├── schema.py          # Validation JSON de sortie
│   └── api.py             # Endpoint FastAPI
├── tests/
│   └── test_parser.py
├── examples/
│   └── sample_queries.json
├── docs/
│   └── DECISIONS.md
├── requirements.txt
├── main.py                # Point d’entrée CLI + serveur
└── README.md
```

## Installation

```bash
cd legal-torrent-indexer
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

## Utilisation CLI

```bash
python main.py "ISO Ubuntu 24.04"
python main.py "vieux film Night of the Living Dead de George Romero"
python main.py "Dernier épisode de House of the Dragon"
```

## API (FastAPI)

```bash
uvicorn src.api:app --reload --port 8000
```

Endpoint unique :

```
POST /parse
Content-Type: application/json
{"query": "votre requête ici"}
```

Réponse = **exactement** le JSON défini dans le prompt (aucun texte autour).

## Règles de décision (implémentées)

1. Si adulte/NSFW ou ambigu → `is_adult = true`
2. Si contenu protégé non autorisé / propriétaire / récent / légalité incertaine → `is_legal_request = false`
3. Si `is_adult == true` **OU** `is_legal_request == false` → tous les champs de `search_payload` = `null` et `keywords = []`
4. Jamais d’invention de licence ou de source officielle
5. En cas de doute → refus

## Licence du projet

MIT – libre d’utilisation et de modification.
