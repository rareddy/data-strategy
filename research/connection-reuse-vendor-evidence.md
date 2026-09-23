# Connection reuse: vendor and access-library evidence

Research date: 2026-09-17. Discovery findings, not an architecture decision. Companion: [Airbyte and OpenMetadata evidence](connection-reuse-connectors.md).

Follow-up correction: OpenMetadata's root Apache-2.0 license does not cover the ingestion connector code indiscriminately. The ingestion subtree carries the Collate Community License. See [code-level feasibility evidence](connection-reuse-openmetadata-feasibility.md) and [ingestion license](https://github.com/open-metadata/OpenMetadata/blob/main/ingestion/LICENSE). Root-license identification was insufficient for connector reuse.

## Agreed scope

- OpenShift deployment; DCH owns namespace-scoped source registrations.
- Support new registrations and import existing settings where feasible. Customers retain existing tools and credential stores; one additional credential entry in DCH is acceptable when reuse is unavailable.
- Import is one-time. DCH manages its own configuration afterward; synchronization from the originating tool is out of scope (user clarification after initial research).
- Initial metadata discovery on credential establishment: schemas, datasets, columns. S3 contains both structured files and documents; clients interpret content for now.
- Initial native-client access; unified Arrow Flight access remains a target. Ingestion is later.
- Sources: S3, Snowflake, Redshift, BigQuery, Oracle, PostgreSQL, IBM Db2.
- Subsequent scope update: Db2 is deferred; PostgreSQL and S3 are the representative cases for the next focused evaluation. The other listed sources remain in the broader scope.
- MIT/Apache-2.0 preferred; library versus separately deployed service is open.
- Single identity is a simplifying assumption for this investigation. It does not resolve the earlier requirement for source-enforced individual access.

## What commercial platforms actually reuse

**Snowflake:** a storage integration holds cloud access configuration and may serve multiple external stages. External access integrations combine allowed network locations and secret references for UDF/procedure access. These are reusable objects within Snowflake, not evidence of a general external connection export contract. [Storage integrations](https://docs.snowflake.com/en/sql-reference/sql/create-storage-integration), [external access integrations](https://docs.snowflake.com/en/developer-guide/external-network-access/creating-using-external-network-access).

Snowflake DESCRIBE SECRET documents metadata output, not a general plaintext credential export. This does not claim that authorized handler code can never access secret values. Also distinguish credentials used to connect *to Snowflake* from outbound integration credentials stored *inside Snowflake*. [DESCRIBE SECRET](https://docs.snowflake.com/en/sql-reference/sql/desc-secret).

**BigQuery:** connection resources have management APIs and sharing permissions. For Cloud SQL, the resource exposes instance/database/type, while the credential field is input-only. Reusing a BigQuery connection for a BigQuery operation therefore does not imply that DCH can export its password for a native client. These outbound connection resources are distinct from client authentication to BigQuery itself. [Manage connections](https://docs.cloud.google.com/bigquery/docs/working-with-connections), [connection resource schema](https://docs.cloud.google.com/bigquery/docs/reference/bigqueryconnection/rest/v1/projects.locations.connections).

Inference: the verified examples simplify reuse inside their product boundaries. They do not demonstrate a universal connection/secret-sharing API across products. Settings import, secret retrieval, and permission to use a connection are separate capabilities to evaluate.

## Other relevant ecosystems

| Technology | Verified relevance | Boundary or gap |
| --- | --- | --- |
| DataHub | Apache-2.0 metadata platform; connector directory includes all seven source families | Metadata connector coverage does not establish a live query service or credential export capability. S3 arbitrary-document inventory needs verification against configured path/file handling. |
| ADBC | API/client libraries for queries, Arrow results, and schema/catalog inspection | Drivers still exist underneath a common API; not itself a remote gateway or shared secret store. |
| ADBC JDBC adapter | Java adapter accepts JDBC URI or DataSource; documented Beta | JDBC availability is not qualification of Oracle/Db2 auth, types, or performance. Driver terms need separate checks. |
| Trino | Apache-2.0 live SQL engine; bundled list includes Snowflake, BigQuery, Redshift, Oracle, PostgreSQL | Db2 is absent from bundled list; IBM's separate plugin is archived. S3 table connectors are not general document access. |
| Gravitino | Metadata management; PostgreSQL and fileset catalogs documented | Published catalog list does not establish coverage of all seven required source families. |

Sources: [DataHub license and purpose](https://github.com/datahub-project/datahub/blob/master/README.md), [DataHub connector directory](https://docs.datahub.com/docs/generated/ingestion/sources/), [Db2 connector](https://docs.datahub.com/docs/generated/ingestion/sources/db2), [S3 connector](https://docs.datahub.com/docs/generated/ingestion/sources/s3); [ADBC overview](https://arrow.apache.org/adbc/current/index.html), [JDBC adapter](https://arrow.apache.org/adbc/current/driver/jdbc.html); [Trino license](https://trino.io/legal.html), [Trino connectors](https://trino.io/docs/current/connector.html), [archived IBM Db2 plugin](https://github.com/IBM/trino-db2); [Gravitino catalog list (development docs)](https://gravitino.apache.org/docs/next/).

**Arrow terminology:** Arrow defines the columnar representation; Flight is an RPC framework built on gRPC and Arrow IPC. Providing Flight transport does not itself implement source authentication, metadata discovery, or query execution. [Flight specification](https://arrow.apache.org/docs/format/Flight.html).

## Remaining questions exposed by evidence

1. Does reuse mean adopting a metadata ingestion runtime, or extracting its source-specific modules? Connector counts do not establish that extraction is supported.
2. Resolved: import is one-time and subsequent external changes need not synchronize.
3. Which authentication methods and Db2 editions are required? A source logo is insufficient qualification.
4. Metadata operations may require different permissions from ordinary reads even under the simplified shared identity.
5. No OpenShift deployment, SCC compatibility, source connectivity, or authentication path was tested in this documentation pass.
