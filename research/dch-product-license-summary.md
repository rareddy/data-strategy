# DCH product license qualification

Date: 2026-09-18. Scope: all six products suggested for the DCH capability, plus supporting access libraries discussed during feasibility. Required source families: PostgreSQL, Snowflake, Redshift, BigQuery, Oracle and S3. Db2 remains deferred. Structured and unstructured access have equal weight.

**Scope update:** The user accepts the Oracle vendor driver and its required companion libraries as an exception to the permissive-license criterion. They no longer block product selection. The exception does not qualify a product’s own connector code, other dependencies, or commercial-only features.

## Reading the results

This is a primary-source component and dependency-declaration audit. It is not certification of a built container or a complete transitive dependency inventory. No deployable product is marked fully qualified.

- **Permissive source evidence:** the inspected implementation and identified direct driver/SDK licenses support further qualification.
- **Known mismatch:** a required selected path includes a nonpermissive license, or a feature is only established in a commercial edition.
- **Unknown:** the actual artifact/license or dependency path was not established. Unknown is not a claim of proprietary licensing, but it does not pass selection.
- **Capability gap:** licensing may be suitable while a required connector or access operation is absent/unproven. A license pass does not close this gap.

The audit applies to software we deploy or distribute, not the licenses of customer-operated databases or cloud services. Integrating with a customer's existing product does not imply adopting or redistributing that product's connector implementation. Fivetran remains an existing-customer ingestion integration example, not a proposed permissive platform dependency.

## Product results

| Product | License result for the proposed use | Selection consequence |
| --- | --- | --- |
| Trino | Apache-licensed connector/access code is not a blanket approval of runtime drivers. Oracle's required JDBC artifacts are covered by the accepted driver exception; other connector dependency graphs remain to be qualified. | Conditional candidate; Oracle driver is no longer a selection blocker. Full runtime and functional qualification remain. |
| Gravitino | Apache project baseline and permissive PostgreSQL-driver evidence. Individual connector/build and distribution dependency checks remain incomplete; coverage gaps are distinct from licensing. Published 1.3.0 now documents JDBC credential vending. | Continue supported PostgreSQL/fileset reuse evaluation; do not infer support for all required warehouses. |
| DataHub | Apache-licensed ingestion subtree, but the PostgreSQL extra includes LGPL-licensed psycopg2-binary. Oracle's python-oracledb thin path has different licensing from the proprietary client added in thick mode. | Qualify selected extras/modes; the standard PostgreSQL ingestion path does not meet permissive-only. Metadata access is not live data access. |
| OpenMetadata | Inspected ingestion framework/connectors use Collate Community License, separate from the Apache-licensed core. | Required connector reuse fails the permissive-only gate. Existing-customer integration is a different decision. |
| Airbyte | Current required connector paths are under ELv2; a permissive protocol or historical connector release does not qualify current implementations. | Current connector reuse fails the gate; no historical fork is proposed. |
| Dremio | Some S3/Flight/REST source implementations are Apache-licensed, but the full required paths are unqualified; BigQuery is commercial-edition-only and ordinary builds include non-OSS dependencies. | Hold from the qualified permissive shortlist. |

The linked audits below contain primary citations, versions and per-source findings. These results neither certify a complete runtime nor claim that every file in a conditional product is nonpermissive.

## Detailed evidence

| Scope | Audit |
| --- | --- |
| Trino connectors, drivers and clients | [Trino](trino-permissive-license-audit.md) |
| Gravitino and DataHub | [Catalog products](catalog-products-permissive-license-audit.md) |
| OpenMetadata and Airbyte | [Ingestion products](ingestion-products-permissive-license-audit.md) |
| Dremio connectors, Flight and REST | [Dremio](dremio-permissive-license-audit.md) |
| Arrow/ADBC, JDBC, SQLAlchemy, Psycopg, Boto3 | [Supporting libraries](access-libraries-license-audit.md) |

## Selection consequences

A project's Apache license, a permissive JDBC driver, and an Apache transport are three different pieces of evidence. None certifies the other two. Similarly, an OSS-only build may still contain copyleft code, and a free Community edition may contain non-OSS components.

Qualification must identify the specific source adapter, required driver/SDK, authentication dependencies, server/client access implementation, and chosen distribution. Optional features should be assessed only when included in the selected path; a disallowed optional dependency does not relicense every other source file.

For a shortlisted product, the remaining packaging check is to pin the release/image, enumerate the resolved runtime artifacts and license notices, and demonstrate that any exclusion preserves the required supported functionality. This work should target a concrete candidate, not become a reason to build a replacement platform.

Unstructured acceptance remains independent: prove object/document discovery and retrieval of original content. S3 table access, metadata-only discovery, or a PDF parser alone does not establish that complete access path.
