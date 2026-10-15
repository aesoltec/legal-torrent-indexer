#!/usr/bin/env python3
"""
Point d’entrée CLI + lancement serveur.
"""

import json
import sys
from pathlib import Path

# Permet d’importer le package src même en CLI
sys.path.insert(0, str(Path(__file__).parent))

from src.parser import parse_query


def main():
    if len(sys.argv) < 2:
        print("Usage: python main.py \"votre requête\"", file=sys.stderr)
        print("       python main.py --server", file=sys.stderr)
        sys.exit(1)

    if sys.argv[1] == "--server":
        import uvicorn
        uvicorn.run("src.api:app", host="0.0.0.0", port=8000, reload=True)
        return

    query = " ".join(sys.argv[1:])
    result = parse_query(query)
    # Sortie pure JSON (comme exigé par le prompt)
    print(json.dumps(result.model_dump(), ensure_ascii=False, indent=None))


if __name__ == "__main__":
    main()
