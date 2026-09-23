# OpenMetadata connector reuse feasibility

Checked 2026-09-17. Source inspection only: no package installation, database connection, S3 request, or OpenShift runtime test was performed. Links target moving `main`; a selected release must be pinned and rechecked. Web snapshots of different files may represent different revisions, so the callable names below describe observed code, not a certified release API.

## Finding

**Connection construction is separable; complete metadata discovery is coupled to OpenMetadata. Current ingestion code also fails the preferred MIT/Apache 2.0 license baseline.** Reusing it would not be simply installing a neutral connector SDK and calling `discover`.

### License correction

The root repository license was insufficient evidence in the previous report. `ingestion/LICENSE` specifies Collate Community License v1.0, and inspected connector files carry matching headers. This is a different license from MIT/Apache 2.0. No historical permissively licensed version has been qualified as an alternative in this investigation. [Ingestion license](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/LICENSE), [PostgreSQL source](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/source/database/postgres/connection.py).

## Concrete connection interfaces

| Source | Observed construction API | Returned object | Implication |
|---|---|---|---|
| PostgreSQL | `metadata.ingestion.source.database.postgres.connection.PostgresConnection(config).client` | SQLAlchemy `Engine` | Native SQL access is technically available from this handle; the constructor body does not request an OpenMetadata server. Azure authentication has an additional token path. |
| Db2 | `metadata.ingestion.source.database.db2.connection.Db2Connection(config).client` | SQLAlchemy `Engine` | Same broad handle type, but construction includes driver preparation and scheme-specific behavior. |
| S3 Storage | `metadata.ingestion.source.storage.s3.connection.get_connection(config)` | `S3ObjectStoreClient` containing S3 client, CloudWatch client, and session | Native AWS object access is available. The helper also creates the metrics client, which DCH's minimal discovery may not need. |

These are code-level seams, not evidence of a supported standalone public connector SDK. Inputs are OpenMetadata-generated typed connection models, not an arbitrary DCH settings dictionary. [PostgreSQL implementation](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/source/database/postgres/connection.py), [Db2 implementation](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/source/database/db2/connection.py), [S3 implementation](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/source/storage/s3/connection.py).

The observed `BaseConnection` owns lazy client construction and cleanup through a context manager. A generic dispatch module also exposes connection factories; it is undergoing migration between function and class forms in the reviewed snapshots. Reuse therefore needs a version-specific wrapper and lifecycle tests. [BaseConnection](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/connections/connection.py), [dispatch](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/source/connections.py).

## Where server independence ends

- **Stock connection testing:** PostgreSQL and Db2 call `test_connection_db_common`; S3 calls `test_connection_steps`. The inspected helper obtains the source's `TestConnectionDefinition` through `metadata.get_by_name`. Supplying `None` as the metadata client is therefore not a sufficient serverless adaptation. Low-level engine or S3 calls can be tested separately, but that would be DCH's testing path. [Test helpers](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/connections/test_connections.py).
- **Database discovery:** `CommonDbSourceService(config, metadata)` retains an OpenMetadata client and calls connection testing during initialization. It builds OpenMetadata database/schema/table requests and uses workflow context. Its basic discovery delegates to SQLAlchemy inspection for schema, table, and view names. This suggests a direct-driver route could recover the required basic discovery without adopting the full workflow, but the complete source class is not independent. [Common database source](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/source/database/common_db_source.py).
- **S3 discovery:** `S3Source` requires the metadata client and, within `get_containers`, looks up catalog `Container` entities by name and uses their identifiers. Replacing only the output sink would not eliminate this dependency. Direct bucket/object listing would need its own small adapter or a deliberate extraction. [S3 metadata source](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/source/storage/s3/metadata.py).

## Dependencies and deployment implications

The framework is packaged as `openmetadata-ingestion`; connector extras are added to shared base dependencies. PostgreSQL includes `psycopg2-binary` and GeoAlchemy2; Db2 includes `ibm-db-sa` and `ibm-db`; S3 has an extra and uses AWS clients. Packaging individual extras avoids installing every connector, but does not produce a tiny isolated factory-only distribution. [Package metadata](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/pyproject.toml), [dependency definitions](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/setup.py).

Db2 deserves a separate qualification: the implementation distinguishes `db2+ibm_db` and IBM i schemes, can install a selected CLI driver, and can write a provided license into the driver package directory. Its metadata module patches dialect reflection for types and z/OS columns. These are concrete maintenance responsibilities beyond filling a connection URL. [Db2 connection](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/source/database/db2/connection.py), [Db2 metadata](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/src/metadata/ingestion/source/database/db2/metadata.py).

For OpenShift, the inference is to validate driver staging at image build time and writable paths under the deployment's actual UID and filesystem settings; the inspected runtime install/write behavior cannot be assumed compatible. This is an untested packaging concern, not a demonstrated deployment failure.

## What DCH would still own

Even if licensing and extraction were acceptable, DCH would still need its namespace-scoped registry, credential resolution, one-time import mappings, client configuration export, basic discovery output model, registration status/errors, and authorization for using a registration. OpenMetadata's native handles do not themselves implement Arrow Flight. This is a scope inference from the examined interfaces.

For the current narrow requirement, the useful comparison is **OpenMetadata workflow adaptation versus SQLAlchemy/native-driver discovery**, not “connector coverage versus writing seven database protocols.” OpenMetadata itself builds on drivers; its extra value includes dialect fixes and rich metadata normalization. Whether those extras justify reuse has not been demonstrated for the minimal table/column and bucket/object scope.

## Next evidence needed

1. Select Db2 LUW, z/OS, or IBM i and the required authentication modes; “Db2” alone is insufficient to choose drivers.
2. Run direct-driver schema/read checks against PostgreSQL and that Db2 variant, and object-list/read checks against S3.
3. Pin any candidate framework and driver versions, verify their actual package licenses, and exercise the resulting image on OpenShift.
4. Treat later per-user identity support separately: the single shared identity assumed here does not establish Alice's individual source authorization.
