# Catalog product component-license audit

Reviewed: 2026-09-18. Scope: Apache Gravitino and DataHub, including discovery connectors and access interfaces for PostgreSQL, Snowflake, Redshift, BigQuery, Oracle, and S3. Db2 is deferred. Structured and unstructured access have equal importance.

This is a component evidence review, not approval of a complete binary distribution. **Source pass** means the inspected source/license is permissive. **Blocked** means an identified dependency fails the permissive-only requirement. **Unknown** means the complete selected dependency path was not established. Missing functionality is recorded separately from license failure. No deployment, SBOM generation, or live source test was performed.

## Findings

| Product/path | License result | Capability result |
|---|---|---|
| DataHub metadata-ingestion framework | Source pass: subtree explicitly Apache 2.0 | Metadata ingestion; not established as a general live-query or raw-document retrieval service |
| DataHub PostgreSQL connector as declared | **Blocked for permissive-only:** requires psycopg2-binary, LGPL-3-or-later | PostgreSQL metadata discovery available |
| DataHub other five source paths | Mixed component evidence; complete resolved dependency paths **unknown** | Metadata connectors exist; source coverage does not prove live-access coverage |
| Gravitino PostgreSQL catalog and S3 filesets | Project/source baseline Apache 2.0; pgJDBC permissive; full connector/runtime bundle audit **unknown** | Plausible bounded registration/metadata/access-coordination role |
| Gravitino Snowflake, Redshift, BigQuery, Oracle | No complete connector path established to approve | **Coverage gap:** no dedicated catalogs in inspected v1.3.0 module inventory |

## DataHub: inspect the ingestion subtree and drivers

DataHub has an explicit [metadata-ingestion/LICENSE](https://github.com/datahub-project/datahub/blob/master/metadata-ingestion/LICENSE) containing Apache 2.0. This is stronger evidence for connector source licensing than the repository root alone. The [dependency manifest](https://github.com/datahub-project/datahub/blob/master/metadata-ingestion/setup.py) identifies the following source-specific dependencies. References to `master` are moving snapshots inspected on the review date; no immutable DataHub commit was successfully captured.

| Source | Declared driver/SDK path | Component evidence and remaining boundary |
|---|---|---|
| PostgreSQL | `psycopg2-binary` via `postgres_common` | [psycopg2 LICENSE](https://github.com/psycopg/psycopg2/blob/master/LICENSE) is LGPL-3-or-later, with an OpenSSL linking exception. The exception does not make the package permissive. The default PostgreSQL ingestion installation therefore fails a strict permissive-only gate. |
| Snowflake | `snowflake-sqlalchemy`, `snowflake-connector-python` | [Python driver LICENSE](https://github.com/snowflakedb/snowflake-connector-python/blob/main/LICENSE.txt) is Apache 2.0. Exact dialect, transitive packages, wheel contents and runtime remain unqualified. |
| Redshift | `sqlalchemy-redshift`, `redshift-connector` | [AWS Python driver LICENSE](https://github.com/aws/amazon-redshift-python-driver/blob/master/LICENSE) is Apache 2.0. Do not infer a complete permissive path from this driver alone; dialect and resolved transitives need inspection. |
| BigQuery | `google-cloud-bigquery`, `sqlalchemy-bigquery`, additional Google SDKs | Declared in the manifest; complete selected SDK/dialect dependency licenses were not established in this bounded audit. **Unknown**, not a blanket pass. |
| Oracle | `oracledb` | [python-oracledb license](https://github.com/oracle/python-oracledb/blob/main/LICENSE.txt) offers Apache 2.0 / UPL. DataHub's [Oracle implementation](https://github.com/datahub-project/datahub/blob/master/metadata-ingestion/src/datahub/ingestion/source/sql/oracle.py) uses that driver and includes optional Oracle Client thick-mode setup. Thin-mode driver licensing does not approve the separately installed Oracle Client or the whole runtime. |
| S3 | `boto3`, `botocore`, `pyarrow`, `smart-open[s3]`, schema/file packages | [Boto3 LICENSE](https://github.com/boto/boto3/blob/develop/LICENSE) is Apache 2.0. Other resolved dependencies and the image remain unknown. |

These are metadata-ingestion paths. SQL profiling or reading a file internally does not establish a supported client-facing data access service. The [S3 connector documentation](https://docs.datahub.com/docs/generated/ingestion/sources/s3) must be evaluated against the actual desired object/document discovery behavior, rather than treating S3 tabular ingestion as equivalent to arbitrary document retrieval. The current manifest also contains document ingestion extras using `unstructured` and `unstructured-ingest`; this audit does not qualify their transitive dependency tree or prove a source-byte retrieval interface.

**DataHub decision:** retain only as a metadata candidate with a known PostgreSQL dependency blocker. An adapter modification to replace psycopg2 would be new integration work, not an off-the-shelf pass. The presence of this blocker does not imply DataHub is prohibited for all uses; it means the reviewed default path does not meet this project's permissive-only requirement.

## Gravitino: released capability versus development documentation

Use **v1.3.0**, released **2026-06-29**, as the current inspected release, rather than inferring availability from `/docs/next`. The [release page](https://github.com/apache/gravitino/releases/tag/v1.3.0) identifies commit `40fdf6ab96ac87b47e6d3e14e7c4dc0d815e68f0`. Its [tagged module inventory](https://github.com/apache/gravitino/blob/v1.3.0/settings.gradle.kts) includes PostgreSQL, filesets, server/API, engine connectors and cloud bundles, but no dedicated Snowflake, Redshift, BigQuery or Oracle catalog modules.

The project's [LICENSE](https://github.com/apache/gravitino/blob/main/LICENSE) establishes the Apache 2.0 baseline. The [PostgreSQL JDBC driver license](https://github.com/pgjdbc/pgjdbc/blob/master/LICENSE) is permissive BSD-style. The tagged connector implementation/build files and entire resolved cloud bundles were not successfully retrieved in this bounded audit; therefore neither the entire connector path nor a Gravitino binary/image receives a complete permissive-only pass here.

Released [v1.3.0 credential-vending documentation](https://gravitino.apache.org/docs/1.3.0/security/credential-vending/) explicitly includes JDBC user/password credentials and engine consumption alongside fileset/cloud credential types. The release also hides sensitive values from ordinary catalog-load responses and directs consumers to the vending API. Thus, the older observation that Gravitino credential vending is confined to filesets and Iceberg REST is stale for v1.3.0. This is a capability finding, not evidence that arbitrary customer credential stores can be imported.

[Fileset metadata](https://gravitino.apache.org/docs/1.3.0/manage-fileset-metadata-using-gravitino/) explicitly represents non-tabular files/directories, including S3-backed locations. This is relevant to the equally important unstructured requirement. Fileset registration and filesystem access should not be conflated with automatically crawling all objects, parsing documents, or producing rich document metadata; those need separate qualification. PostgreSQL metadata coordination similarly does not make Gravitino itself a general SQL execution engine.

**Gravitino decision:** a bounded PostgreSQL/S3 registration and access-coordination candidate with incomplete binary license qualification. It is not established as a complete six-source product. Missing catalog implementations are a functional gap, independent of the permissiveness of the Apache source baseline. OpenShift namespace isolation and runtime behavior also remain untested.

## Remaining qualification

For any selected path, pin a release and exact driver versions; resolve only required extras; inventory container, OS, native and transitive components; and inspect each license. Keep source-license evidence separate from end-to-end distribution approval. Test raw S3 document retrieval and structured reads separately, and do not infer either from metadata discovery alone.
