# Décisions de conception

## Principe fondamental

> En cas de doute sur le copyright ou la licence → **refuser**.

Le moteur est volontairement conservateur. Il ne tente jamais d’inventer une licence, une autorisation ou une source officielle.

## Règles codées

| Condition                              | is_adult | is_legal_request | search_payload | keywords |
|----------------------------------------|----------|------------------|----------------|----------|
| Contenu adulte / NSFW / ambigu         | true     | false            | null           | []       |
| Contenu propriétaire / récent / douteux| false    | false            | null           | []       |
| Logiciel libre / OS officiel / PD / CC | false    | true             | rempli         | remplis  |

## Catégories

- `movies` : films
- `tv`     : séries / épisodes
- `software` : ISO, logiciels, OS
- `other`  : tout le reste

## Extension de la base de connaissance

Les listes `FREE_SOFTWARE`, `PUBLIC_DOMAIN_HINTS`, `COPYRIGHTED_INDICATORS` peuvent être enrichies, mais **jamais** en assouplissant les règles de refus.

Toute nouvelle entrée doit être vérifiable (licence officielle, date de domaine public, source institutionnelle).
