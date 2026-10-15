"""
API FastAPI – endpoint /parse + frontend hybride (Mobile / PC)
Retourne STRICTEMENT le JSON du prompt pour /parse.
Sert l'interface web responsive depuis /web.
"""

from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

from .parser import parse_query
from .schema import ParseResult

# Racine du projet (legal-torrent-indexer/)
ROOT = Path(__file__).resolve().parent.parent
WEB_DIR = ROOT / "web"

app = FastAPI(
    title="Legal Torrent Metadata Indexer",
    description="Moteur de parsing strictement légal pour métadonnées .torrent – Hybrid Mobile/PC",
    version="1.1.0",
)


class QueryRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=500)


@app.post("/parse", response_model=ParseResult)
def parse_endpoint(body: QueryRequest) -> ParseResult:
    """
    Analyse la requête utilisateur et renvoie le JSON conforme au prompt.
    """
    try:
        result = parse_query(body.query)
        return result
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/health")
def health():
    return {"status": "ok", "platform": "hybrid"}


# ---- Frontend hybride (Mobile + PC) ----
# Servir les assets statiques
if WEB_DIR.is_dir():
    app.mount("/css", StaticFiles(directory=WEB_DIR / "css"), name="css")
    app.mount("/js", StaticFiles(directory=WEB_DIR / "js"), name="js")

    @app.get("/")
    def serve_index():
        return FileResponse(WEB_DIR / "index.html")

    @app.get("/manifest.json")
    def serve_manifest():
        return FileResponse(WEB_DIR / "manifest.json")
