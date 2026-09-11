# RHAI Data Strategy: Questions on Reusing Customer Investments

**Author:** Ramesh  
**Re:** Red Hat AI Data Strategy: Technical Proposal, v4.0  
**Status:** For discussion with the architecture team

## Starting point

I support the proposal's framing: “Red Hat AI brings computation to your data, wherever it lives.” To deliver that, I suggest this principle:

> **RHOAI should prioritize integrating the customer's data stack.** We should build or package additional data services where demonstrated customer needs cannot be adequately met through integration.

For the proposed catalog, DCH-mediated access, Iceberg catalog service, and ingestion capabilities, establish **what the customer needs, what they already operate, and what gap remains after integration.** Customers with established platforms and those needing missing capabilities—including disconnected deployments—may warrant different answers. These are strategy questions; the ADRs provide early implementation context.

## 1. Catalog: why can't the customer's existing catalog remain authoritative?

Agents need descriptions, schemas, and meaning to discover data. Customers using catalogs like Atlan or OpenMetadata may already maintain this information. Another registry risks repeated registration and unclear metadata ownership. Any additional AI artifact requirements should first be assessed against existing registries and the customer's catalog.

> **Question:** I agree agents need a data dictionary and discovery capabilities. For a customer already using catalogs like Atlan, why can't that remain the authoritative source? What specific missing capability requires a new RHOAI catalog, rather than an integration?

If a new catalog is justified, evaluate existing implementations, including OpenMetadata, before building custom capabilities. Account for OpenShift integration, operational footprint, and maintenance.

## 2. Access: what requires an additional RHOAI service?

Data Connect Hub (DCH) proposes shared access through HTTP/Arrow Flight and REST, reducing repeated driver integration. Customers may already have suitable APIs or native connectors. Similarly, connecting to an existing Iceberg catalog is distinct from hosting another catalog server.

Training may need bulk reads; agents may query sources without ingestion. Our working constraint for the proposed NVIDIA OpenShell environment is HTTP-based credential swapping. Existing HTTP APIs or MCP tools may meet that agent requirement without dictating the access path for Spark or Ray.

> **Question:** Before committing to DCH-mediated access or an RHOAI-hosted Iceberg catalog, can we identify the customer journeys that existing source APIs, native connectors, and customer-managed catalogs cannot adequately support? Where a gap exists, what is the smallest additional capability RHOAI needs to provide?

Specify the recommended path and whether data is copied; non-Iceberg sources should remain usable without conversion. Reuse customer-maintained connection metadata and credential references where appropriate. OpenShift RBAC controls who may use a connection; the source controls its credentials' permissions. Reusing catalog metadata need not mean reusing its scanning credentials.

## 3. Storage: why not use customer-designated destinations for processed data?

Ingestion, training-data preparation, and document processing produce datasets, chunks, or embeddings. Customer-designated object storage and retrieval systems may already provide suitable destinations. Some outputs need durable retention for reproducibility or serving, with explicit responsibility for capacity, access, retention, backup, and deletion.

**Proposed direction:** Reuse customer-designated storage and retrieval systems wherever suitable. Additional RHOAI-managed storage should address a demonstrated requirement those systems cannot meet. Retaining processing outputs does not itself justify a new catalog, and catalog registration alone does not require copying data.

> **Question:** Which outputs require additional RHOAI-managed storage, why are customer-designated destinations insufficient, and who would configure and operate the additional storage?

## Documents informing these questions

- [Red Hat AI Data Strategy: Technical Proposal, v4.0](RHAI-data-strategy-proposal.md)
- [Data Registry ADR](https://raw.githubusercontent.com/opendatahub-io/architecture-decision-records/refs/heads/main/architecture-decision-records/data-registry/ODH-ADR-DR-0001-data-registry.md)
- [Data Connect Hub ADR](https://raw.githubusercontent.com/opendatahub-io/architecture-decision-records/refs/heads/main/architecture-decision-records/data-connect-hub/ODH-ADR-0001-data-connect-hub.md)
