// e2e-customer-360.cypher
// Multi-NATCO Customer 360 — Global (TM Forum SID) + DE/AT/HR/HU/PL
// Complete per-country flow:
//   Namespace -ALIGNS_TO-> Global
//   local Concept -FEDERATES-> SID Concept (+ FederationEdge)
//   BusinessTerm -MAPS_TO-> SID (+ MappingRecord) / -EXPRESSED_AS-> local Concept
//   System→DB→Schema→Table→Column -REPRESENTS-> local + global
//   DataEntity -IMPLEMENTED_IN-> NATCO Table ; DataAttribute -IMPLEMENTED_BY-> NATCO Column
//   DataProduct -CONSUMES-> InputPort -READS_FROM-> NATCO Table
//   DataProduct -EXPOSES-> OutputPort -BACKED_BY-> curated Table (+ contract)

// ========== 1. Global namespace + TM Forum SID concepts ==========
MERGE (ns:Namespace {id: 'ns-global'})
SET ns.slug = 'global',
    ns.displayName = 'Enterprise Global (TM Forum SID)',
    ns.kind = 'global',
    ns.uriBase = 'https://semantics.example/ns/global/',
    ns.naming = 'tmforum-sid',
    ns.status = 'active',
    ns.owner = 'Global Semantic COE',
    ns.pack = 'semantic-control-plane'
WITH ns

MERGE (cCust:Concept {id: 'concept-global-Customer'})
SET cCust.conceptId = 'Customer',
    cCust.uri = 'https://semantics.example/ns/global/Customer',
    cCust.kind = 'entity',
    cCust.preferredLabel = 'Customer',
    cCust.description = 'TM Forum SID Customer — a party that buys or uses products or services',
    cCust.bootstrapSource = 'tmforum-sid',
    cCust.status = 'approved',
    cCust.pack = 'semantic-control-plane'
WITH ns, cCust

MERGE (cId:Concept {id: 'concept-global-CustomerIdentification'})
SET cId.conceptId = 'CustomerIdentification',
    cId.uri = 'https://semantics.example/ns/global/CustomerIdentification',
    cId.kind = 'shared_property',
    cId.preferredLabel = 'Customer Identification',
    cId.description = 'TM Forum SID-aligned unique identifier of a Customer',
    cId.bootstrapSource = 'tmforum-sid',
    cId.status = 'approved',
    cId.pack = 'semantic-control-plane'
WITH ns, cCust, cId

MERGE (ns)-[:CONTAINS_CONCEPT]->(cCust)
MERGE (ns)-[:CONTAINS_CONCEPT]->(cId)
WITH ns, cCust, cId

// ========== 2. Global business catalog (needed before NATCO IMPLEMENTED_* bridges) ==========
MERGE (termG:BusinessTerm {id: 'term-global-Customer'})
SET termG.name = 'Customer', termG.definition = 'TM Forum SID Customer',
    termG.status = 'Approved', termG.pack = 'business-catalog'
MERGE (domain:DataDomain {id: 'domain-customer'})
SET domain.name = 'Customer', domain.status = 'Active', domain.pack = 'business-catalog'
MERGE (model:DataModel {id: 'model-customer-logical'})
SET model.name = 'Customer Logical Model', model.status = 'Approved',
    model.pack = 'business-catalog'
MERGE (entity:DataEntity {id: 'entity-customer'})
SET entity.name = 'Customer', entity.status = 'Approved', entity.pack = 'business-catalog'
MERGE (attr:DataAttribute {id: 'attr-customer-id'})
SET attr.name = 'customerId', attr.dataType = 'string', attr.status = 'Approved',
    attr.pack = 'business-catalog'

MERGE (domain)-[:OWNS_MODEL]->(model)
MERGE (model)-[:CONTAINS_ENTITY]->(entity)
MERGE (entity)-[:HAS_ATTRIBUTE]->(attr)
MERGE (domain)-[:CLASSIFIES]->(entity)
MERGE (termG)-[:RELATES_TO {role: 'defines'}]->(entity)
MERGE (termG)-[:MAPS_TO]->(cCust)
MERGE (entity)-[:MAPS_TO]->(cCust)
MERGE (attr)-[:MAPS_TO]->(cId)

MERGE (mapTermG:MappingRecord {id: 'map-global-term-Customer'})
SET mapTermG.kind = 'business_to_concept', mapTermG.da = 'DA-08', mapTermG.status = 'approved',
    mapTermG.pack = 'semantic-control-plane'
MERGE (mapTermG)-[:SOURCE]->(termG)
MERGE (mapTermG)-[:TARGET]->(cCust)

MERGE (mapEntG:MappingRecord {id: 'map-global-entity-Customer'})
SET mapEntG.kind = 'business_to_concept', mapEntG.da = 'DA-08', mapEntG.status = 'approved',
    mapEntG.pack = 'semantic-control-plane'
MERGE (mapEntG)-[:SOURCE]->(entity)
MERGE (mapEntG)-[:TARGET]->(cCust)

MERGE (mapAttrG:MappingRecord {id: 'map-global-attr-CustomerIdentification'})
SET mapAttrG.kind = 'business_to_concept', mapAttrG.da = 'DA-08', mapAttrG.status = 'approved',
    mapAttrG.pack = 'semantic-control-plane'
MERGE (mapAttrG)-[:SOURCE]->(attr)
MERGE (mapAttrG)-[:TARGET]->(cId)

WITH ns, cCust, cId, domain, entity, attr

// ========== 3. Per-NATCO complete flow ==========
UNWIND [
  {
    nsId: 'ns-natco-de', slug: 'natco-de', display: 'Germany', iso: 'DE',
    entId: 'concept-natco-de-kunde', entCid: 'kunde', entLabel: 'Kunde',
    entUri: 'https://semantics.example/ns/natco-de/kunde',
    idId: 'concept-natco-de-kundennummer', idCid: 'kundennummer', idLabel: 'Kundennummer',
    idUri: 'https://semantics.example/ns/natco-de/kundennummer',
    termName: 'Kunde',
    sysId: 'sys-crm-de', sysName: 'CRM-DE',
    dbId: 'db-crm-de', dbName: 'crm_de',
    schId: 'schema-crm-de', schName: 'public',
    tblId: 'table-crm-de-kunde', tblName: 'kunde', tblFqn: 'crm_de.public.kunde',
    colId: 'col-crm-de-kundennummer', colName: 'kundennummer',
    portId: 'port-in-crm-de', portName: 'crm_de_kunde'
  },
  {
    nsId: 'ns-natco-at', slug: 'natco-at', display: 'Austria', iso: 'AT',
    entId: 'concept-natco-at-kunde', entCid: 'kunde', entLabel: 'Kunde',
    entUri: 'https://semantics.example/ns/natco-at/kunde',
    idId: 'concept-natco-at-kunden-id', idCid: 'kunden_id', idLabel: 'Kunden-ID',
    idUri: 'https://semantics.example/ns/natco-at/kunden_id',
    termName: 'Kunde',
    sysId: 'sys-crm-at', sysName: 'CRM-AT',
    dbId: 'db-crm-at', dbName: 'crm_at',
    schId: 'schema-crm-at', schName: 'dbo',
    tblId: 'table-crm-at-kunde', tblName: 'Kunde', tblFqn: 'crm_at.dbo.Kunde',
    colId: 'col-crm-at-kunden-id', colName: 'kunden_id',
    portId: 'port-in-crm-at', portName: 'crm_at_kunde'
  },
  {
    nsId: 'ns-natco-hr', slug: 'natco-hr', display: 'Croatia', iso: 'HR',
    entId: 'concept-natco-hr-kupac', entCid: 'kupac', entLabel: 'Kupac',
    entUri: 'https://semantics.example/ns/natco-hr/kupac',
    idId: 'concept-natco-hr-kupac-id', idCid: 'kupac_id', idLabel: 'ID kupca',
    idUri: 'https://semantics.example/ns/natco-hr/kupac_id',
    termName: 'Kupac',
    sysId: 'sys-crm-hr', sysName: 'CRM-HR',
    dbId: 'db-crm-hr', dbName: 'crm_hr',
    schId: 'schema-crm-hr', schName: 'public',
    tblId: 'table-crm-hr-kupac', tblName: 'kupac', tblFqn: 'crm_hr.public.kupac',
    colId: 'col-crm-hr-kupac-id', colName: 'kupac_id',
    portId: 'port-in-crm-hr', portName: 'crm_hr_kupac'
  },
  {
    nsId: 'ns-natco-hu', slug: 'natco-hu', display: 'Hungary', iso: 'HU',
    entId: 'concept-natco-hu-ugyfel', entCid: 'ugyfel', entLabel: 'Ügyfél',
    entUri: 'https://semantics.example/ns/natco-hu/ugyfel',
    idId: 'concept-natco-hu-ugyfel-azonosito', idCid: 'ugyfel_azonosito', idLabel: 'Ügyfél azonosító',
    idUri: 'https://semantics.example/ns/natco-hu/ugyfel_azonosito',
    termName: 'Ügyfél',
    sysId: 'sys-crm-hu', sysName: 'CRM-HU',
    dbId: 'db-crm-hu', dbName: 'crm_hu',
    schId: 'schema-crm-hu', schName: 'dbo',
    tblId: 'table-crm-hu-ugyfel', tblName: 'Ugyfel', tblFqn: 'crm_hu.dbo.Ugyfel',
    colId: 'col-crm-hu-ugyfel-azonosito', colName: 'ugyfel_azonosito',
    portId: 'port-in-crm-hu', portName: 'crm_hu_ugyfel'
  },
  {
    nsId: 'ns-natco-pl', slug: 'natco-pl', display: 'Poland', iso: 'PL',
    entId: 'concept-natco-pl-klient', entCid: 'klient', entLabel: 'Klient',
    entUri: 'https://semantics.example/ns/natco-pl/klient',
    idId: 'concept-natco-pl-id-klienta', idCid: 'id_klienta', idLabel: 'ID klienta',
    idUri: 'https://semantics.example/ns/natco-pl/id_klienta',
    termName: 'Klient',
    sysId: 'sys-crm-pl', sysName: 'CRM-PL',
    dbId: 'db-crm-pl', dbName: 'crm_pl',
    schId: 'schema-crm-pl', schName: 'public',
    tblId: 'table-crm-pl-klient', tblName: 'klient', tblFqn: 'crm_pl.public.klient',
    colId: 'col-crm-pl-id-klienta', colName: 'id_klienta',
    portId: 'port-in-crm-pl', portName: 'crm_pl_klient'
  }
] AS n

MERGE (nNs:Namespace {id: n.nsId})
SET nNs.slug = n.slug, nNs.displayName = n.display, nNs.kind = 'natco',
    nNs.iso3166 = n.iso,
    nNs.uriBase = 'https://semantics.example/ns/' + n.slug + '/',
    nNs.naming = 'local-' + toLower(n.iso),
    nNs.status = 'active',
    nNs.owner = n.slug + '-data-office',
    nNs.pack = 'semantic-control-plane'
MERGE (nNs)-[:ALIGNS_TO {via: 'federation', da: 'DA-11'}]->(ns)

MERGE (nEnt:Concept {id: n.entId})
SET nEnt.conceptId = n.entCid, nEnt.uri = n.entUri, nEnt.kind = 'entity',
    nEnt.preferredLabel = n.entLabel, nEnt.status = 'approved',
    nEnt.scope = 'natco', nEnt.pack = 'semantic-control-plane'
MERGE (nIdc:Concept {id: n.idId})
SET nIdc.conceptId = n.idCid, nIdc.uri = n.idUri, nIdc.kind = 'shared_property',
    nIdc.preferredLabel = n.idLabel, nIdc.status = 'approved',
    nIdc.scope = 'natco', nIdc.pack = 'semantic-control-plane'
MERGE (nNs)-[:CONTAINS_CONCEPT]->(nEnt)
MERGE (nNs)-[:CONTAINS_CONCEPT]->(nIdc)

// Federation (direct + edge audit nodes)
MERGE (nEnt)-[:FEDERATES {predicate: 'sameAs', da: 'DA-11'}]->(cCust)
MERGE (nIdc)-[:FEDERATES {predicate: 'sameAs', da: 'DA-11'}]->(cId)
MERGE (fedE:FederationEdge {id: 'fed-' + n.slug + '-entity'})
SET fedE.predicate = 'sameAs', fedE.status = 'approved', fedE.isPrimary = true,
    fedE.da = 'DA-11', fedE.pack = 'semantic-control-plane'
MERGE (nEnt)-[:FROM_CONCEPT]->(fedE)
MERGE (fedE)-[:TO_CONCEPT]->(cCust)
MERGE (fedI:FederationEdge {id: 'fed-' + n.slug + '-id'})
SET fedI.predicate = 'sameAs', fedI.status = 'approved', fedI.isPrimary = true,
    fedI.da = 'DA-11', fedI.pack = 'semantic-control-plane'
MERGE (nIdc)-[:FROM_CONCEPT]->(fedI)
MERGE (fedI)-[:TO_CONCEPT]->(cId)

// Local glossary
MERGE (term:BusinessTerm {id: 'term-' + n.slug + '-customer'})
SET term.name = n.termName, term.natco = n.slug, term.status = 'Approved',
    term.pack = 'business-catalog'
MERGE (term)-[:MAPS_TO]->(cCust)
MERGE (term)-[:EXPRESSED_AS]->(nEnt)
MERGE (mapTerm:MappingRecord {id: 'map-' + n.slug + '-term-Customer'})
SET mapTerm.kind = 'business_to_concept', mapTerm.da = 'DA-08', mapTerm.status = 'approved',
    mapTerm.natco = n.slug, mapTerm.pack = 'semantic-control-plane'
MERGE (mapTerm)-[:SOURCE]->(term)
MERGE (mapTerm)-[:TARGET]->(cCust)

// Local technical hierarchy
MERGE (sys:System {id: n.sysId})
SET sys.name = n.sysName, sys.natco = n.slug, sys.status = 'Active',
    sys.pack = 'technical-catalog'
MERGE (db:Database {id: n.dbId})
SET db.name = n.dbName, db.natco = n.slug, db.status = 'Active',
    db.pack = 'technical-catalog'
MERGE (sch:Schema {id: n.schId})
SET sch.name = n.schName, sch.natco = n.slug, sch.status = 'Active',
    sch.pack = 'technical-catalog'
MERGE (tbl:Table {id: n.tblId})
SET tbl.name = n.tblName, tbl.fullyQualifiedName = n.tblFqn, tbl.natco = n.slug,
    tbl.status = 'Active', tbl.pack = 'technical-catalog'
MERGE (col:Column {id: n.colId})
SET col.name = n.colName, col.natco = n.slug, col.dataType = 'varchar',
    col.isPrimaryKey = true, col.status = 'Active', col.pack = 'technical-catalog'

MERGE (sys)-[:HAS_DATABASE]->(db)
MERGE (db)-[:HAS_SCHEMA]->(sch)
MERGE (sch)-[:CONTAINS_TABLE]->(tbl)
MERGE (tbl)-[:CONTAINS_COLUMN]->(col)

// Technical meaning bridges (local + global)
MERGE (tbl)-[:REPRESENTS]->(nEnt)
MERGE (col)-[:REPRESENTS]->(nIdc)
MERGE (tbl)-[:REPRESENTS]->(cCust)
MERGE (col)-[:REPRESENTS]->(cId)
MERGE (mapTbl:MappingRecord {id: 'map-' + n.slug + '-table-Customer'})
SET mapTbl.kind = 'technical_to_concept', mapTbl.da = 'DA-09', mapTbl.status = 'approved',
    mapTbl.natco = n.slug, mapTbl.pack = 'semantic-control-plane'
MERGE (mapTbl)-[:SOURCE]->(tbl)
MERGE (mapTbl)-[:TARGET]->(cCust)
MERGE (mapCol:MappingRecord {id: 'map-' + n.slug + '-column-CustomerIdentification'})
SET mapCol.kind = 'technical_to_concept', mapCol.da = 'DA-09', mapCol.status = 'approved',
    mapCol.natco = n.slug, mapCol.pack = 'semantic-control-plane'
MERGE (mapCol)-[:SOURCE]->(col)
MERGE (mapCol)-[:TARGET]->(cId)

// Structural business ↔ technical (was missing for all NATCOs)
MERGE (entity)-[:IMPLEMENTED_IN]->(tbl)
MERGE (tbl)-[:IMPLEMENTS_ENTITY]->(entity)
MERGE (attr)-[:IMPLEMENTED_BY]->(col)
MERGE (col)-[:IMPLEMENTS_ATTRIBUTE]->(attr)

// Stash port wiring data for step 5
WITH ns, cCust, cId, domain, entity, attr,
     collect({portId: n.portId, portName: n.portName, tblId: n.tblId}) AS ports

// ========== 4. Curated product technical (global) ==========
MERGE (dbDp:Database {id: 'db-dp'})
SET dbDp.name = 'dp', dbDp.technology = 'PostgreSQL', dbDp.status = 'Active',
    dbDp.pack = 'technical-catalog'
MERGE (schDp:Schema {id: 'schema-dp-curated'})
SET schDp.name = 'curated', schDp.status = 'Active', schDp.pack = 'technical-catalog'
MERGE (tblDp:Table {id: 'table-dp-customer-360'})
SET tblDp.name = 'customer_360', tblDp.fullyQualifiedName = 'dp.curated.customer_360',
    tblDp.status = 'Active', tblDp.pack = 'technical-catalog'
MERGE (colDp:Column {id: 'col-dp-customer-id'})
SET colDp.name = 'customer_id', colDp.dataType = 'varchar', colDp.isPrimaryKey = true,
    colDp.status = 'Active', colDp.pack = 'technical-catalog'

MERGE (dbDp)-[:HAS_SCHEMA]->(schDp)
MERGE (schDp)-[:CONTAINS_TABLE]->(tblDp)
MERGE (tblDp)-[:CONTAINS_COLUMN]->(colDp)
MERGE (colDp)-[:REPRESENTS]->(cId)
MERGE (tblDp)-[:REPRESENTS]->(cCust)
MERGE (entity)-[:IMPLEMENTED_IN]->(tblDp)
MERGE (tblDp)-[:IMPLEMENTS_ENTITY]->(entity)
MERGE (attr)-[:IMPLEMENTED_BY]->(colDp)
MERGE (colDp)-[:IMPLEMENTS_ATTRIBUTE]->(attr)

MERGE (mapTblDp:MappingRecord {id: 'map-dp-table-Customer'})
SET mapTblDp.kind = 'technical_to_concept', mapTblDp.da = 'DA-09', mapTblDp.status = 'approved',
    mapTblDp.pack = 'semantic-control-plane'
MERGE (mapTblDp)-[:SOURCE]->(tblDp)
MERGE (mapTblDp)-[:TARGET]->(cCust)
MERGE (mapColDp:MappingRecord {id: 'map-dp-column-CustomerIdentification'})
SET mapColDp.kind = 'technical_to_concept', mapColDp.da = 'DA-09', mapColDp.status = 'approved',
    mapColDp.pack = 'semantic-control-plane'
MERGE (mapColDp)-[:SOURCE]->(colDp)
MERGE (mapColDp)-[:TARGET]->(cId)

WITH ns, cCust, cId, domain, entity, attr, tblDp, colDp, ports

// ========== 5. Data Product + ports for every NATCO ==========
MERGE (prod:DataProduct {id: 'dp-customer-360'})
SET prod.name = 'Customer 360',
    prod.description = 'Enterprise customer master federating DE/AT/HR/HU/PL sources',
    prod.status = 'Published', prod.pack = 'data-products'
MERGE (out:OutputPort {id: 'port-out-customer-360'})
SET out.name = 'customer_360_table', out.portType = 'table', out.status = 'Active',
    out.pack = 'data-products'
MERGE (contract:DataContract {id: 'contract-customer-360-v1'})
SET contract.name = 'Customer 360 Contract', contract.version = '1.0.0',
    contract.status = 'Active', contract.pack = 'data-products'
MERGE (field:ContractField {id: 'field-customer-id'})
SET field.name = 'customer_id', field.dataType = 'string', field.required = true,
    field.status = 'Active', field.pack = 'data-products'

MERGE (prod)-[:EXPOSES]->(out)
MERGE (out)-[:GOVERNED_BY]->(contract)
MERGE (contract)-[:CONTAINS_FIELD]->(field)
MERGE (prod)-[:IMPLEMENTS]->(cCust)
MERGE (field)-[:IMPLEMENTS]->(cId)
MERGE (out)-[:BACKED_BY]->(tblDp)
MERGE (field)-[:MAPS_TO_COLUMN]->(colDp)
MERGE (prod)-[:BELONGS_TO_DOMAIN]->(domain)

MERGE (mapProd:MappingRecord {id: 'map-dp-Customer'})
SET mapProd.kind = 'product_to_concept', mapProd.da = 'DA-10', mapProd.status = 'approved',
    mapProd.pack = 'semantic-control-plane'
MERGE (mapProd)-[:SOURCE]->(prod)
MERGE (mapProd)-[:TARGET]->(cCust)
MERGE (mapField:MappingRecord {id: 'map-field-CustomerIdentification'})
SET mapField.kind = 'product_to_concept', mapField.da = 'DA-10', mapField.status = 'approved',
    mapField.pack = 'semantic-control-plane'
MERGE (mapField)-[:SOURCE]->(field)
MERGE (mapField)-[:TARGET]->(cId)

WITH prod, cCust, ports
UNWIND ports AS p
MERGE (inp:InputPort {id: p.portId})
SET inp.name = p.portName, inp.portType = 'table', inp.status = 'Active',
    inp.pack = 'data-products'
MERGE (prod)-[:CONSUMES]->(inp)
WITH prod, cCust, inp, p
MATCH (tbl:Table {id: p.tblId})
MERGE (inp)-[:READS_FROM]->(tbl)

WITH DISTINCT prod, cCust
RETURN 'Multi-NATCO Customer 360 loaded (complete country flows)' AS status,
       cCust.uri AS globalConcept,
       prod.name AS product;
