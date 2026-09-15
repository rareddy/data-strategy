# Enterprise Source Access — Evidence and Design Rationale

**Checked:** 2026-09-14. Primary documentation only. These are design inputs, not tested integrations. Short source excerpts are cached in [sources/enterprise-access-excerpts.md](sources/enterprise-access-excerpts.md). Cached excerpts are deliberately partial; the findings below preserve their architectural interpretation.

## 1. Existing HTTP APIs can avoid a new universal gateway

**Evidence.** Snowflake's SQL API supports submitting SQL, checking status, cancellation, and fetching results. It supports queries and many write statements, with documented limitations. [Snowflake SQL API](https://docs.snowflake.com/en/developer-guide/sql-api/intro).

BigQuery publishes a REST API, including query and job operations. [BigQuery API](https://docs.cloud.google.com/bigquery/docs/reference/rest).

Redshift's Data API is an asynchronous HTTP interface. It can use Secrets Manager credentials, temporary database credentials, or supported IAM Identity Center arrangements. Authorization to invoke the API and database authentication are distinct setup steps. [Redshift Data API](https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html).

**Decision.** Show a direct, OpenShell-mediated HTTP path alongside a trusted adapter path. Do not assume every source needs a new MCP server, DCH, or a native driver inside the agent. A customer's API must still support the requested operations, account mapping, and source permissions. An HTTP API alone does not establish delegated identity.

## 2. Identity propagation requires a destination-specific contract

**Evidence.** Snowflake External OAuth requires configured issuer, audience, user mapping, and scopes/roles. Role-switching behavior depends on integration settings. [Snowflake External OAuth](https://docs.snowflake.com/en/user-guide/oauth-ext-custom).

OAuth token exchange distinguishes delegation and impersonation; the authorization infrastructure determines permitted exchanges. This does not require every destination to support that flow. [RFC 8693](https://www.rfc-editor.org/rfc/rfc8693.html).

**Decision.** Bind the defined process user/workload to a logical source and approved source account/role. Authenticate that binding through trusted configuration. Do not treat an agent-supplied username header or an OpenShift login token as universally valid source credentials. Keep the workload's identity available for audit even where the source records only the represented account.

## 3. Legacy credentials need trusted native authentication

**Evidence.** PostgreSQL supports password authentication, including SCRAM-SHA-256. [PostgreSQL password authentication](https://www.postgresql.org/docs/current/auth-password.html). NVIDIA documents HTTP credential rewriting, not generic native-wire-protocol rewriting; see [OpenShell evidence](agent-data-access-evidence.md).

**Decision.** For a legacy PostgreSQL source lacking a suitable HTTP service, a trusted adapter uses the mapped source credential with a native driver. The agent only talks to the approved HTTP tool/API. Reusing existing customer adapters takes priority. A shared broad database login cannot silently substitute for the represented user's credential.

## 4. Authentication expiry and session termination are different

**Evidence.** RDS IAM database tokens expire after 15 minutes for authentication, but expiry does not affect an already established session. [RDS IAM authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html).

**Decision.** Separate secret refresh, token expiry, certificate reload, and active-session revocation. Existing sessions and remote jobs need explicit handling; do not claim that refreshing a proxy credential instantly revokes every source session. This RDS example demonstrates the distinction, not identical behavior across all sources.

## 5. Constraints derived from this conversation

These are architectural deductions from agreed requirements, not vendor feature claims:

- Keeping datasets out of the sandbox means S3/HDFS analysis needs an existing query/compute service near storage; object/file access is not itself query processing.
- Source-authorized results may still contain sensitive data. Control result-producing operations and approved model destinations; a byte limit alone does not prevent repeated extraction.
- Autonomous writes need handling for uncertain outcomes. A retry after a timeout could repeat an operation, so use source-supported idempotency or reconcile its status.
- Process identity is stable for the initial architecture. Do not introduce per-run user switching or shared-user sessions before their isolation model is defined.

## Research limits

No connector was deployed or tested. Authentication and operation coverage must be validated per source and customer configuration. This note does not establish generic S3/HDFS source-side compute, universal OAuth delegation, or support for all SQL/transaction operations through every HTTP API.
