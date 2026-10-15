"""
Schéma Pydantic strict correspondant au format JSON obligatoire du prompt.
"""

from typing import List, Optional, Literal
from pydantic import BaseModel, Field, model_validator


class SearchPayload(BaseModel):
    broad_query: Optional[str] = None
    archive_org_query: Optional[str] = None
    academic_query: Optional[str] = None
    linux_software_query: Optional[str] = None


class ParseResult(BaseModel):
    original_query: str
    category: Literal["movies", "tv", "software", "other"]
    is_adult: bool
    is_legal_request: bool
    search_payload: SearchPayload
    keywords: List[str] = Field(default_factory=list)
    target_extension: Literal["torrent"] = "torrent"
    client_platform_hint: Literal["hybrid_payload"] = "hybrid_payload"
    reason: str

    @model_validator(mode="after")
    def enforce_refusal_rules(self) -> "ParseResult":
        """Règle d’échec du prompt : si adulte ou illégal → payload null + keywords vides."""
        if self.is_adult or not self.is_legal_request:
            self.search_payload = SearchPayload(
                broad_query=None,
                archive_org_query=None,
                academic_query=None,
                linux_software_query=None,
            )
            self.keywords = []
        return self
