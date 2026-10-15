# Décisions de conception — legal-torrent-indexer (Dart)

## Ordre définitif des vérifications de légalité

Implémenté dans `_isClearlyLegal` (`lib/src/parser.dart`) :

| Étape | Condition | Résultat |
|-------|-----------|----------|
| 1 | Contenu adulte (`\b` word-boundary) | `is_legal_request = false`, `confidence = high` |
| 2 | Injection / contournement de règles | refus, `confidence = high` |
| 3 | Signaux **positifs** forts (free software, official ISO, domaine public, academic/open data) | **autorisé** |
| 3b | Positif **et** mention copyright coexistent | autorisé, `confidence = medium`, reason d’ambiguïté |
| 4 | Signaux **négatifs** copyright **sans** positif | refus, `confidence = high` |
| 5 | Aucun signal clair | refus par précaution |

### Pourquoi cet ordre ?

Un refus prématuré sur « windows 11 » bloquait des requêtes légitimes du type **« Ubuntu vs Windows 11 benchmark »**.
Le prompt impose d’évaluer d’abord les signaux positifs de légalité, puis seulement les indicateurs de contenu protégé.

### Word-boundary pour l’adulte

`String.contains("anal")` matchait « analyse », « canal ».
Tous les mots de `_adultKeywords` passent par une seule `RegExp` avec `\b`.

### archive_org_query

Élargi : partitions, films muets, textes, images historiques — avec `mediatype` adapté.
