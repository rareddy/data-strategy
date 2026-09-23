# Source contracts for one registration: PostgreSQL and S3

Date: 2026-09-17. Primary-documentation and source-code assessment, not a live integration test. Db2 is deferred. This note describes concrete client inputs and limitations; it does not select an architecture.

## Finding

The same resolved PostgreSQL connection parameters can open sessions for metadata discovery and SQL reads. The same resolved S3 session/client settings can support object listing and object reads. They need not be the same live connection object. This is an inference from the APIs below, not evidence that DCH already implements the mapping or credential delivery.

User-established scope: one namespace-scoped registration, one shared identity for the initial case, discovery when credentials are established, one-time imports, and clients interpreting S3 file/document contents. The shared identity is a simplification; it does not implement Alice-specific source authorization.

## PostgreSQL: reusable inputs

For a bounded password-authenticated TCP connection, these are the inputs a resolver must reproduce for both uses. The names below are native libpq parameters, not a proposed DCH API.

| Input | Purpose |
| --- | --- |
| `host`, `port`, `dbname` | Server and database selection. Explicit values avoid environment-dependent defaults. |
| `user`, resolved `password` (or `passfile`) | Shared source identity and authentication. A credential reference is not itself a libpq password. |
| `connect_timeout` | Bounds connection establishment. |
| `sslmode` | Preserves the actual TLS verification policy. |
| `sslrootcert` | Local CA bundle location, when using custom trust. |
| Optional `sslcert`, `sslkey`, `sslpassword` | Client certificate/key and encrypted-key passphrase when required. |

These parameters are documented by [libpq connection control](https://www.postgresql.org/docs/current/libpq-connect.html). This is a bounded field list; Kerberos, OAuth, multi-host failover, and every libpq extension are not qualified here.

Psycopg accepts libpq connection strings and keyword arguments through `psycopg.connect()`. The resulting connection executes both metadata SQL and data SQL through `execute()`/cursors. Keyword arguments override values in the connection string; inconsistent duplicated representations therefore have observable consequences. [Psycopg connection API](https://www.psycopg.org/psycopg3/docs/api/connections.html).

TLS mapping cannot collapse into a generic `tls: true`: `require` requests encryption, `verify-ca` checks trust, and `verify-full` also checks the server name. Certificate/key paths are runtime-local resources, not portable references to files on the importing tool's machine. On Unix, libpq also checks private-key file permissions. These facts require qualification in the actual container image and mounts. [PostgreSQL TLS behavior](https://www.postgresql.org/docs/current/libpq-ssl.html).

### Discovery and reads

`information_schema.tables` provides catalog/database, schema, name, and table type for tables/views visible to the current user. It is scoped to the connected database; it does not inventory every database on the server. Visibility requires ownership or some privilege, not specifically `SELECT`. [Tables view](https://www.postgresql.org/docs/current/infoschema-tables.html).

`information_schema.columns` provides column name/order, nullability, default, type, character length, numeric precision/scale, and native/domain type identifiers. Preserve native type identifiers: a single `data_type` string is insufficient for domains, arrays, and user-defined types. System columns are excluded. Column visibility is also privilege-filtered. [Columns view](https://www.postgresql.org/docs/current/infoschema-columns.html).

Consequently, discovery success does not prove that `SELECT *` will succeed. A metadata entry is not an access grant. A read uses the same identity but is subject to source authorization at execution time. PostgreSQL row policies can further constrain results; table owners and privileged roles can bypass policies under documented conditions. [Row security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html).

Discovery schema filters are workflow inputs, not authentication parameters. They must not be described as source-enforced restrictions: native clients holding the same credentials can attempt other queries permitted by the source. This is an inference from the separation of connection and query APIs.

## S3: reusable inputs

Bounded initial case: AWS general-purpose S3 bucket. Custom endpoint fields are included to preserve imported configurations, but this note does not qualify arbitrary S3-compatible implementations, directory buckets, access points, or Outposts.

| Input | Native mapping / role |
| --- | --- |
| Region | `Session(region_name=...)` or client region. |
| Credential binding | Explicit key ID/secret and optional session token, or a configured SDK credential provider. |
| Optional endpoint URL | `client('s3', endpoint_url=...)`; complete URL including scheme. |
| Trust settings | `verify=True`/default trust or a local CA bundle filename. |
| Optional addressing style | `Config(s3={'addressing_style': 'auto'|'virtual'|'path'})`. |
| Bucket and optional prefix | Listing/read scope, supplied to operations rather than session constructor. |
| Optional expected owner / requester-pays setting | Operation parameters where applicable. |

Session/client inputs and TLS behavior are documented in [Boto3 Session](https://docs.aws.amazon.com/boto3/latest/reference/core/session.html). An explicit endpoint URL controls the scheme and overrides `use_ssl`; a custom CA filename must exist in each consumer runtime. Addressing style, timeouts, retry settings, and proxy configuration are described by [Botocore Config](https://docs.aws.amazon.com/botocore/latest/reference/config.html).

### Discovery and reads

For a registered bucket, use a `list_objects_v2` paginator with `Bucket` and optional `Prefix`. Capture key, size, modification time, and available object attributes. Listing returns at most 1,000 objects per service request, so a single successful page is not a complete inventory. General-purpose buckets require `s3:ListBucket`. Registering a known bucket avoids making account-wide bucket enumeration part of the minimum contract. [ListObjectsV2](https://docs.aws.amazon.com/boto3/latest/reference/services/s3/client/list_objects_v2.html).

The same client can call `get_object(Bucket=..., Key=...)` and consume its streaming response. Reading a current object requires `s3:GetObject`; a specified version uses `s3:GetObjectVersion`. KMS-encrypted objects need relevant KMS authorization, and some archived objects must be restored before reading. Thus successful listing is not proof of read access. File format parsing is outside this contract. [GetObject](https://docs.aws.amazon.com/boto3/latest/reference/services/s3/client/get_object.html).

Bucket/prefix selection is not an IAM boundary unless the source policies enforce it. A native client can issue other operations allowed by its credentials. This is an inference from the operation-specific permissions above.

### Shared identity does not mean a permanent credential value

Boto3 supports provider-based credential resolution, including configured assume-role and web-identity flows. For supported role profiles it obtains temporary credentials and refreshes them automatically; clients from one session share the cached credentials. Provider configuration and its prerequisite credentials/token files must be usable in each runtime. [Boto3 credential providers](https://docs.aws.amazon.com/boto3/latest/guide/credentials.html).

Do not treat exported temporary key/secret/token values as a refresh mechanism. Botocore's explicit-key client branch constructs plain `Credentials`; otherwise it obtains credentials from its resolver. Copying values alone does not transfer the provider's refresh process. [Botocore client construction source](https://github.com/boto/botocore/blob/develop/botocore/session.py). This observation is source-based and must be checked against the version pinned for deployment.

## What is established versus still untested

Psycopg is an API example here, not an MIT/Apache dependency selection: its repository license is LGPL v3. The plain Python installation also requires local libpq; the binary distribution bundles libraries. Qualification must record the chosen distribution and its dependencies. [Psycopg license](https://github.com/psycopg/psycopg/blob/master/LICENSE.txt), [installation](https://www.psycopg.org/psycopg3/docs/basic/install.html).

Established: both libraries have the operations needed to reuse one source registration for basic discovery and native reads; separate discovery credentials are not an API requirement. Permissions, TLS material, and credential lifecycle still affect the two consumers independently.

Not established: DCH's actual serialization/resolution behavior, delivery to notebooks, OpenShift runtime compatibility, network reachability from both workloads, rotation/refresh in deployed pods, or equivalence across other client libraries. No live PostgreSQL/S3 tests were performed for this note.

Meaningful qualification cases: a PostgreSQL table visible through a non-SELECT privilege, a column-restricted reader, quoted identifiers and native types; an S3 listing spanning multiple pages with one unreadable object; TLS with a custom CA; temporary credentials surviving their initial expiration through the selected provider. Record discovery completeness separately from connectivity and successful bounded reads.
