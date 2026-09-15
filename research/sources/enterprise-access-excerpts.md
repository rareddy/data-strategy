# Cached Enterprise Access Source Excerpts

**Retrieved:** 2026-09-14 using the web tool. These are short verbatim excerpts, not full-page snapshots. [Findings and rationale](../enterprise-source-access-evidence.md) contain paraphrased evidence and design decisions.

## Snowflake — execute through an existing API

[Introduction to the SQL API](https://docs.snowflake.com/en/developer-guide/sql-api/intro), capabilities:

> Submit SQL statements for execution.

> Check the status of the execution of a statement.

## Redshift — asynchronous HTTP access

[Using the Amazon Redshift Data API](https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html), introduction:

> Instead, it provides a secure HTTP endpoint and integration with AWS SDKs.

> Calls to the Data API are asynchronous.

## Snowflake — destination trust and user mapping

[Configure custom authorization servers for External OAuth](https://docs.snowflake.com/en/user-guide/oauth-ext-custom), user attribute configuration:

> This attribute refers to attribute to identify users in your IdP.

The surrounding configuration also specifies issuer, audience, and the target Snowflake user attribute; those requirements are summarized in the research note.

## Additional primary sources consulted

The following pages were reviewed; their relevant findings are cached as paraphrases in the research note rather than verbatim snapshots:

- [BigQuery REST API](https://docs.cloud.google.com/bigquery/docs/reference/rest).
- [PostgreSQL password authentication](https://www.postgresql.org/docs/current/auth-password.html).
- [OAuth token exchange, RFC 8693](https://www.rfc-editor.org/rfc/rfc8693.html).
- [RDS IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html).
