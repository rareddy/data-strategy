# Airbyte and OpenMetadata: permissive-license gate

Checked 2026-09-18. Bounded source-license assessment for S3, PostgreSQL, Snowflake, Redshift, BigQuery, and Oracle. Db2 is deferred. This is not a complete dependency/SBOM or redistribution qualification.

## Decision

**Neither current Airbyte connectors nor the current OpenMetadata ingestion framework qualify for the project's permissive-only baseline.** This is a directly identified license mismatch, not merely an unresolved dependency check. MIT/Apache-licensed protocol, core, or schema components do not qualify the connector execution path.

| Candidate/component | Evidence | Gate result |
|---|---|---|
| Airbyte connector collection | Official license policy places connectors under Elastic License 2.0 (ELv2), with individual connector metadata providing details. | Does not meet permissive-only baseline. |
| Airbyte protocol | Official policy identifies the protocol as MIT. | Permissive protocol; does not supply connector implementation or an access gateway. |
| Airbyte commercial products | Official policy distinguishes Cloud, Enterprise, and Agents as commercially licensed. | Do not infer permissive licensing from public API availability. |
| OpenMetadata repository core | Root license is Apache 2.0. | Applies subject to subtree/file exceptions; not a whole-distribution approval. |
| OpenMetadata ingestion framework | `ingestion/LICENSE` specifies Collate Community License v1.0 (CCL), with a competing-service excluded-purpose restriction. | Does not meet permissive-only baseline. |
| OpenMetadata Python SDK / REST access | Python ingestion package and server REST API must be treated as separate artifacts. No independent permissive SDK clearance was completed here. | Root Apache license or a REST endpoint does not remove ingestion connector restrictions. |

Sources: [Airbyte official licensing policy](https://raw.githubusercontent.com/airbytehq/airbyte/master/docs/community/licenses/README.md), [OpenMetadata ingestion license](https://raw.githubusercontent.com/open-metadata/OpenMetadata/main/ingestion/LICENSE), [OpenMetadata root license](https://github.com/open-metadata/OpenMetadata/blob/main/LICENSE).

## Source coverage versus license clearance

| Required source | Airbyte | OpenMetadata |
|---|---|---|
| S3 | Connector collection policy: ELv2. | Storage and datalake discovery live in ingestion subtree: CCL. |
| PostgreSQL | Connector collection policy: ELv2. | Ingestion subtree CCL; PostgreSQL connection header was inspected in prior feasibility work. |
| Snowflake | Connector collection policy: ELv2. | Ingestion subtree CCL; individual connector/dependency exceptions not exhaustively checked. |
| Redshift | Connector collection policy: ELv2. | Ingestion subtree CCL; individual connector/dependency exceptions not exhaustively checked. |
| BigQuery | Connector collection policy: ELv2. | Ingestion subtree CCL; individual connector/dependency exceptions not exhaustively checked. |
| Oracle | Connector collection policy: ELv2. | Ingestion subtree CCL; driver mode and transitive licensing remain unqualified. |

These rows apply the documented collection/subtree license; they are **not claims that every file, image, SDK, or driver was separately audited**. No permissively licensed exception for these current connectors was established. Earlier connector and capability inspection is recorded in [connection reuse research](connection-reuse-connectors.md) and [OpenMetadata feasibility](connection-reuse-openmetadata-feasibility.md).

## Access contract and unstructured data

Airbyte's protocol exposes specification, connection checking, discovery, and record extraction for replication. That is not evidence of interactive native query or Arrow Flight service. A permissive protocol definition cannot license the connector that executes it. [Airbyte protocol](https://github.com/airbytehq/airbyte/blob/master/docs/platform/understanding-airbyte/airbyte-protocol.md).

OpenMetadata's catalog API and ingestion workflow are metadata interfaces. The inspected underlying connectors create database/AWS clients, but that does not establish a supported general live-data access gateway. See the [source-level feasibility findings](connection-reuse-openmetadata-feasibility.md).

S3 connector availability establishes neither arbitrary document retrieval nor equivalent structured and unstructured access. The two requirements remain equally important. Neither product is qualified here as the complete access solution.

## Pinning and evidence limits

GitHub's commit API returned these identifiers during this check:

- Airbyte: `6d9c1efcc35f4152200d1a46c68acb00f9382ec4`.
- OpenMetadata: `f5141da5317c813d8eb4c14a9e0ddb401a015692`.
- Airbyte protocol: `79375c2c6cbd8436c9d283be1ba964fc4e85e62d`.

The follow-up batch fetching individual files at those pins was interrupted, so **the license conclusions above rely on the retrieved moving-branch official license texts and prior connector inspections, not a completed pinned-artifact audit**. The identifiers are reproducibility starting points, not a certification. No historical release, complete container, third-party driver closure, OpenShift deployment, or alternative commercial license was qualified. Since directly required connector/framework code already fails the permissive baseline, those incomplete checks do not justify presenting either current stack as a permissive recommendation.
