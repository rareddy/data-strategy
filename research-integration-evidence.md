# Integration claims: evidence and corrections

Research date: 2026-09-11. Scope: factual review of identity, credentials, catalog connections, and derived-data governance in `data-strategy-feedback.md`. This is research supporting discussion, not an edit to the feedback or proposal. Vendor capabilities below do not establish customer adoption or demand.

## 1. Identity propagation is a good preference, but does not replace governance

**Evidence.** OAuth token exchange is an established standard. RFC 8693 distinguishes impersonation (the receiver sees the represented identity) from delegation (actor and represented subject remain distinguishable). The authorization server decides what it permits and issues; the exchange mechanism does not itself confer authority or guarantee a particular target supports it. [RFC 8693, sections 1.1 and 2](https://www.rfc-editor.org/rfc/rfc8693.html).

Snowflake External OAuth requires an explicitly configured security integration, trusted issuer/key configuration, audience validation, user mapping, and role scopes. Thus the feedback's direction is feasible for Snowflake, but cannot be delivered by forwarding an arbitrary OpenShift login token. [Snowflake custom External OAuth](https://docs.snowflake.com/en/user-guide/oauth-ext-custom).

Google distinguishes workload federation from workforce/user identity. Workload Identity Federation may provide direct access or service account impersonation; the latter authorizes as the service account, not automatically as the human who initiated a job. [Google Workload Identity Federation](https://docs.cloud.google.com/iam/docs/workload-identity-federation).

**Correction/recommendation.** Replace “The requirement is identity propagation, not policy replication” with “Prefer enforcement at the source under an appropriate user or workload identity; specify additional enforcement wherever data is materialized or delegated access is mediated.” Pipelines legitimately need workload identities. For every connector identify the principal enforced at the destination, supported delegation, role mapping, audit correlation, refresh/revocation behavior, and fallback. “Read its policy model and map it locally” is a substantial policy-translation project, not a safe generic fallback. An approved scoped service identity, restricted operation gateway, or explicit unsupported case can be preferable; that is an architectural recommendation rather than a universal product fact.

## 2. Non-HTTP access does not imply per-database MCP

**Evidence.** The feedback correctly observes that an HTTP header injector cannot rewrite a PostgreSQL protocol exchange. The proposed necessity of per-database MCP does not follow:

- Vault generates leased database credentials from configured roles, including PostgreSQL; a native database client can use these directly. [Vault database secrets engine](https://developer.hashicorp.com/vault/docs/secrets/databases).
- Cloud SQL Auth Proxy and language connectors can obtain, submit, and refresh IAM tokens for native PostgreSQL connections. A user or workload can therefore use database credentials through an intermediary without an MCP server. [Cloud SQL IAM authentication](https://docs.cloud.google.com/sql/docs/postgres/iam-authentication).
- Amazon RDS supports IAM tokens in place of passwords for supported database engines. Tokens last 15 minutes for establishing connections; expiry does not end an existing session. [RDS IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html).
- PostgreSQL 18 supports OAuth authentication, with required client build support and server-side validator integration. This is version-dependent, not a claim about every deployed PostgreSQL instance. [PostgreSQL 18 OAuth](https://www.postgresql.org/docs/18/auth-oauth.html).

**Correction/recommendation.** Ask for a protocol-specific access strategy, offering native drivers with temporary credentials, supported proxies/connectors, and MCP tools where useful to agents. MCP is an agent interaction interface, not a prerequisite for credential brokering or an efficient universal interface for Spark/Ray data transfer. A broker can keep credentials out of model context; whether it also keeps them out of the runtime depends on architecture. Secret injection into the application's environment/files does not achieve the latter.

Remote MCP also requires separate trust boundaries. The MCP security guidance prohibits accepting a token issued for another resource and simply passing it downstream; downstream authorization needs proper audience separation and supported flows. This does not forbid legitimate delegation or token exchange. [MCP security best practices](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/docs/2026-07-28/tutorials/security/security_best_practices.mdx).

## 3. Catalog connection metadata is not an execution credential contract

**Evidence.** OpenMetadata can store service connection configuration and use references to secrets in a customer-controlled secret manager. Its documentation describes these credentials serving connector, ingestion, bot, and internal requirements. [OpenMetadata secrets management](https://docs.open-metadata.org/v1.12.x/deployment/secrets-manager). Its MCP connection guide describes metadata search, glossaries, and lineage tools. [OpenMetadata MCP connection guide](https://docs.open-metadata.org/v1.12.x/how-to-guides/mcp/connect).

**Correction/recommendation.** Reusing nonsecret endpoint and asset definitions is reasonable. Do not assume a catalog's metadata-ingestion credential is appropriate to distribute to an agent, or that discovering an asset authorizes reading it. Require a contract separating asset metadata, network location, supported protocol, credential reference, requesting principal, and execution authorization. Validate actual MCP tool capabilities against the required user flow; a catalog MCP endpoint alone is insufficient evidence of arbitrary warehouse query execution. Do not claim that no existing product solves connections/credentials: Vault and cloud connectors already solve important portions. The defensible claim is a possible gap in consistent RHOAI integration across workloads, subject to an inventory.

## 4. Derived RAG data needs its own enforceable access lifecycle

**Evidence.** Azure AI Search documents document-level permission metadata captured during indexing and enforced during retrieval. Source permission changes only affect search results after synchronization through the relevant index/update mechanism; several native integrations remain preview features. Source authorization therefore does not automatically govern a derived search index. [Azure AI Search document-level access](https://learn.microsoft.com/en-us/azure/search/search-document-level-access-overview).

**Correction/recommendation.** A user permitted to read the original source today may lose access tomorrow while an old chunk remains in an index. This remains a problem if the index is stored in the customer's own warehouse. “Write back to the system of record so rules apply uniformly” requires proof for the new representation, grants, retrieval path, and changes over time. Define ownership, lineage, destination authorization, permission synchronization/rechecks, deletion/revocation behavior, retention, and retrieval filtering before admitting shared derived artifacts. Platform-local governance is legitimate where the platform serves such artifacts; avoiding a second manually authored enterprise policy source is a different objective.

## Questions that would strengthen the architectural discussion

1. Can an existing source be queried from a workbench and agent without copying data or duplicating credentials, with the correct destination principal visible in audit logs?
2. What is the supported delegated-user path versus unattended-workload path for each initial connector?
3. How is source access revocation reflected in existing chunks, embeddings, caches, and subsequent retrieval, and within what interval?
4. Which catalog fields can be imported safely, and which runtime access details still require configuration or approval?
5. Can one initial customer scenario prove reuse of an existing catalog, warehouse, and credential system before broader claims about the required product are made?
