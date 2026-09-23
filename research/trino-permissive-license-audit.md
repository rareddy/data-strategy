# Trino connector and access license audit

Date: 2026-09-18. Scope: bounded source/build-file and first-party documentation review, principally Trino release tag **483**. This is not a resolved dependency tree, SBOM, container audit, or approval of a complete runtime. Some upstream license links are moving branches; their exact packaged versions remain to be checked.

## Decision

**Trino remains a conditional structured-access candidate, not an approved permissive-only distribution. The user has accepted the Oracle vendor driver and required companion libraries as a license exception, so those artifacts no longer block selection.** The other paths have useful permissive component evidence but still require version-specific dependency checks. Trino does not establish the equally important unstructured object retrieval requirement.

The [Trino 483 root license](https://github.com/trinodb/trino/blob/483/LICENSE) is Apache 2.0. This covers Trino's own code; it does not relicense vendor JDBC drivers, SDKs, dependencies, or the JDK/container image.

## Required connectors

| Source | Inspected path and evidence | License finding | Qualification status |
|---|---|---|---|
| PostgreSQL | [PostgreSQL connector POM](https://github.com/trinodb/trino/blob/master/plugin/trino-postgresql/pom.xml) uses `org.postgresql:postgresql`; it also includes geometry dependencies such as `org.locationtech.jts:jts-core`. The fetched moving-branch POM identified itself as 481-SNAPSHOT, so this row is not pinned to 483. | [pgjdbc license](https://github.com/pgjdbc/pgjdbc/blob/master/LICENSE) has BSD two-clause terms. This is permissive but is not literally MIT/Apache. | Connector and primary driver evidence favorable; **full path unverified**. Geometry and all runtime dependencies still need classification; do not infer approval from pgjdbc alone. |
| Snowflake | [483 connector POM](https://github.com/trinodb/trino/blob/483/plugin/trino-snowflake/pom.xml) requires `net.snowflake:snowflake-jdbc`. | [Snowflake JDBC license](https://github.com/snowflakedb/snowflake-jdbc/blob/master/LICENSE.txt) is Apache 2.0. Snowflake documents fat/thin driver distributions and [third-party notices](https://github.com/snowflakedb/snowflake-jdbc/blob/master/src/main/javadoc/licenses.html). | **Conditional**. Resolve exact driver version and bundled/shaded dependencies before approving the binary path. |
| Redshift | [483 connector POM](https://github.com/trinodb/trino/blob/483/plugin/trino-redshift/pom.xml), retrieved directly from upstream, requires `com.amazon.redshift:redshift-jdbc42:2.2.7`; also references Trino S3 and Parquet modules. | [AWS Redshift JDBC source license](https://github.com/aws/amazon-redshift-jdbc-driver/blob/master/LICENSE) explicitly says BSD-2-Clause. | **Conditional**. Exact 2.2.7 packaged notices, authentication dependencies, S3 unload path, and runtime closure not audited. |
| BigQuery | [483 connector POM](https://github.com/trinodb/trino/blob/483/plugin/trino-bigquery/pom.xml) directly requires Google BigQuery and BigQuery Storage libraries, Google authentication, gRPC, Arrow, and other dependencies. | [Google BigQuery library license](https://github.com/googleapis/java-bigquery/blob/main/LICENSE) is Apache 2.0. This path uses Google client libraries; it is not evidence of dependence on a commercial Simba JDBC driver. | **Conditional**. BigQuery Storage and every resolved authentication/transport/transitive artifact still require exact-version license inspection. |
| Oracle | [483 connector POM](https://github.com/trinodb/trino/blob/483/plugin/trino-oracle/pom.xml) requires `com.oracle.database.jdbc:ojdbc11`, `com.oracle.database.jdbc:ucp`, and runtime `com.oracle.database.nls:orai18n`. Versions are inherited and were not resolved in this review. | Trino's Apache wrapper does not cover these Oracle artifacts. Oracle distributes JDBC under vendor terms, discussed below. | **Accepted driver exception**; remaining connector/runtime qualification still applies. |
| S3 structured tables | [Trino S3 documentation](https://trino.io/docs/current/object-storage/file-system-s3.html) describes native S3 support through Hive, Iceberg, Hudi, or Delta Lake catalogs. | [AWS SDK for Java v2](https://github.com/aws/aws-sdk-java-v2/blob/master/LICENSE.txt) is Apache 2.0, but that alone does not qualify a complete table connector/metastore/format stack. The exact S3 module dependency closure was not retrieved. | **Conditional**. Select and audit an actual table connector and metastore configuration, including optional filesystem dependencies. |

### Oracle distribution distinction

The following records the license facts; the user has accepted these vendor-driver artifacts as an exception for product selection.

The [Oracle JDBC downloads page](https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html) explicitly points to [Oracle Free Distribution, Hosting, and Use Terms (FDHUT)](https://download.oracle.com/otn-pub/otn_software/jdbc/FDHUT_LICENSE.txt). Those terms permit specified uses and distribution of unmodified software, but restrict modification and reverse engineering. They are not MIT/Apache-style permissive open-source terms.

The publisher's [ojdbc11 21.17.0.0 Maven metadata](https://central.sonatype.com/artifact/com.oracle.database.jdbc/ojdbc11/21.17.0.0) instead declares Oracle Free Use Terms and Conditions. **Do not assume the download-page license is the exact license shipped with Trino's resolved Maven artifacts.** Both pieces of evidence prevent blanket permissive approval, but the precise Trino version, artifact license files, UCP, and internationalization companion terms must be resolved individually. Free availability or permission to redistribute does not establish permissive open-source licensing.

## Client-facing access points

| Access point | Evidence | Status |
|---|---|---|
| HTTP SQL query endpoint | The official [client protocol](https://trino.io/docs/current/develop/client-protocol.html) documents Trino's query REST API. The server is Trino code under the root Apache license. | Source-level permissive evidence; deployed server dependency closure unverified. |
| JDBC client | Official [JDBC documentation](https://trino.io/docs/current/client/jdbc.html) identifies Trino's own driver. It belongs to the Apache-licensed Trino repository. | Source-level permissive evidence; packaged client dependencies unverified. This is separate from the vendor JDBC driver running inside the server's connector. |
| Python DB-API / SQLAlchemy client | The [official Python client license](https://github.com/trinodb/trino-python-client/blob/master/LICENSE) is Apache 2.0. | Source-level permissive evidence; exact Python release, optional authentication extras, and installed dependency set unverified. |
| Arrow Flight | No first-party Flight server path was qualified by this investigation. | **Unknown/unqualified**, not implied by Arrow usage inside a connector. Any external gateway requires its own audit. |

## Structured and unstructured parity

The S3 documentation describes storage access for table connectors. It does not establish a client-facing bucket/object discovery and arbitrary PDF/document byte-retrieval API. Therefore Trino's S3 support must not be presented as satisfying the unstructured requirement. A separately identified object access component and its client dependencies must be qualified alongside the structured path.

## Remaining evidence required for selection

1. Pin the actual Trino release, enabled plugins, client releases, and deployment image.
2. Resolve compile/runtime/provided dependencies, shaded jars, optional authentication modes, and their included license/notice files. Test-only dependencies should not be confused with shipped dependencies.
3. Decide whether the policy permits other permissive licenses such as BSD-2-Clause, rather than interpreting the user's MIT/Apache examples as an exclusive list.
4. Treat JDK and base-image licensing as a separate deployment boundary; a permissive application component claim is not a permissive-only operating-system claim.
5. Qualify an unstructured access path independently. No live source, OpenShift deployment, or complete image was tested in this review.
