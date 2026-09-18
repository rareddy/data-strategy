# An Integration-First Read of the RHAI Data Strategy

**Re:** Red Hat AI Data Strategy: Technical Proposal, v4.0
**Status:** Notes for discussion

---

## Purpose of these notes

This isn't a critique of the proposal. It's an attempt to hold the strategy up against how the
industry currently solves these problems, and to ask, pillar by pillar, one question:

> **Where can we integrate with something the customer (or the ecosystem) already has, instead of
> building it ourselves?**

The reason to ask it is not cost avoidance. It's fit. Every enterprise likely to buy RHOAI _may_ has already invested in a data stack - a warehouse or lake, a catalog, a secret manager, an ingestion tool, an identity provider - and has policies, audits, and teams attached to those investments. A strategy that composes with those investments lands on day one. A strategy that asks the customer to re-establish them inside OpenShift AI lands after a migration they may not agree to.

The proposal's own framing already says this:

> "Red Hat AI brings computation to your data, wherever it lives."

That sentence is, in my view, the correct strategy and matches where the industry has moved. The
staged plan, though, largely describes the opposite motion: ingest from source systems → process on
platform compute → land in a platform store → serve from a platform catalog. These notes are about
closing the gap between the tagline and the plan.

## The organizing question

Red Hat's mandate has never been to supply the system of record; it's to run the customer's stack
well, on their infrastructure, without lock-in. Most enterprises evaluating RHOAI will already have a data warehouse or lake (Snowflake, BigQuery, Redshift, Databricks, on-prem Postgres, object
storage) and a catalog or governance tool (Atlan, Collibra, Alation, Purview, OpenMetadata), with
access policies attached to both.

Red Hat is one of those customers: Red Hat IT runs Atlan, Dataverse, and Snowflake. Where they just supply a MCP servers for access for Agents. 

So the question I'd put at the top of the strategy **"what is the smallest thing we must own so that everything the customer already owns works inside OpenShift AI?"** Working through the pillars below, my answer is the connection, credential, and identity fabric - Pillar 1, currently the thinnest-staged pillar, and the one piece of this that no existing product delivers for us.

---

## Pillar 3 - Catalog

**What the industry means by "catalog" is not what Iceberg means by it.** These are two different
layers that happen to share a word, and the proposal treats them as adjacent options:

- An **Iceberg REST Catalog** is table lifecycle and state management: where the table lives, which  bucket, current snapshot, schema, file format (Parquet/ORC/Avro), partitioning. It's an query engine-facing API to support likes of Trino, DuckDB,PyIceberg
- A **data catalog** is a governance and discovery plane: who owns this asset, what does this column mean, who may see it, where did it come from, is it PII.

Iceberg's API surfaces almost none of the second list. Glossary, ownership, classification,
column-level lineage, policy, and the discovery UI that makes any of it usable would all still have
to be built on top. Having worked on this class of system, that's a substantial backend *and*
frontend program, and it puts us in the market as a late entrant against vendors who have compounded
on discovery UX and connector breadth for years.

**The norm here is integration, not replacement.** Catalog vendors compete on connector
count and on being the single governance plane; If we introduce
a platform-resident catalog beside the one the customer actually governs with, we create two places
to register assets, two places to grant access, two lineage stories, and a sync problem between
them. The real need behind this pillar - "their catalog doesn't know about our features and vector
stores" - is met by publishing RHOAI-native assets *into* their catalog and reading source and
dataset definitions *from* it, not by standing up a another one.

If we *really* do see that we need a catalog solution on OpenShift AI, the UC OSS primary ranking in
the proposal stands. Worth noting that OpenMetadata deliberately does *not* build on the Iceberg
API, for the layering reason above — that distinction applies equally to any catalog we evaluate.

Treat the customer's catalog as the system of record for governance,
integrate with it in both directions, and keep any Iceberg REST catalog we run scoped to what it's
actually for table state for RHOAI-produced tables.

## Pillar 2 - Compute and storage

The engine choices are right and I'd keep them: Spark, Ray Data, Kueue, Docling, and the AIGW ->
distributed-engine progression are the industry-standard answers for this workload, and running
compute and storage on OpenShift is exactly where they belong. The question I want to test is what
those engines are ultimately filling.

**As written, the plan reads as a custom data warehouse on OpenShift** - ingest the catalog, ingest
the data, push processed output from Spark and Ray into a platform-resident store. That is a
warehouse, whatever we call it, and it's worth being explicit about the three consequences:

1. **What if customer already has a warehouse or lake.** If they run Snowflake, BigQuery, Redshift,
   Databricks, or an on-prem lake, we're standing up a second copy of data they already store, back
   up, and are audited on including regulated data.
2. **It's a genuinely hard system to build.** Storage mechanics, capacity, durability, tiering,
   compaction, small-file handling, backup, DR plus the format edges. The pull is already visible:
   to support volume semantics we're producing non-Iceberg, custom-shaped tables. Once you own the
   store, you start inventing formats for what the open format doesn't cover, and interoperability
   erodes. That's a long, complex, multi-team program.
3. **Customers won't redo their data** They aren't going to re-ingest and re-define assets
   that are already defined, governed, and in production elsewhere. That's where this pillar stalls
   in the field.

**The mandate should be the inverse: support whatever warehouse or lake stack the customer already
runs, and make that infrastructure reachable from OpenShift AI.** The requirement behind this pillar
is making the customer's existing data assets accessible to the agents being developed and deployed
on OpenShift AI. That's a connectivity and access problem, not a storage problem. If a customer
wants to read directly from S3, we shouldn't ask them to land it in our store first least of all
so that *our* RBAC can apply.

That also means accepting heterogeneity rather than normalizing it away. Not everything is a table:
a Postgres table isn't an Iceberg table, and live operational data has a different protocol, client,
and consistency model. The industry answer is first-class per-protocol access JDBC/native for
operational databases, object APIs for S3, warehouse-native connectors for Snowflake and BigQuery,
federation via Trino where a single SQL surface genuinely helps not one lakehouse that every
source must be copied into so a single toolchain works.

**Where the asset genuinely doesn't exist, building it is fair game, but it lands in their system
of record.** If the customer has no such dataset, using Spark or Ray to construct one is exactly
right; the output should be written back into Snowflake, BigQuery, Redshift, Databricks, or wherever
their system of record lives, rather than retained in a platform-owned store, so that their data
access rules apply to it uniformly. Platform-local storage then becomes a working and scratch tier
with a lifecycle policy an implementation detail, not a product surface.

**One question I'd like to ask:** is the use of Spark and Ray Data scoped to training and
fine-tuning, or are agents also expected to submit tasks to them? The two readings might imply different
architectures.

## Pillar 4 - Governance

On access control, the industry position is clear and I'd align with
it: data access policy already exists, attached to the systems that hold the data, maintained by
teams who are audited on it. Red Hat's own Dataverse carries per-user data permissions today. There is a concern that customers may not re-enter these configurations in OpenShift AI. Operating a second policy plane that drifts from the primary policy plane risks creating a false sense of authority while delivering inaccurate outcomes, which poses a greater operational risk than having no secondary policy plane at all.

**The requirement is identity propagation, not policy replication.** OIDC token exchange,
impersonation, and delegation into Snowflake, BigQuery, Postgres, and the catalog, so that a query
issued from a workbench, a pipeline, or an agent arrives at the target system carrying the end
user's identity and the target system enforces its own policies on it. We don't copy or re-author
those policies; we make sure the caller is correctly identified when the policy is evaluated. Only
where a system can't accept a propagated identity would we read its policy model and map it locally,
and that should be a documented exception rather than the default.

This is also what resolves the Pillar 2 question. The main argument for pulling data onto the
platform is that we can only apply access control to data we hold. If identity flows through to the
source, the data stays where it is and is still governed, and the "copy it in so our RBAC can apply"
justification goes away.

Agents are the same problem with a delegation twist: an agent acting for a user should hold no more
privilege than that user and usually less a down-scoped, auditable, time-bounded delegation rather
than a new principal with a hand-maintained permission set. This is an area where the industry
doesn't yet have a settled answer, so it's worth surveying the emerging agent authorization models
(OPA/Cedar-style policy engines, delegated and attenuated tokens).

## Pillar 1 — The integration layer nobody builds for us

**Connection sharing/delegation is the actual product.** Define a connection once and have it available 
correctly scoped, with credentials the user never shares directly to a workbench, a pipeline, a Spark job, a Ray job, a Feast store, a tool, and an MCP server, filtered by that user's permissions on the
underlying resource. The proposal has auto-mounting as a Phase 2 bullet; I'd make it the headline
deliverable, and extend it so credentials can be **brokered outside the agent and per OpenShift
perimeter**, from the customer's existing secret manager (HashiCorp Vault and equivalents), rather
than only projected as long-lived Secrets.

**Don't re-enter what already exists.** Where a customer runs OpenMetadata or Atlan, sync data
source definitions from their catalog instead of having an admin retype them, and reuse their
credential broker instead of storing a second copy of the secret.

**A limitation worth designing around.** Credential injection for an agent in OpenShift works
cleanly for HTTP-based endpoints, including remote MCP over HTTP. It isn't designed for native wire
protocols a Postgres connection isn't an HTTP request with a header we can rewrite. The workable
pattern today is a per-database MCP server plus a broker that injects credentials on the agent's
behalf. That belongs in the strategy, because it implies a credential broker as a first-class
component, an MCP server catalog, and a per-protocol story none of which is a warehouse, and all
of which are on the critical path for agentic data access. It also implies breadth work we should
plan for: different brokering paths for different catalogs and warehouses, and support for more than
one vault. I'd pair this with MCP servers for the major catalogs and warehouses, so agents query the
customer's real data rather than a copy.

**Movement engines are the customer's choice.** Customers may already ingest with Fivetran or
Airbyte, with something like Portworx underneath for storage. Integrate with what they've chosen;
Debezium/Strimzi remain the right upstream answer where a customer wants a Red Hat-aligned CDC path,
but as an option rather than the path.

## Pillar 5 - Unified experience

I'd adjust this in line with the above: the experience to optimize is making data connection and
access easy for agents and for Spark/Ray workloads. I'd leave the data catalog side of the UI to the
source systems, where agents or jobs need catalog information, it's available over the customer
catalog's API, and AI Hub's "Data Assets" view can federate over that plus RHOAI-native assets. Same
UX, different backing, and it works on day one for a customer who already runs Atlan. Keep the
warehouse-centric framing out of this pillar; what belongs here is the ability to *use* the data.

---

## Where this lands, pillar by pillar

| Pillar | Industry pattern | Integration-first read |
|---|---|---|
| P3 Catalog | Governance planes compete to be the single source of truth; Iceberg REST is a separate, engine-facing layer | Integrate with the customer's catalog in both directions; keep Iceberg scoped to table state; if we ship OSS, OpenMetadata is the shorter path |
| P2 Compute/storage | Compute moves to the data; warehouses and lakes are the customer's investment | Keep the engines and keep compute on OpenShift; persist to the customer's system of record; build new datasets only where none exists |
| P4 Governance | Policy lives with the data; federation via identity propagation | OIDC token exchange, impersonation, delegation; map a policy model only where propagation is impossible |
| P1 Connections | No existing product solves this for OpenShift AI | Make connection + credential brokering the flagship; broker from the customer's vault; per-protocol and MCP-based access |
| P5 Experience | Discovery UX belongs to the governance plane | Federated asset view; optimize for agent and job access, not for owning the catalog UI |

## Questions I'd like to work through together

1. Is Spark/Ray Data scoped to training and fine-tuning, or do agents also submit tasks to them?
   The answer changes the architecture and the Pillar 1 dependencies.
2. Have we identified a customer segment that genuinely wants RHOAI to be the system of record? If
   so, that changes my read of Pillars 2-3 substantially.
3. What's the intended relationship between an RHOAI catalog and the customer's existing catalog 
   sync, federate, or replace? I think this is the crux, and the document doesn't say.
4. How far can identity propagation go on today's platform given token auth is disabled in 3.4, and
   what's the fallback where it can't?
5. Is the non-HTTP credential injection limitation understood and accepted, and is a credential
   broker with multi-vault and multi-catalog support in scope for Pillar 1?
