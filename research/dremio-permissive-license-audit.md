# Dremio connector and access license audit

Checked: 2026-09-18. Scope: whether the components needed for the proposed access layer have affirmative permissive open-source evidence. This is a component qualification, not a completed distribution dependency audit.

**Decision: hold Dremio out of the qualified permissive-product shortlist.** Its public core and inspected access-point source files are Apache 2.0, but that does not establish permissive licensing for all required connectors or the shipped product. BigQuery is Enterprise/Cloud-only in the published edition matrix. Several other connector implementations remain unverified. Equal structured and unstructured access remains a separate functional gate.

**Scope update:** Oracle vendor-driver and required companion-library licensing is now an accepted exception. Dremio remains on hold because the exception does not resolve its connector implementation, commercial BigQuery feature, or other distribution dependencies.

## Evidence boundaries

The public tree was inspected at commit [`799ccbda47e6f2e1bfacf1ccbded174e00d4150a`](https://github.com/dremio/dremio-oss/tree/799ccbda47e6f2e1bfacf1ccbded174e00d4150a). Its [root license](https://github.com/dremio/dremio-oss/blob/799ccbda47e6f2e1bfacf1ccbded174e00d4150a/LICENSE) is Apache 2.0. The [edition matrix](https://docs.dremio.com/editions/) labels its comparison Community 26.0+, Enterprise 26.1, and Cloud; it is not a license manifest for this commit or a specific container image.

The [build instructions](https://github.com/dremio/dremio-oss/blob/799ccbda47e6f2e1bfacf1ccbded174e00d4150a/README.md) explicitly say normal builds include dependencies under non-OSS licenses and offer `-Ddremio.oss-only=true`. **OSS-only does not mean permissive-only**, nor does it guarantee the required connectors survive the exclusion. The pinned [daemon build manifest](https://github.com/dremio/dremio-oss/blob/799ccbda47e6f2e1bfacf1ccbded174e00d4150a/dac/daemon/pom.xml) puts `dremio-ce-jdbc-plugin`, Redshift JDBC 2.1.0.28 and Oracle `ojdbc10` 19.22.0.0 in its community profile, which is disabled by that flag. PostgreSQL and MariaDB drivers appear outside this profile. A driver dependency alone does not establish the adapter's license or usable connector availability.

## Component results

“Verified permissive” below applies only to the identified source component, not all of its transitive dependencies or a complete deployable image. “Unknown” fails the current selection gate until resolved; it is not an assertion of proprietary licensing.

| Component | Status | Evidence and practical consequence |
|---|---|---|
| Public Dremio core source | Verified permissive | Root Apache 2.0 license. Do not extend this finding to binaries or separately supplied plugins. |
| S3 adapter implementation | Verified permissive source; full runtime unknown | [`S3StoragePlugin.java`](https://github.com/dremio/dremio-oss/blob/799ccbda47e6f2e1bfacf1ccbded174e00d4150a/plugins/s3/src/main/java/com/dremio/plugins/s3/store/S3StoragePlugin.java) carries an Apache 2.0 header. Requires dependency qualification. It does not establish raw PDF/document retrieval through Dremio's public interface. |
| PostgreSQL connector | Unknown end-to-end | Community availability is documented, and a PostgreSQL JDBC dependency is present. The inspected public tree did not establish the matching production adapter implementation and its license. Do not infer that adapter's license from the driver. |
| Snowflake connector | Unknown end-to-end | Community availability in the matrix is insufficient licensing evidence. No matching production adapter/license was established in the inspected tree. Snowflake Open Catalog is a different integration. |
| Amazon Redshift connector | Unknown end-to-end | Community availability is documented; the community profile adds Redshift JDBC 2.1.0.28 and the separate JDBC plugin. Neither removal by OSS-only nor inclusion in Community by itself proves the exact adapter/driver license. |
| BigQuery connector | Commercial-edition path; permissive implementation unverified | Matrix excludes it from Community and includes Enterprise/Cloud. No permissively licensed implementation for the proposed off-the-shelf path was established. Does not pass. |
| Oracle connector | Unknown adapter/runtime; vendor-driver exception accepted | Community profile includes Oracle `ojdbc10` 19.22.0.0. The vendor driver is covered by the accepted exception. Adapter and other runtime terms remain unqualified. |
| Arrow Flight / Flight SQL server source | Verified permissive source; full runtime unknown | [`DremioFlightProducer.java`](https://github.com/dremio/dremio-oss/blob/799ccbda47e6f2e1bfacf1ccbded174e00d4150a/services/arrow-flight/src/main/java/com/dremio/service/flight/DremioFlightProducer.java) carries an Apache 2.0 header and implements `FlightSqlProducer`. It establishes that implementation source, not all authentication modes or edition capabilities. |
| Apache Arrow Java client | Verified permissive project license; selected artifact still needs audit | Apache's [license](https://github.com/apache/arrow-java/blob/main/LICENSE.txt) is Apache 2.0 with dependency notices. This finding does not cover arbitrary Dremio-branded ODBC/JDBC installers or third-party clients. |
| REST catalog/source management source | Verified permissive source; full runtime unknown | [`CatalogResource.java`](https://github.com/dremio/dremio-oss/blob/799ccbda47e6f2e1bfacf1ccbded174e00d4150a/dac/backend/src/main/java/com/dremio/dac/api/CatalogResource.java) has an Apache 2.0 header and catalog read/create/update routes. Does not establish exportable secrets. |
| REST SQL execution source | Verified permissive source; full runtime unknown | [`SQLResource.java`](https://github.com/dremio/dremio-oss/blob/799ccbda47e6f2e1bfacf1ccbded174e00d4150a/dac/backend/src/main/java/com/dremio/dac/api/SQLResource.java) has an Apache 2.0 header. Does not prove a generic object download API. |
| Ordinary Community distribution | Not qualified as permissive-only | Build instructions explicitly include non-OSS dependencies; root license cannot certify the distribution. |
| OSS-only distribution | Unknown permissive-only status and required connector coverage | The build filter excludes non-OSS profile components, not necessarily copyleft dependencies. Need resolved dependency inventory and actual source-access tests. |

## What would be needed to lift the hold

1. Select an exact build/image and enumerate the actual adapter, driver, endpoint and dependency artifacts.
2. Obtain affirmative permissive license evidence for each required artifact, including authentication and credential integrations.
3. Demonstrate all six retained sources without relying on unqualified commercial connectors. Db2 remains deferred.
4. Demonstrate raw object/document discovery and retrieval as well as table access. A licensed S3 table adapter does not satisfy that requirement on its own.

The license gate concerns software we would deploy or redistribute for the access layer. It does not require the remote Snowflake, BigQuery or Oracle service itself to be open source. No live build, SBOM scan, endpoint test or OpenShift deployment was performed for this audit.
