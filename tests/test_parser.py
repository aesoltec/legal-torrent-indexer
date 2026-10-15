"""
Tests unitaires couvrant les exemples du prompt + cas limites.
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from src.parser import parse_query


def test_public_domain_movie():
    r = parse_query("vieux film Night of the Living Dead de George Romero")
    assert r.is_adult is False
    assert r.is_legal_request is True
    assert r.category == "movies"
    assert r.search_payload.broad_query is not None
    assert "public domain" in r.search_payload.broad_query.lower() or "romero" in r.search_payload.broad_query.lower()
    assert r.keywords  # non vide


def test_recent_tv_show_refused():
    r = parse_query("Dernier épisode de House of the Dragon")
    assert r.is_adult is False
    assert r.is_legal_request is False
    assert r.search_payload.broad_query is None
    assert r.keywords == []
    assert "refus" in r.reason.lower() or "protégé" in r.reason.lower()


def test_ubuntu_iso_allowed():
    r = parse_query("ISO Ubuntu 24.04")
    assert r.is_adult is False
    assert r.is_legal_request is True
    assert r.category == "software"
    assert r.search_payload.linux_software_query is not None
    assert "ubuntu" in r.search_payload.linux_software_query.lower()


def test_adult_content_refused():
    r = parse_query("films x")
    assert r.is_adult is True
    assert r.is_legal_request is False
    assert r.search_payload.broad_query is None
    assert r.keywords == []
    assert "adulte" in r.reason.lower()


def test_empty_query():
    r = parse_query("   ")
    assert r.is_legal_request is False
    assert r.keywords == []


def test_json_serializable():
    r = parse_query("Ubuntu 24.04")
    data = r.model_dump()
    # Doit être sérialisable en JSON pur
    json.dumps(data, ensure_ascii=False)


if __name__ == "__main__":
    test_public_domain_movie()
    test_recent_tv_show_refused()
    test_ubuntu_iso_allowed()
    test_adult_content_refused()
    test_empty_query()
    test_json_serializable()
    print("All tests passed.")
