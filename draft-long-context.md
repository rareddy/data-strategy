# Notes on the RHAI Data Strategy — Connect vs. Build (long working draft)

> Working draft. Captures full context; will be condensed to 2–3 pages.

## Framing

The proposal's own tagline is the strongest line in the document:

> "Red Hat AI brings computation to your data, wherever it lives."

Most of my feedback is that the five pillars, as currently staged, don't fully deliver on that
sentence. Pillars 1–3 largely describe moving data *into* the platform (ingestion → platform
compute → platform catalog/store), which is closer to "bring your data to our compute." The gap
between the tagline and the staging is where I think the strategy is most improvable — and I think
closing it makes the story *stronger* competitively, not weaker.

## The organizing idea: our mandate is the customer's stack

Red Hat's mandate has never been to supply the system of record. It is to run the customer's stack
well, on their infrastructure, without lock-in. Applied to data, that means:

- We meet the data where it already is.
- We bring compute to it, or push compute into it.
- We do not ask the customer to adopt a new warehouse, a new catalog, or a new permission model as
  the price of admission to OpenShift AI.

Every enterprise that will buy RHOAI already has a warehouse (Snowflake, BigQuery, Redshift,
Databricks, on-prem Postgres/Oracle), already has a catalog (Atlan, Collibra, Alation, Purview,
OpenMetadata), and already has data access policies attached to both. Red Hat itself is one of
these customers: Red Hat IT runs Atlan, Dataverse, and Snowflake. If our own organization would not
switch its catalog and warehouse to an RHOAI-native model, we should be careful about a strategy
that implicitly asks customers to.

So the question I would put at the top of the strategy is not "what data platform should we build?"
but "what is the smallest thing we must own so that everything the customer already owns works
inside OpenShift AI?" My answer: **the connection, credential, and identity fabric.** That is
Pillar 1. It is currently the thinnest-staged pillar and I think it should be the flagship.

---

## Pillar 3 — Data Abstraction and Catalog

This is where I have the most concern, and it's three separate concerns that are easy to conflate.

### 3.1 An Iceberg REST Catalog is not a data catalog

The proposal treats "Iceberg REST Catalog API" and "data catalog" as adjacent choices (Polaris and
Unity Catalog listed side by side under "Data catalog strategy"). They solve different problems:

- **Iceberg REST Catalog** is a *table* registry. It answers: where does this table live, which
  bucket, what is the current snapshot, what is the schema, what file format (Parquet/ORC/Avro),
  what are the partitions. It is essential plumbing for a lakehouse.
- **A data catalog** answers: who owns this data, what does this column *mean*, who may see it,
  where did it come from, what broke downstream, is it certified, is it PII.

Iceberg gives us almost none of the second list. Business glossary, ownership, stewardship
workflows, column-level lineage, classification, policy, and the UI that makes any of it usable are
all still to be built. Having worked on this class of system before, I'd estimate that is a large
multi-quarter backend *and* frontend program — and at the end of it we'd be a late entrant against
Atlan, Collibra, Alation, and Purview, who have been compounding on discovery UX and connector
breadth for years. That's a hard race to enter with a pre-v1.0 dependency.

### 3.2 The proposal assumes the customer has no catalog

Every enterprise target for RHOAI has already made a catalog decision. Introducing Unity Catalog
OSS as the platform catalog therefore creates a *second* catalog next to the one they govern with —
two places to register assets, two places to grant access, two sources of truth for lineage, and an
obvious sync problem between them. The reflex objection ("but the customer's catalog doesn't know
about our features/vector stores") is real, and the answer is to *publish into* their catalog, not
to run a competing one.

### 3.3 If we must ship a catalog, extend OpenMetadata rather than start near zero

The proposal ranks Unity Catalog OSS first (POC primary) and OpenMetadata as fallback. I'd invert
that, for the reasons the proposal itself documents: OpenMetadata has 120+ connectors, semantic
search, native MCP, and the fastest growth in the category, while Unity Catalog OSS is pre-v1.0
with 18/36 capabilities and no ABAC. If the goal is "catalog capability inside OpenShift AI without
a multi-year build," OpenMetadata is the shorter path by a wide margin. The Collate license
question is a real gate — but it's a legal review, not an engineering program, and it should be run
now rather than left as a fallback condition. (Fair counter to me: MLflow integration is genuinely
better with UC, and UC's Apache-2.0 license is cleaner. I'd want that weighed explicitly rather
than assumed.)

### 3.4 Recommendation for Pillar 3

Reframe Pillar 3 from "provide the catalog" to "**be a good citizen of the customer's catalog.**"
Concretely:

- Read data source, dataset, and schema definitions *from* the customer's catalog (OpenMetadata,
  Atlan, Purview) so RHOAI's asset views are populated without re-registration.
- Publish RHOAI-native assets (Feast feature views, vector collections, models, pipelines) *into*
  that catalog so the customer's governance plane stays the single source of truth.
- Keep Feast where the analysis already put it — predictive AI feature serving — and don't let it
  drift toward being a catalog. The proposal is already right about this.
- Treat "which catalog we ship in the box for customers who have none" as a smaller, secondary
  question, answered by extending OpenMetadata.

---

## Pillar 2 — Compute Engine Strategy

I agree with the engine choices. Spark and Ray Data are the right pair, Kueue is the right resource
layer, and the AIGW file_processor → Spark/Ray progression is a good prototype-to-production story.
My concern is not the engines; it is **what they write into and what they assume.**

### 2.1 The unstated assumption is a platform-resident lake

Read together, Pillars 1–3 describe: ingest from source systems → process on platform compute →
land in a platform store → serve from a platform catalog. That is a lakehouse on OpenShift. If we
build it, we inherit the storage mechanics — capacity, durability, tiering, compaction,
small-file problems, backup, DR — for data the customer already stores and already backs up
somewhere else. That's a large operational surface for a product whose differentiator is supposed
to be *not* holding the customer's data.

We can already see the pull. To support object/volume semantics we're producing non-Iceberg,
custom-shaped tables. That is a small signal of a big pattern: once you own the store, you start
inventing formats to cover the cases the open format doesn't, and interoperability erodes.

### 2.2 The purpose of Spark/Ray needs to be pinned down

The strategy doesn't say which of these Spark and Ray are for, and the answer changes the
architecture materially:

1. **Compute over existing sources to hydrate a platform warehouse.** This is the reading I'd push
   back on — it presumes the warehouse.
2. **Batch/feature prep for predictive training.** Legitimate and valuable. But the outputs can be
   written straight back into the customer's Snowflake / BigQuery / Redshift / lake. Nothing about
   this requires a platform-resident warehouse.
3. **Document processing for RAG (Ray Data + Docling).** Legitimate, already validated, and the
   output is a vector store — which may be the customer's (pgvector in their Postgres, their
   Milvus) as easily as ours.
4. **Agents submitting jobs for heavy computation.** Legitimate and interesting, but it needs job
   submission *plus* credentials and data access scoped to the agent's identity — which is a
   Pillar 1/4 problem, not a compute problem.

I'd suggest the strategy state which of these it is targeting per phase. My position: (2), (3), and
(4) are all good; (1) is the one to drop.

### 2.3 Not everything is a table, and that's the tell

A Postgres table is not an Iceberg table. If a user wants live data from an operational Postgres or
MySQL, the Iceberg/table-format tooling doesn't reach it — different protocol, different client,
different consistency model. There are only two ways to make the experience uniform:

- **Copy everything into our lakehouse first** so one set of tools works. This mandates the
  warehouse even for customers who don't want one, and inserts a hop (and a staleness window, and a
  second copy of regulated data) into a journey they didn't ask for.
- **Accept heterogeneity** and provide first-class direct access per protocol — JDBC/native for
  operational databases, object APIs for S3, warehouse-native connectors for Snowflake/BigQuery,
  federation (Trino) where a single SQL surface genuinely helps.

I'd argue for the second. If a customer wants to read directly from S3, we shouldn't require them
to land it in our warehouse first — least of all so that *our* RBAC model can apply to it. That's
the governance tail wagging the architecture dog, and it's addressed properly in Pillar 4.

### 2.4 Recommendation for Pillar 2

Keep Spark, Ray, Kueue, Docling exactly as proposed. Change the target of the writes: **compute in
OpenShift, persist in the customer's system of record.** Platform-local storage becomes a cache and
a scratch tier — an implementation detail with a lifecycle policy — not a product surface.

---

## Pillar 4 — Governance: federate policy, don't re-author it

The lineage analysis here is good, and the emitter/collector split is the right way to frame it. I
want to push on the access-control half.

### 4.1 Customers will not re-declare their policies in RHOAI

Data access policy already exists, attached to the systems that hold the data, maintained by teams
who are audited on it. Red Hat's own Dataverse already carries per-user data permissions. No one is
going to re-enter those in OpenShift AI, and if we ask them to, we've created a second policy plane
that will drift from the first — which is worse than having no policy plane at all, because it
looks authoritative while being wrong.

### 4.2 The requirement is identity propagation, not policy replication

What RHOAI needs to do is carry the *end user's identity* through to the target system and let that
system's policy engine decide. Concretely: OIDC/token exchange and delegation into Snowflake,
BigQuery, Postgres, and the catalog, so that a query issued from a workbench, a pipeline, or an
agent is evaluated against the policies the customer already wrote. Where propagation genuinely
isn't possible, *pull and map* their permission model rather than asking them to re-author it.

This also dissolves the argument in 2.3: if identity flows through, in-place access is governable,
and the "copy it into our warehouse so we can apply RBAC" justification disappears.

### 4.3 Agents are the same problem with a delegation twist

An agent acting for a user should hold *no more* privilege than that user and usually less — a
down-scoped, auditable, time-bounded delegation of that user's rights, not a new principal with a
hand-maintained permission set. The proposal is right that OpenLineage doesn't cover agent access
and that this is an open area; I'd add that the *authorization* side of agent data access is the
more urgent half, and it follows directly from getting identity propagation right for humans.

---

## Pillar 1 — This should be the flagship, and it has a hard problem in it

Pillar 1 is where I'd concentrate investment, because it's the piece nobody else will build for us
and the piece every other pillar depends on.

### 1.1 Connection sharing is the actual product

The genuinely hard, genuinely valuable problem is: a connection is defined once, and then it is
available — correctly scoped, with credentials the user never sees — to a workbench, a pipeline, a
Spark job, a Ray job, a Feast store, a tool, and an MCP server, filtered by that user's permissions
on the underlying resource. The proposal names auto-mounting; I'd elevate it from a Phase-2 bullet
to the headline deliverable, and I'd extend it: credentials should be **brokered outside the agent
and outside the OpenShift perimeter** where the customer's secret manager already lives, rather than
projected as long-lived Secrets. (The proposal already flags that token auth is disabled in 3.4 and
calls it a systemic blocker — I agree, and I'd argue it's the single highest-priority item in the
whole document.)

### 1.2 Don't re-enter connection definitions that already exist

Catalogs already hold data source definitions and connection metadata. Where a customer runs
OpenMetadata or Atlan, RHOAI should **sync data source definitions from the catalog** rather than
have an admin retype them, and reuse the customer's credential broker rather than store a second
copy of the secret. This is the concrete form of "be a good citizen of their catalog" from 3.4.

### 1.3 A real limitation worth designing around: non-HTTP protocols

Credential injection for an agent running in OpenShift works cleanly for HTTP-based endpoints,
including remote MCP over HTTP. It is not designed for native wire protocols — a Postgres
connection is not an HTTP request with a header we can rewrite. Today the workable pattern is a
per-database MCP server plus a broker that injects the right credentials into that server on the
agent's behalf.

That is worth stating in the strategy, because it has design consequences: it means we need a
credential broker as a first-class component, an MCP server catalog, and a per-protocol story —
none of which is a warehouse, and all of which are on the critical path for agentic data access.

### 1.4 Movement engines are the customer's choice

For bulk movement and CDC, customers already run Fivetran, Airbyte, or similar, and storage teams
run Portworx underneath. We should integrate with what they've chosen rather than curate a
Red Hat ingestion engine. Debezium/Strimzi remain the right *upstream* answer where the customer
wants a Red Hat-aligned CDC path, but that should be an option, not the path.

---

## Pillar 5 — Mostly agree, one adjustment

The unified experience and AIGW/OGX control plane are the right capstone, and MCP-based data
discovery is exactly the right bet. One adjustment: the "Data Assets" view in AI Hub should be a
*federated view over the customer's catalog plus RHOAI-native assets*, not a view over an
RHOAI-owned catalog. Same UX, different backing — and it works on day one for a customer who
already has Atlan, which the RHOAI-owned version does not.

On the agent side, I'd make the MCP investment explicit: MCP servers for the major catalogs
(OpenMetadata, Atlan) and the major warehouses, so agents discover and query the customer's real
estate rather than a platform-local copy of it.

---

## What I'd change, in one table

| Proposal as written | Suggested adjustment | Why |
|---|---|---|
| P3: ship Unity Catalog OSS as platform catalog | Integrate with the customer's catalog; publish RHOAI assets into it | Every target customer already has one; avoids a second source of truth |
| P3: UC primary, OpenMetadata fallback | OpenMetadata first (run the license review now) | 120+ connectors, MCP, mature UI vs. pre-v1.0 and no ABAC |
| P3: Iceberg REST catalog as catalog strategy | Keep Iceberg for table format; don't let it stand in for governance/lineage | They solve different problems |
| P2: compute lands in platform store | Compute in OpenShift, persist to the customer's system of record | Avoids owning storage mechanics and a second copy of regulated data |
| P4: RBAC modeled in RHOAI | Identity propagation to the target system; map their model where needed | Customers won't re-author audited policy |
| P1: credential auto-mount in Phase 2 | Make connection + credential brokering the flagship deliverable | It's the dependency for every other pillar and the piece only we can build |
| P1: curate connectors | Curate connectors *and* sync source definitions from the customer's catalog | Removes re-registration |

## Open questions I'd like to work through with the authors

1. Which of the four Spark/Ray use cases in 2.2 is the strategy actually targeting per phase?
2. Is there a customer segment we've identified that genuinely wants RHOAI to be the system of
   record? If so, that changes my read of Pillars 2–3 substantially.
3. What's the intended relationship between the RHOAI catalog and a customer's existing catalog —
   sync, federate, or replace? The document doesn't say, and it's the crux.
4. How far can identity propagation realistically go with today's platform (given token auth is
   disabled in 3.4), and what's the fallback where it can't?
5. Is the non-HTTP credential injection limitation (1.3) understood and accepted, and is a
   credential broker in scope for Pillar 1?
