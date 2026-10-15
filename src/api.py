"""
API FastAPI – endpoint unique /parse
Retourne STRICTEMENT le JSON du prompt (aucun enrobage).
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from .parser import parse_query
from .schema import ParseResult

app = FastAPI(
    title="Legal Torrent Metadata Indexer",
    description="Moteur de parsing strictement légal pour métadonnées .torrent",
    version="1.0.0",
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
    return {"status": "ok"}
