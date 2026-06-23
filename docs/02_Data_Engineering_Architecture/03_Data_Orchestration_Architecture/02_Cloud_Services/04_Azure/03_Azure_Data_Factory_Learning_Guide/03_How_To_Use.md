---
title: How to Use Azure Data Factory
section: "02.03.02.04.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [azure, adf, operations]
canonical: true
---
# 3. How to Use Azure Data Factory

## Setup prerequisites

1. Create **Data Factory** resource in target region (align with ADLS/Synapse).
2. Configure **Git repository** (Azure DevOps or GitHub) for CI/CD.
3. Create **Managed Identity** (system-assigned on factory recommended).
4. Provision **Integration Runtime** — Azure default + SHIR if hybrid.
5. Naming: `adf-{domain}-{env}` (e.g., `adf-analytics-prod`).

## Create factory and linked service (Azure CLI)

```bash
az datafactory create \
  --resource-group rg-analytics-prod \
  --factory-name adf-analytics-prod \
  --location westeurope
```

**ADLS Gen2 linked service (managed identity):**

```json
{
  "name": "ls_adls_curated",
  "properties": {
    "type": "AzureBlobFS",
    "typeProperties": {
      "url": "https://stcurated.dfs.core.windows.net"
    },
    "connectVia": { "referenceName": "AutoResolveIntegrationRuntime", "type": "IntegrationRuntimeReference" }
  }
}
```

Assign Storage Blob Data Contributor to factory MI on the storage account.

## Sample copy pipeline (JSON)

```json
{
  "name": "pl_ingest_orders_daily",
  "properties": {
    "parameters": { "partitionDate": { "type": "String" } },
    "activities": [
      {
        "name": "CopyOrders",
        "type": "Copy",
        "policy": { "timeout": "01:00:00", "retry": 2 },
        "typeProperties": {
          "source": { "type": "SqlSource", "sqlReaderQuery": "SELECT * FROM orders WHERE dt = '@{pipeline().parameters.partitionDate}'" },
          "sink": { "type": "ParquetSink", "storeSettings": { "type": "AzureBlobFSWriteSettings" } },
          "enableStaging": false
        },
        "inputs": [{ "referenceName": "ds_sql_orders", "type": "DatasetReference" }],
        "outputs": [{ "referenceName": "ds_adls_orders", "type": "DatasetReference" }]
      }
    ]
  }
}
```

## Schedule trigger

```json
{
  "name": "tr_daily_0200",
  "properties": {
    "type": "ScheduleTrigger",
    "typeProperties": {
      "recurrence": {
        "frequency": "Day",
        "interval": 1,
        "startTime": "2024-01-01T02:00:00Z",
        "timeZone": "UTC"
      }
    },
    "pipelines": [{ "pipelineReference": { "referenceName": "pl_ingest_orders_daily", "type": "PipelineReference" }, "parameters": { "partitionDate": "@formatDateTime(adddays(utcnow(), -1), 'yyyy-MM-dd')" } }]
  }
}
```

## Tumbling window trigger (backfill)

Use for dependency chains with **offset** and **retry** policies — ideal for partition backfill with `windowStartTime` / `windowEndTime` pipeline parameters.

## Self-Hosted IR setup

1. Register IR in ADF UI → download install key.
2. Install on Windows VM(s) in corporate network — **minimum 2 nodes** for HA.
3. Open outbound HTTPS to Azure; no inbound ports required.
4. Monitor CPU/memory on SHIR nodes in ADF monitoring blade.

## ARM / Bicep deploy

```bicep
resource factory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: 'adf-analytics-prod'
  location: location
  identity: { type: 'SystemAssigned' }
}
```

Export ARM from Git branch for release pipelines.

## Observability

- **Monitor → Pipeline runs** — duration, activity breakdown, error messages.
- **Log Analytics** diagnostic settings on factory.
- **Purview** — register outputs for lineage.
- **Alerts** — metric on FailedRuns > 0.

## Operational checklist

- [ ] Git as source of truth; no prod edits in UI only
- [ ] Managed identity on linked services where supported
- [ ] SHIR HA (2+ nodes) for hybrid
- [ ] Key Vault for remaining secrets
- [ ] Parameterize environments via ARM parameters
- [ ] Enable **detailed billing per pipeline** for chargeback (optional)

## Related

- [Architecture](02_Architecture.md)
- [Production Configuration](07_Production_Configuration.md)
