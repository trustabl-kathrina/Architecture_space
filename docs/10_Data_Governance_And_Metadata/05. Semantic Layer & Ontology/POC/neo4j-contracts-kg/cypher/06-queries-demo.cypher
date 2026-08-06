// 06-queries-demo.cypher — Demo queries for Neo4j Browser
// Paste sections one at a time into Browser after load.sh

// ============================================================
// Q1 — Full Customer 360 neighborhood (concept-centric)
// ============================================================
MATCH (c:Concept {conceptId: 'customer'})
OPTIONAL MATCH (c)<-[r]-(src)
RETURN c, r, src
LIMIT 50;

// ============================================================
// Q2 — Meaning bridges: anything that lands on customer-identifier
// ============================================================
MATCH (c:Concept {conceptId: 'customer-identifier'})<-[r:MAPS_TO|REPRESENTS|IMPLEMENTS]-(src)
RETURN labels(src)[0] AS sourceType, src.id AS sourceId, type(r) AS bridge, c.uri AS conceptUri
ORDER BY sourceType;

// ============================================================
// Q3 — Technical lineage path: System → … → Column → Concept
// ============================================================
MATCH path = (sys:System)-[:HAS_DATABASE]->(:Database)-[:HAS_SCHEMA]->(:Schema)
  -[:CONTAINS_TABLE]->(:Table)-[:CONTAINS_COLUMN]->(col:Column)-[:REPRESENTS]->(c:Concept)
WHERE sys.id = 'sys-crm'
RETURN path;

// ============================================================
// Q4 — Product → Concept → Business Term (cross-pack)
// ============================================================
MATCH (p:DataProduct)-[:IMPLEMENTS]->(c:Concept)<-[:MAPS_TO]-(t:BusinessTerm)
RETURN p.name AS product, c.preferredLabel AS concept, t.name AS businessTerm;

// ============================================================
// Q5 — Contract field → column → concept (governed physical path)
// ============================================================
MATCH (f:ContractField)-[:MAPS_TO_COLUMN]->(col:Column)-[:REPRESENTS]->(c:Concept)
RETURN f.name AS contractField, col.name AS column, c.uri AS concept;

// ============================================================
// Q6 — Federation: NATCO Kunde → global Customer
// ============================================================
MATCH (natco:Concept)-[f:FEDERATES]->(global:Concept)
RETURN natco.uri AS natcoUri, f.predicate AS predicate, global.uri AS globalUri;

// ============================================================
// Q7 — Impact: if Concept customer-identifier changes, who is affected?
// ============================================================
MATCH (c:Concept {conceptId: 'customer-identifier'})<-[:MAPS_TO|REPRESENTS|IMPLEMENTS]-(n)
RETURN labels(n) AS assetType, n.id AS assetId, n.name AS name
ORDER BY assetType, assetId;

// ============================================================
// Q8 — Pack inventory counts
// ============================================================
MATCH (n)
WHERE n.pack IS NOT NULL
RETURN n.pack AS pack, count(*) AS nodes
ORDER BY pack;

// ============================================================
// Q9 — End-to-end story path (readable)
// ============================================================
MATCH (term:BusinessTerm {id: 'term-customer'})-[:MAPS_TO]->(c:Concept)
MATCH (entity:DataEntity {id: 'entity-customer'})-[:MAPS_TO]->(c)
MATCH (prod:DataProduct {id: 'dp-customer-360'})-[:IMPLEMENTS]->(c)
MATCH (tbl:Table {id: 'table-crm-customer'})-[:REPRESENTS]->(c)
RETURN term.name AS glossary, entity.name AS logicalEntity, prod.name AS product,
       tbl.fullyQualifiedName AS sourceTable, c.uri AS meaningSoR;
