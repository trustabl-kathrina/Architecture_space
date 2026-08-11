# Enterprise Governance Grid — POC

Entropy-style **marketing site + demo tenant**: landing page for trust messaging; **Try 1-Click Demo** opens a separate workspace where all Customer 360 / NATCO details live.

## Run

```bash
# 1) Neo4j Contracts KG (optional but recommended for Semantics)
cd neo4j-contracts-kg && docker compose up -d && ./scripts/load.sh

# 2) Site + KG API (Vite proxies /api/kg → :8787)
cd ../enterprise-governance-grid && npm install && npm run dev
```

| URL | Role |
| --- | --- |
| `/` | Marketing landing |
| `/demo/customer360/marketplace` | Demo tenant · Marketplace |
| `/demo/customer360/contracts` | Global & NATCO contract folders |
| `/demo/customer360/semantics` | **Live Neo4j KG** (Cypher views) + fallback JSON |
| `/demo/customer360/studio` | Architecture & concepts |
| `/demo/customer360/governance` | Ownership · policies · outcomes |
| `/demo/customer360/guided` | Guided tour bar |

### Semantics · Neo4j Cypher workbench

| Piece | Detail |
| --- | --- |
| API | `GET /api/kg/queries`, `POST /api/kg/queries/run`, `POST /api/kg/run` |
| Catalog source | Parses `neo4j-contracts-kg/cypher/show-e2e-*.cypher` + `06-queries-demo.cypher` (19 queries) |
| UI | Saved Cypher sidebar · editor · Graph/Table · Neo4j property inspector |
| Maintain | Edit those `.cypher` files — API reloads catalog on server restart |

## How to pitch

1. Open the marketing page — brand + “Trust turns data into value”.
2. Click **Try 1-Click Demo** → marketplace.
3. Open **Semantics** — prefer Neo4j live; switch Germany / Croatia / Product path chips.
4. Contracts: Global (TM Forum) / each NATCO → Semantics · Business · Technical · Data Products.

## Contents

| Path | Role |
| --- | --- |
| [`docs/15. Neo4j Contracts Knowledge Graph.md`](./docs/15.%20Neo4j%20Contracts%20Knowledge%20Graph.md) | Neo4j KG setup |
| [`neo4j-contracts-kg/`](./neo4j-contracts-kg/) | Docker Neo4j + Cypher seed |
| [`enterprise-governance-grid/`](./enterprise-governance-grid/) | Vite + React + KG API |
| [`examples/`](./examples/) | Pitch JSON (static fallback) |
