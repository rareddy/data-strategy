# DCH connection reuse: focused feasibility assessment

Date: 2026-09-17. Scope: PostgreSQL, Db2, and S3; initial discovery and direct client reads. One identity per namespace-scoped registration is a simplification. Import is one-time and DCH owns subsequent configuration. This is an evidence assessment, not an adopted architecture.

Scope update: the user deferred Db2 after this assessment. Continue the focused evaluation with PostgreSQL and S3; retain Db2 findings below as background, not an active requirement or blocker. Snowflake, Redshift, BigQuery, and Oracle remain in the broader source scope.

## Result

Basic database discovery is already a driver capability. A separate metadata product is not technically required merely to enumerate schemas, tables/views, and columns. OpenMetadata adds metadata-specific behavior, but its complete discovery workflows depend on OpenMetadata services; its ingestion code also has a separate license from the Apache-2.0 root. See [OpenMetadata code investigation](connection-reuse-openmetadata-feasibility.md).

Inference: the direct-driver path is a credible baseline for this limited scope. It removes a metadata-platform runtime dependency but leaves DCH responsible for registration, configuration mapping, discovery orchestration, persistence, and access integration. It is not proof that all seven sources or authentication methods are qualified.

## Capability comparison

| Source | Direct-driver capability | What still needs qualification |
| --- | --- | --- |
| PostgreSQL | JDBC exposes database metadata and query execution. Native PostgreSQL ADBC is documented stable, wraps libpq, and supports ADBC metadata/query APIs. | TLS/auth mappings, metadata visibility, views, native types, timeouts, pagination/batch handling, client packaging. |
| Db2 | IBM documents JDBC metadata access and a type-4 driver. Standard JDBC covers schema/table/column discovery and queries. | Exact Db2 platform, IBM driver distribution terms, credentials/TLS, type behavior and metadata completeness. The ADBC JDBC adapter is Beta, not evidence of a tested Db2 Arrow integration. |
| S3 | AWS SDK can list objects with pagination and stream object bytes; the same configured client can perform both. | Bucket/prefix scope, endpoint/region/TLS, credentials, object version behavior, permissions. Interpretation of PDFs/CSV/Parquet remains the client's task. |

Sources: [JDBC metadata contract](https://docs.oracle.com/en/java/javase/21/docs/api/java.sql/java/sql/DatabaseMetaData.html), [PostgreSQL ADBC](https://arrow.apache.org/adbc/current/driver/postgresql.html), [IBM metadata methods](https://www.ibm.com/docs/en/db2/12.1.x?topic=programming-learning-about-data-source-using-databasemetadata-methods), [IBM JDBC drivers](https://www.ibm.com/docs/en/db2/12.1.x?topic=apis-supported-drivers-jdbc-sqlj), [ADBC JDBC adapter](https://arrow.apache.org/adbc/current/driver/jdbc.html), [S3 listing](https://docs.aws.amazon.com/boto3/latest/reference/services/s3/paginator/ListObjectsV2.html), [S3 reads](https://docs.aws.amazon.com/boto3/latest/reference/services/s3/client/get_object.html).

## Existing API boundaries

**JDBC:** a configured connection supplies `getMetaData()`. `DatabaseMetaData.getSchemas`, `getTables`, and `getColumns` provide the required discovery primitives; column results include ordinal, native type name, size, scale, and nullability. The same connection can execute statements. Missing metadata may return empty results, and catalog/schema semantics depend on the driver and DBMS. This is a common interface over vendor implementations, not identical behavior across databases. [JDBC contract](https://docs.oracle.com/en/java/javase/21/docs/api/java.sql/java/sql/DatabaseMetaData.html).

**ADBC:** `getObjects` exposes a hierarchy of catalogs, schemas, tables, and columns; query execution returns Arrow data. The Java JDBC adapter accepts a JDBC URI or an existing `javax.sql.DataSource`. Its Java API is not automatically a native Python Db2 driver. [JDBC adapter](https://arrow.apache.org/adbc/current/driver/jdbc.html), [version 24 JdbcConnection API](https://arrow.apache.org/adbc/24/java/api/org/apache/arrow/adbc/driver/jdbc/JdbcConnection.html).

**Python database access:** SQLAlchemy Inspector exposes `get_schema_names`, `get_table_names`, `get_view_names`, and `get_columns`. Dialects/drivers implement those operations. This is relevant because the inspected OpenMetadata PostgreSQL/Db2 connection builders produce SQLAlchemy engines. Reusing a connection builder does not automatically reuse the complete metadata workflow. [SQLAlchemy reflection](https://docs.sqlalchemy.org/en/20/core/reflection.html), [OpenMetadata investigation](connection-reuse-openmetadata-feasibility.md).

**S3:** `ListObjectsV2` and `GetObject` form an object-discovery/read pair. An SDK session can use explicit credentials, profiles, or supported role providers. Generic support for web identity does not establish that a customer's OpenShift token is trusted by AWS; that trust/configuration remains deployment-specific. [Boto3 credential providers](https://docs.aws.amazon.com/boto3/latest/guide/credentials.html).

PyArrow also offers S3 filesystem listing and byte-stream access; it does not require parsing a PDF as a table. This is another client library option, not evidence that database and object APIs have become identical. [Arrow filesystem interface](https://arrow.apache.org/docs/python/filesystems.html).

## Dependencies and licensing

- PostgreSQL JDBC is pure Java, BSD-2-Clause (permissive, but not literally MIT/Apache). Native ADBC PostgreSQL adds a C/C++ driver and libpq; client libraries do not eliminate those deployment dependencies. [pgJDBC](https://jdbc.postgresql.org/), [license](https://jdbc.postgresql.org/license/), [ADBC driver](https://arrow.apache.org/adbc/current/driver/postgresql.html).
- IBM type-4 JDBC offers a different packaging path from Python `ibm-db`/CLI libraries. IBM license requirements vary by product/platform; do not label the vendor driver Apache-2.0 just because an adapter is Apache-licensed. [IBM supported drivers](https://www.ibm.com/docs/en/db2/12.1.x?topic=apis-supported-drivers-jdbc-sqlj), [IBM license files](https://www.ibm.com/docs/en/db2/12.1.x?topic=licenses-db2).
- Boto3 is Apache-2.0. [Repository](https://github.com/boto/boto3).
- OpenMetadata ingestion connector files carry Collate Community License headers. The prior root-license-only finding is corrected in the earlier research note. [Ingestion license](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/LICENSE).

## Work that remains DCH-specific under either path

These are inferred responsibilities, not proposed components:

1. Store namespace-scoped source settings and an authorized credential binding.
2. Map imported settings into the selected driver's configuration. JDBC URLs, SQLAlchemy options, and SDK settings are not interchangeable strings.
3. Trigger discovery and save a source-native schema snapshot, including errors/partial results. A credential check succeeding is not proof that all metadata can be enumerated.
4. Make equivalent configuration available to authorized native clients. A live engine object cannot be transferred from a service into a notebook; the notebook constructs its own client and retains its driver dependency.
5. Handle TLS material, rotation/refresh, connection failures, and cancellation across the chosen source drivers.
6. If later offering Flight, implement/choose server-side source execution and translate results. ADBC is a client API; Flight is a transport. Neither supplies DCH's namespace or credential policies.

## What was and was not validated

Subsequent validation: a local isolated PostgreSQL check now verifies discovery and authorized reads through one restricted libpq identity, plus metadata visibility without SELECT. See [execution evidence](connection-registration-validation.md). The original assessment below remains documentation-only; S3 and OpenShift are still untested.

Validated by primary documentation and OpenMetadata source inspection: required driver APIs exist; OpenMetadata engine/client construction can be distinguished from server-dependent workflows; source-specific license and packaging boundaries exist.

No live PostgreSQL, Db2, S3, or OpenShift qualification was performed. No test credentials/endpoints were supplied. The local environment has Boto3 but no PyArrow, SQLAlchemy, native PostgreSQL ADBC, or psycopg package. Installing libraries alone would not validate source access.

Useful next execution gates, if proceeding to a prototype: a PostgreSQL schema containing a view, quoted identifiers and decimal/time types; the actual target Db2 edition; an S3 prefix with more than one listing page and both tabular/document objects. Compare discovery output and a bounded read using one registration, then check the chosen image under OpenShift runtime constraints. These are future validation gates, not reported test results.
