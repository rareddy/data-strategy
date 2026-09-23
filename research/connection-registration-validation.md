# One registration for discovery and direct access

Date: 2026-09-17. PostgreSQL and S3 only; Db2 deferred. Follow-up to [feasibility assessment](connection-reuse-feasibility.md) and [source contracts](connection-registration-source-contracts.md).

## Finding

One source configuration and identity can supply both discovery and reads. Separate consumer sessions do not require separate user-entered registrations. This does not mean every consumer accepts the same configuration format, or that discovery grants permission to read.

## Concrete registration contents

These are logical inputs for evaluation, not a committed DCH schema:

| Shared registration content | PostgreSQL | S3 |
| --- | --- | --- |
| Identity of registration | Namespace, name, source type | Namespace, name, source type |
| Source location | Host, port, database | Region, bucket, optional endpoint |
| Authentication binding | Username and credential reference/provider | Credential reference/provider |
| Trust configuration | Verification mode and CA/client-cert bindings | HTTPS endpoint and CA binding |
| Discovery selection | Schemas/tables to enumerate | Optional object prefix |

Selection filters control discovery scope, not source authorization. Credential references must be resolved through an authorized path; libraries do not inherently understand a DCH reference. Trust-file paths are local to each runtime. Native PostgreSQL type details should be retained alongside any normalized types. See [libpq inputs](https://www.postgresql.org/docs/current/libpq-connect.html), [column metadata](https://www.postgresql.org/docs/current/infoschema-columns.html), [Boto3 client inputs](https://docs.aws.amazon.com/boto3/latest/reference/core/session.html).

## Consumption of the same registration

| Consumer | PostgreSQL | S3 |
| --- | --- | --- |
| Initial discovery | Resolve connection inputs; enumerate schemas/tables/views/columns | Resolve client inputs; paginate objects in selected bucket/prefix |
| Native client | Resolve equivalent inputs in client runtime; execute authorized SQL | Resolve equivalent inputs; stream selected object bytes |

The discovery result contains metadata. It need not contain credential values. One-time import maps available external fields to this registration; credentials and local trust material may need to be supplied again. No subsequent synchronization from the originating tool is required.

Inference: DCH needs a maintained mapping from its registration into each supported client family. Reusing native libraries reduces protocol implementation work, but does not supply namespace authorization, secret resolution, or configuration delivery. Client-side source drivers remain until reads execute behind a service such as the contemplated Flight layer. No such layer was implemented here.

## Executed PostgreSQL validation

Used the already-present `postgres:16` container image, with no network and no published port. Test-only local trust authentication was used; this did not exercise passwords, TLS, remote access, or credential storage. Fixture setup ran as the disposable administrator. Discovery and reads ran together through psql/libpq as `dch_reader` with a single `PGUSER`/`PGDATABASE` configuration.

The container was stopped and automatically removed after validation.

| Check | Observed result |
| --- | --- |
| Enumerate two tables and one view | All three discovered |
| Inspect columns | Seven column entries across the tables/view |
| Quoted column name and nullability | `Customer Name`, non-null, verified |
| Decimal precision and scale | `numeric(12,2)` verified |
| Authorized view read | Expected amount `12.34` returned to the restricted role |
| Table with INSERT but no SELECT | Appeared in metadata; SELECT failed with insufficient privilege, as expected |

The assertion script exited with code 0 and printed both PASS notices. Reproducible artifacts: [fixture](connection-checks/postgres-fixture.sql), [assertions](connection-checks/postgres-check.sql). These files are for a disposable database only.

Reproduction (requires container runtime access):

```bash
docker run --rm -d --name dch-connection-check --network none \
  -e POSTGRES_HOST_AUTH_METHOD=trust docker.io/library/postgres:16
# Wait for PostgreSQL readiness before loading the fixture.
docker exec dch-connection-check pg_isready -U postgres
docker exec -i dch-connection-check psql -X -U postgres -d postgres \
  -v ON_ERROR_STOP=1 < research/connection-checks/postgres-fixture.sql
docker exec -i -e PGUSER=dch_reader -e PGDATABASE=postgres \
  dch-connection-check psql -X -v ON_ERROR_STOP=1 \
  < research/connection-checks/postgres-check.sql
docker stop dch-connection-check
```

## S3 evidence and limits

No live S3 endpoint was tested. The SDK contracts establish the paired operations: a configured client can paginate `ListObjectsV2` and perform `GetObject`. Listing and reading have separate permissions. Supported credential providers can refresh temporary credentials; exporting a temporary key tuple alone does not transfer that refresh behavior. [Listing](https://docs.aws.amazon.com/boto3/latest/reference/services/s3/paginator/ListObjectsV2.html), [reads](https://docs.aws.amazon.com/boto3/latest/reference/services/s3/client/get_object.html), [credential providers](https://docs.aws.amazon.com/boto3/latest/guide/credentials.html).

## Conclusion boundary

The PostgreSQL test verifies source behavior under one configured identity. It does not validate an implemented DCH registry, notebook delivery, OpenShift integration, other database drivers, or production authentication. The S3 conclusion remains documentation-based. The remaining architectural question is how DCH resolves and delivers a registration to each consumer, rather than whether discovery inherently needs a second connection definition.
