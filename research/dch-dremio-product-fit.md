# Dremio as an existing product for DCH capabilities

Checked 2026-09-18 against current Dremio Software documentation (26.x). Documentation assessment only; no deployment or source connections tested.

## Finding

Dremio is a credible existing product to evaluate for source registration, metadata discovery, SQL execution, and Arrow Flight SQL access together. It is not established as an MIT/Apache-only solution for the complete requirement. Its documented BigQuery connector and external secrets integration require Enterprise; the standard Community build also includes dependencies under other licenses.

## Capability fit

| Requirement | Evidence and limit |
|---|---|
| Register once for discovery and execution | Dremio source configuration contains source-specific connection settings and metadata policy. The same source is queryable through Dremio. Its catalog REST API manages sources. This is reuse within Dremio; it does not establish native-client configuration delivery. |
| Source coverage | Current docs cover S3, PostgreSQL, Snowflake, Redshift, BigQuery, and Oracle. BigQuery is explicitly marked Enterprise. Do not equate documentation coverage with availability in every distribution. |
| Unified access | Flight SQL supports queries, prepared statements, and metadata requests. This is already a product capability, not a new server DCH must first implement. |
| Secrets | AWS Secrets Manager, Azure Key Vault, and HashiCorp Vault are documented Enterprise integrations. Vault supports Kubernetes authentication. AWS integration requires Dremio on AWS. |
| One-time settings import/export | Catalog REST APIs expose structured source configurations; secret values are masked as `$DREMIO_EXISTING_VALUE$`. Translating another product's settings and supplying missing credentials remains unproven integration work. |
| Native source access from notebooks | Flight connects clients to Dremio. No reviewed documentation establishes Dremio as a general credential/configuration broker for clients bypassing Dremio. This requirement remains a gap to investigate. |
| Namespace scope | Dremio sources and permissions belong to its own catalog/security model. Deployment in an OpenShift namespace does not establish per-source binding to arbitrary RHOAI project namespaces. Mapping or deployment isolation must be evaluated. |
| S3 documents | S3 support establishes object-storage access for Dremio's data engine. It does not establish a general PDF/document retrieval service. Preserve the native S3 path as a requirement to qualify, rather than counting SQL S3 support as satisfying it. |

Sources: [source API](https://docs.dremio.com/current/reference/api/catalog/source/), [source configuration and masking](https://docs.dremio.com/current/reference/api/catalog/source/container-source-config/), [Flight SQL](https://docs.dremio.com/current/developer/arrow-flight-sql/), [secrets management](https://docs.dremio.com/current/security/secrets-management/), [Vault](https://docs.dremio.com/current/security/secrets-management/hashicorp-vault/), [AWS secrets](https://docs.dremio.com/current/security/secrets-management/aws-secrets-manager).

Connector references: [S3](https://docs.dremio.com/current/data-sources/object/s3/), [PostgreSQL](https://docs.dremio.com/current/data-sources/databases/postgres/), [Snowflake](https://docs.dremio.com/current/data-sources/databases/snowflake/), [Redshift](https://docs.dremio.com/current/data-sources/databases/redshift/), [BigQuery—Enterprise](https://docs.dremio.com/current/data-sources/databases/google-bigquery/), [Oracle](https://docs.dremio.com/current/data-sources/databases/oracle/).

## Distribution and deployment qualification

The public `dremio-oss` repository has an Apache 2.0 root license. Its README explicitly distinguishes the default Community distribution, which includes non-OSS dependencies (including Oracle's driver), from an OSS-only build using `-Ddremio.oss-only=true`; the latter loses capabilities requiring excluded dependencies. Root licensing must not be used to label every included driver, Enterprise feature, or downloadable distribution Apache 2.0. [Repository license](https://github.com/dremio/dremio-oss/blob/master/LICENSE), [build and distribution explanation](https://github.com/dremio/dremio-oss#oss-only).

Current deployment documentation explicitly includes OpenShift instructions, override values, and security context constraints. The environment page lists OpenShift 4.18.x on x86-64/RHCOS and says testing is on ROSA. The documented Helm configuration uses the Enterprise image and requires a license. This is stronger evidence than generic Kubernetes compatibility, but does not prove Community support or validation on every customer OpenShift version. [Tested environments](https://docs.dremio.com/current/deploy-dremio/kubernetes-environments/), [deployment](https://docs.dremio.com/current/deploy-dremio/deploy-on-kubernetes/), [image and OpenShift configuration](https://docs.dremio.com/current/deploy-dremio/configuring-kubernetes/).

## Evaluation position

Updated after the user's licensing clarification: **Dremio is on hold, not a recommended foundation.** Each required connector and access path must pass permissive open-source qualification. BigQuery is documented Enterprise-only; root Apache licensing and the OSS-only build switch do not qualify all adapters, drivers or dependencies. See the [component license audit](dremio-permissive-license-audit.md). Namespace authorization, native-client access and arbitrary S3 object handling also remain unqualified. No custom DCH platform is proposed by this assessment.
