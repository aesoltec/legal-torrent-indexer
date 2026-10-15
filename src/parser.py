"""
Moteur de parsing et d'expansion de requêtes
conforme au prompt système fourni.
"""

from __future__ import annotations

import re
from typing import List, Optional, Tuple

from .schema import ParseResult, SearchPayload


# ---------------------------------------------------------------------------
# Listes de détection (conservatrices – en cas de doute on refuse)
# ---------------------------------------------------------------------------

ADULT_KEYWORDS = {
    "x", "xxx", "porn", "porno", "nude", "nudes", "hentai", "nsfw",
    "adulte", "adult", "sex", "sexe", "erotic", "érotique", "onlyfans",
    "camgirl", "escort", "jav", "milf", "blowjob", "anal", "fetish",
}

# Indicateurs de contenu propriétaire / récent / non libre
COPYRIGHTED_INDICATORS = {
    "netflix", "disney+", "disney plus", "hbo", "hulu", "amazon prime",
    "paramount+", "apple tv", "crunchyroll", "spotify", "apple music",
    "steam", "epic games", "playstation", "xbox", "nintendo",
    "house of the dragon", "game of thrones", "the last of us",
    "stranger things", "the boys", "wednesday", "oppenheimer",
    "barbie", "dune part", "avatar 2", "marvel", "star wars",
    "windows 11", "windows 10", "macos", "office 365", "photoshop",
    "premiere pro", "after effects", "final cut",
}

# Logiciels / OS libres connus (autorisés)
FREE_SOFTWARE = {
    "ubuntu", "debian", "fedora", "arch linux", "linux mint", "manjaro",
    "opensuse", "gentoo", "kali", "tails", "centos", "almalinux",
    "rocky linux", "pop!_os", "elementary os", "zorin", "mx linux",
    "libreoffice", "gimp", "inkscape", "blender", "krita", "audacity",
    "vlc", "firefox", "thunderbird", "obs studio", "godot", "kdenlive",
    "shotcut", "darktable", "rawtherapee", "scribus", "qgis",
    "postgresql", "mysql community", "mariadb", "nginx", "apache httpd",
    "docker", "kubernetes", "python", "node.js", "golang", "rust",
}

# Domaine public / archives officielles (exemples confirmés)
PUBLIC_DOMAIN_HINTS = {
    "night of the living dead", "george romero", "nosferatu", "metropolis",
    "charlie chaplin", "buster keaton", "public domain", "domaine public",
    "internet archive", "archive.org", "project gutenberg", "librivox",
    "creative commons", "cc0", "cc-by", "cc-by-sa",
}

# Mots liés à l’éducation / data ouverts
ACADEMIC_HINTS = {
    "dataset", "données ouvertes", "open data", "scientific", "scientifique",
    "arxiv", "pubmed", "wikipedia dump", "wikidata", "openstreetmap",
    "cours", "mooc", "leçon", "tutoriel libre", "documentation libre",
}


def _normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower().strip())


def _contains_any(text: str, keywords: set) -> bool:
    return any(k in text for k in keywords)


def _detect_adult(query: str) -> bool:
    q = _normalize(query)
    # Mot exact "x" / "xxx" / etc. (évite faux positifs comme "vieux", "linux"…)
    if re.search(r"\b(x|xxx|porn|porno|nsfw|hentai|sexe?|erotic|érotique)\b", q):
        return True
    # Autres mots adultes plus longs : substring ok
    long_adult = {k for k in ADULT_KEYWORDS if len(k) > 3}
    return _contains_any(q, long_adult)


def _detect_category(query: str) -> str:
    q = _normalize(query)
    if any(w in q for w in ("film", "movie", "cinéma", "cinema", "pelicula")):
        return "movies"
    if any(w in q for w in ("série", "serie", "episode", "épisode", "season", "saison", "tv show")):
        return "tv"
    if any(w in q for w in ("iso", "ubuntu", "debian", "linux", "software", "logiciel", "os ", "distribution")):
        return "software"
    if _contains_any(q, FREE_SOFTWARE):
        return "software"
    return "other"


def _is_clearly_legal(query: str) -> Tuple[bool, str]:
    """
    Retourne (is_legal, reason).
    En cas de doute → False (refus).
    """
    q = _normalize(query)

    # 1. Contenu adulte déjà géré ailleurs, mais double sécurité
    if _detect_adult(q):
        return False, "Contenu adulte exclu."

    # 2. Indicateurs forts de contenu propriétaire / récent
    if _contains_any(q, COPYRIGHTED_INDICATORS):
        return False, "Requête refusée : contenu protégé par le droit d'auteur ou non autorisé."

    # 3. Logiciel / OS libre connu
    if _contains_any(q, FREE_SOFTWARE) or "official torrent" in q or "iso officiel" in q:
        return True, "Distribution ou logiciel libre officiellement autorisé."

    # 4. Domaine public / Internet Archive / Creative Commons
    if _contains_any(q, PUBLIC_DOMAIN_HINTS):
        return True, "Contenu potentiellement domaine public ou source officielle (vérification licence requise)."

    # 5. Éducation / open data
    if _contains_any(q, ACADEMIC_HINTS):
        return True, "Contenu éducatif ou données ouvertes (licence permissive présumée)."

    # 6. Tout le reste → doute → refus
    return False, "Légalité incertaine ou contenu non explicitement autorisé → refus par précaution."


def _build_payload(query: str, category: str, is_legal: bool) -> SearchPayload:
    if not is_legal:
        return SearchPayload()

    q = query.strip()
    q_norm = _normalize(q)

    broad = f"{q} torrent"
    archive = None
    academic = None
    linux = None

    if category == "software" or _contains_any(q_norm, FREE_SOFTWARE):
        # Évite de répéter "official" si déjà présent
        suffix = "" if "official" in q_norm else " official"
        linux = f"{q}{suffix} torrent download"
        broad = f"{q}{suffix} torrent"
    elif category == "movies" and _contains_any(q_norm, PUBLIC_DOMAIN_HINTS):
        broad = f"{q} public domain torrent"
        # Exemple d’optimisation Archive.org
        title_guess = re.sub(r"(vieux film|film|movie|de |by )", "", q, flags=re.I).strip()
        archive = f'title:("{title_guess}") AND mediatype:(movies)'
    elif _contains_any(q_norm, ACADEMIC_HINTS):
        academic = f"{q} open data OR public domain"
        broad = f"{q} open data torrent"
    elif _contains_any(q_norm, PUBLIC_DOMAIN_HINTS):
        broad = f"{q} public domain torrent"
        archive = f"{q} mediatype:(movies OR texts OR audio)"

    return SearchPayload(
        broad_query=broad,
        archive_org_query=archive,
        academic_query=academic,
        linux_software_query=linux,
    )


def _extract_keywords(query: str, is_legal: bool) -> List[str]:
    if not is_legal:
        return []
    # Mots simples, sans stop-words basiques
    stop = {"de", "du", "des", "le", "la", "les", "un", "une", "et", "ou", "à", "a", "the", "of", "for"}
    words = re.findall(r"[a-z0-9\.]+", _normalize(query))
    return [w for w in words if w not in stop and len(w) > 1][:12]


def parse_query(raw_query: str) -> ParseResult:
    """
    Point d’entrée unique du moteur.
    Produit exclusivement le JSON décrit dans le prompt.
    """
    original = raw_query.strip()
    if not original:
        return ParseResult(
            original_query="",
            category="other",
            is_adult=False,
            is_legal_request=False,
            search_payload=SearchPayload(),
            keywords=[],
            reason="Requête vide.",
        )

    is_adult = _detect_adult(original)
    category = _detect_category(original)

    if is_adult:
        return ParseResult(
            original_query=original,
            category=category,
            is_adult=True,
            is_legal_request=False,
            search_payload=SearchPayload(),
            keywords=[],
            reason="Contenu adulte exclu.",
        )

    is_legal, reason = _is_clearly_legal(original)

    payload = _build_payload(original, category, is_legal)
    keywords = _extract_keywords(original, is_legal)

    return ParseResult(
        original_query=original,
        category=category,
        is_adult=False,
        is_legal_request=is_legal,
        search_payload=payload,
        keywords=keywords,
        reason=reason,
    )
