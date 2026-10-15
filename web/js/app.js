/**
 * Legal Torrent Indexer – Frontend (Hybrid Mobile / PC)
 * Appelle l'endpoint /parse et affiche le résultat de façon responsive.
 */

(function () {
  "use strict";

  const form = document.getElementById("search-form");
  const queryInput = document.getElementById("query");
  const btnSearch = document.getElementById("btn-search");
  const btnText = btnSearch.querySelector(".btn-text");
  const btnSpinner = btnSearch.querySelector(".btn-spinner");
  const resultSection = document.getElementById("result-section");
  const statusBadge = document.getElementById("status-badge");
  const resultSummary = document.getElementById("result-summary");
  const metaCategory = document.getElementById("meta-category");
  const metaAdult = document.getElementById("meta-adult");
  const metaLegal = document.getElementById("meta-legal");
  const payloadBlock = document.getElementById("payload-block");
  const payloadContent = document.getElementById("payload-content");
  const keywordsBlock = document.getElementById("keywords-block");
  const keywordsList = document.getElementById("keywords-list");
  const reasonText = document.getElementById("reason-text");
  const rawJson = document.getElementById("raw-json");

  // Chips d'exemples
  document.querySelectorAll(".chip").forEach((chip) => {
    chip.addEventListener("click", () => {
      queryInput.value = chip.dataset.q || "";
      queryInput.focus();
      form.requestSubmit();
    });
  });

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const query = queryInput.value.trim();
    if (!query) return;

    setLoading(true);
    resultSection.hidden = true;

    try {
      const res = await fetch("/parse", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.detail || `Erreur ${res.status}`);
      }

      const data = await res.json();
      renderResult(data);
    } catch (err) {
      renderError(err.message || "Erreur réseau");
    } finally {
      setLoading(false);
    }
  });

  function setLoading(on) {
    btnSearch.disabled = on;
    btnText.hidden = on;
    btnSpinner.hidden = !on;
  }

  function renderResult(data) {
    const allowed = data.is_legal_request && !data.is_adult;

    // Badge
    statusBadge.textContent = allowed ? "Autorisé" : "Refusé";
    statusBadge.className = "status-badge " + (allowed ? "allowed" : "refused");

    // Summary
    resultSummary.textContent = allowed
      ? "Cette requête est acceptée. Les champs de recherche ont été générés."
      : "Cette requête a été refusée. Aucun payload de recherche n'est fourni.";

    // Meta
    metaCategory.textContent = data.category || "—";
    metaAdult.textContent = data.is_adult ? "Oui" : "Non";
    metaAdult.className = "meta-value " + (data.is_adult ? "no" : "yes");
    metaLegal.textContent = data.is_legal_request ? "Oui" : "Non";
    metaLegal.className = "meta-value " + (data.is_legal_request ? "yes" : "no");

    // Payload
    const payload = data.search_payload || {};
    const hasPayload =
      payload.broad_query ||
      payload.archive_org_query ||
      payload.academic_query ||
      payload.linux_software_query;

    if (hasPayload) {
      payloadBlock.hidden = false;
      payloadContent.innerHTML = "";
      const fields = [
        ["broad_query", "Broad query"],
        ["archive_org_query", "Archive.org"],
        ["academic_query", "Academic / Open data"],
        ["linux_software_query", "Linux / Software"],
      ];
      fields.forEach(([key, label]) => {
        if (payload[key]) {
          const div = document.createElement("div");
          div.className = "payload-item";
          div.innerHTML = `<strong>${label}</strong>${escapeHtml(payload[key])}`;
          payloadContent.appendChild(div);
        }
      });
    } else {
      payloadBlock.hidden = true;
    }

    // Keywords
    if (data.keywords && data.keywords.length) {
      keywordsBlock.hidden = false;
      keywordsList.innerHTML = "";
      data.keywords.forEach((kw) => {
        const span = document.createElement("span");
        span.className = "keyword";
        span.textContent = kw;
        keywordsList.appendChild(span);
      });
    } else {
      keywordsBlock.hidden = true;
    }

    // Reason
    reasonText.textContent = data.reason || "—";

    // Raw JSON
    rawJson.textContent = JSON.stringify(data, null, 2);

    resultSection.hidden = false;
    resultSection.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  function renderError(msg) {
    statusBadge.textContent = "Erreur";
    statusBadge.className = "status-badge refused";
    resultSummary.textContent = msg;
    metaCategory.textContent = "—";
    metaAdult.textContent = "—";
    metaAdult.className = "meta-value";
    metaLegal.textContent = "—";
    metaLegal.className = "meta-value";
    payloadBlock.hidden = true;
    keywordsBlock.hidden = true;
    reasonText.textContent = "Impossible d'obtenir une réponse du serveur.";
    rawJson.textContent = "";
    resultSection.hidden = false;
  }

  function escapeHtml(str) {
    const d = document.createElement("div");
    d.textContent = str;
    return d.innerHTML;
  }
})();
