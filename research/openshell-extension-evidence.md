# OpenShell extension, topology, and tenancy evidence

**Checked:** 2026-09-15 against the NVIDIA/OpenShell repository, `main` at `fd3fd9c` (2026-09-15), and the latest release tag `v0.0.116` (2026-08-28). Docs were read from the repository source (`docs/`, `rfc/`, `proto/`, `deploy/helm/`), because several published doc URLs returned 404 during this session. These are documentation and design-record findings, not deployment tests.

This note supplements [agent-data-access-evidence.md](agent-data-access-evidence.md). Where they conflict, this note is newer; conflicts are listed in §9.

## 1. Release and maturity

- Latest release is `v0.0.116`. No `0.x` stable line exists yet.
- [RFC 0014](https://github.com/NVIDIA/OpenShell/tree/main/rfc/0014-release-stability) (state: **review**) proposes alpha exit at `0.1.0`: weekly stable releases, Stable vs Experimental API maturity, and maintenance of latest and N-1 minor lines.
- **Consequence for RHOAI:** a product dependency on OpenShell needs a Stable API contract and a supported release line. Neither exists today.

## 2. OpenShift and Kubernetes topology

**OpenShift install page** (`docs/kubernetes/openshift.mdx`), verbatim:

> The OpenShift install path is experimental. It currently requires running sandbox pods under the `privileged` SCC and installing the gateway with TLS disabled. Use only for evaluation on a private network.

The same page later documents end-to-end TLS with OIDC: Gateway API with BackendTLSPolicy on OpenShift 4.22+, or a passthrough Route with cert-manager.

**Topologies** (`docs/kubernetes/topology.mdx`, present at `v0.0.116`). Helm `supervisor.topology` defaults to `combined`.

| Topology | Agent container | Trusted component | Tradeoff |
|---|---|---|---|
| `combined` (default) | Runs the supervisor and adds `SYS_ADMIN`, `NET_ADMIN`, `SYS_PTRACE`, and `SYSLOG` | Same container | Full network, filesystem, and process enforcement |
| `sidecar` | `sandbox_uid:gid`, `allowPrivilegeEscalation: false`, drops `ALL` | Network sidecar: UID 0, drops `ALL`, adds `SYS_PTRACE` + `DAC_READ_SEARCH` (binary-aware default). A root init container adds `NET_ADMIN`, `NET_RAW`, `CHOWN`, and `FOWNER` for nftables. | Network/L7 enforcement is primary; the agent container does no privilege drop or supervisor mount isolation |

Verbatim facts about sidecar mode:

> Sidecar pods use `shareProcessNamespace: true` so the network sidecar can resolve workload process and binary identity through `/proc/<entrypoint-pid>`.

> The nftables fence exempts UID 0, so do not inject other root containers into these pods.

> Sidecar topology keeps gateway credentials in the network sidecar. The agent container does not mount the projected ServiceAccount token used for sandbox token bootstrap, does not mount the sandbox client TLS secret, and does not get gateway callback environment variables.

> Sidecar topology has been validated with Kata Containers. It does not currently support gVisor.

Binary-aware matching can be disabled (`processBinaryAwareNetworkPolicy=false`). The sidecar then runs non-root without the extra capabilities and loses `policy.binaries` matching.

**Split-pod isolation (not yet released).**
- [PR #3144](https://github.com/NVIDIA/OpenShell/pull/3144), merged 2026-09-14 into the feature branch `codex/1737-rfc12-supervisor-primitives`, **not `main`** (corrected 2026-09-15; see [main verification](openshell-main-verification.md)), "isolate workloads behind a dedicated supervisor", implements [RFC 0012](https://github.com/NVIDIA/OpenShell/tree/main/rfc/0012-isolation-backend) (state: **review**) for Kubernetes.
- It renders separate workload and supervisor Pods and does not share a process namespace. Namespace NetworkPolicies deny workload egress except through the supervisor.
- Its motivation ([issue #981](https://github.com/NVIDIA/OpenShell/issues/981)) names OpenShift SCC incompatibility and root supervisors sharing a pod with the agent.
- RFC 0012 non-goal: a delegated backend "does not guarantee Pod Security Standards compliance."
- It is not in `v0.0.116`, and the Helm values still expose only `combined` and `sidecar`.

**Air-gapped install** (`docs/kubernetes/setup.mdx`): documents mirroring the agent-sandbox controller, gateway, sandbox, and supervisor images to an internal registry.

## 3. Native protocols on Kubernetes

`docs/sandboxes/policies.mdx`:

> Docker and Podman sandboxes support policy DNS and transparent TCP capture. Other compute drivers reject policies containing `protocol: tcp` until they provide the required runtime capability.

> `protocol: sql` is not a practical incremental workflow today. OpenShell does not do full SQL parsing, and SQL enforcement is not meaningfully supported yet.

> Provider-credentialed endpoints reject L4-only and `tls: skip` modes by default.

The only override is explicit `allow_uninspected_credentials: true`.

**Consequence (corrected 2026-09-15):** Kubernetes rejects transparent `protocol: tcp` capture, but endpoints without `protocol` still allow explicit-proxy opaque TCP passthrough. Neither L4 shape can inject native database credentials, and credentialed endpoints need the `allow_uninspected_credentials` exception to use them. So credential-hidden native access needs an adapter or an existing HTTP service, and policy must explicitly prohibit unapproved opaque passthrough. [RFC 0005](https://github.com/NVIDIA/OpenShell/tree/main/rfc/0005-sandbox-proxy-egress-adapter) (state: review) plans native protocol processors later.

## 4. Extension points usable by a Red Hat distribution

### Gateway interceptors
Sources: [RFC 0010](https://github.com/NVIDIA/OpenShell/tree/main/rfc/0010-gateway-interceptors) (state: **accepted**) and `docs/extensibility/gateway-interceptors.mdx` (present at `v0.0.116`).

- **Service shape:** an external gRPC service with `modify_operation` (allow, deny, or JSON-patch), `validate`, and `post_commit` (observe only). It can also vend an authoritative provider-profile catalog through `SnapshotProviderProfiles`.
- **Interceptable RPCs:** `CreateSandbox`, `DeleteSandbox`, `AttachSandboxProvider`, `DetachSandboxProvider`, `CreateProvider`, `UpdateProvider`, `DeleteProvider`, `RotateProviderCredential`, `ConfigureProviderRefresh`, `DeleteProviderRefresh`, `ImportProviderProfiles`, `UpdateProviderProfiles`, `DeleteProviderProfile`, and `UpdateConfig`. Source: `crates/openshell-gateway-interceptors/src/routes.rs`.
- **Security-relevant limits,** verbatim:
  > Interceptors cannot receive or mutate protobuf fields marked secret.

  > Registration changes require a gateway restart.

  > Extension tokens and sandbox-to-gateway tokens are signed by the same key, separated by audience and `typ`. The extension credential path cannot yet be rotated or revoked independently of sandbox admission.
- **Failure behavior:** `fail_closed` rejects the operation. An unavailable interceptor at startup prevents the gateway from starting. `binding_policy = allowlist|exact` is recommended when the interceptor is part of a security boundary.
- **Precedent:** the upstream [governance-interceptor example](https://github.com/NVIDIA/OpenShell/tree/main/examples/governance-interceptor) vends signed profiles, applies a signed policy on `CreateSandbox`, and denies sandbox-authored policy proposals.

### Supervisor middleware
Sources: [RFC 0009](https://github.com/NVIDIA/OpenShell/tree/main/rfc/0009-supervisor-middleware) (state: **accepted**) and `docs/extensibility/supervisor-middleware.mdx`.

- An operator-run gRPC service is called by supervisors on the request path.
- V1 bindings are `HttpRequest/pre_credentials` and `WebSocketMessage/pre_credentials` only.
- It can allow, deny, or replace a request, add approved headers, and emit audit-safe findings. It never sees injected credentials.
- **Limit,** verbatim:
  > Binary messages, control frames, and upstream-to-client traffic remain uninspected.
- Request context carries `sandbox_id` (authoritative) and `workspace`/`sandbox_name` (display only).
- **Consequence:** response size and content cannot be bounded at the OpenShell proxy today. Result bounding must happen at the adapter or source.

### Remote credential drivers
Sources: `docs/reference/gateway-config.mdx` and [`proto/credential_driver.proto`](https://github.com/NVIDIA/OpenShell/blob/main/proto/credential_driver.proto) (present at `v0.0.116`).

- Built-in drivers are the encrypted database (default), `kubernetes-secrets`, and `vault`. A remote gRPC driver can plug in over a Unix socket (`transport = "uds"`).
- **Contract:** `StoreCredential`, `DeleteCredential`, `ResolveCredentials` (with `expires_at_ms`), and an optional `ListCredentials`. The gateway owns writes and handles.
- **Limit,** verbatim:
  > OpenShell supports at most one enabled credential driver at a time.
- The gateway does not migrate credentials when the driver changes.
- The Helm README says `allowReferenceNamespace` is deprecated: "Credential storage no longer supports user-authored namespace references."
- The `kubernetes-secrets` driver Role grants read/write on all Secrets in its namespace, so the docs recommend a dedicated namespace.
- Vault authenticates with `kubernetes` (the gateway ServiceAccount) or `token_file` (dev only).
- **Consequence:** upstream does not consume pre-existing customer Secrets or Vault paths in place. The gateway stores its own copy through the driver.

## 5. Identity, token grants, and SPIFFE

`docs/providers/profiles.mdx` and `docs/kubernetes/access-control.mdx`:

- **Dynamic `token_grant`,** resolved by the supervisor per matching HTTP endpoint and cached (`cache_ttl_seconds`):
  - `client_credentials`: the sandbox JWT-SVID is the OAuth2 client assertion (`jwt-spiffe`). The result represents the sandbox workload.
  - `token_exchange`: the gateway verifies the supervisor SVID, exchanges the stored **user subject token** with its own SVID, and the supervisor performs the final exchange. Upstream design ([issue #1987](https://github.com/NVIDIA/OpenShell/issues/1987), closed) targets a final token with user `sub` and sandbox `azp`.
- The subject token comes from `provider create/update --from-oidc-token`. Verbatim:
  > OpenShell does not store the OIDC refresh token in the provider. When the stored subject-token credential expires, the gateway rejects intermediate token exchange until the provider is updated with a fresh token.
- **Refresh strategies:** `static`, `external` (an outside process calls `provider update`), `oauth2_refresh_token`, `oauth2_client_credentials`, `google_service_account_jwt`, and `aws_sts_assume_role`. Token endpoints are profile-owned.
- **Rotation and detach:** "Credential rotation and detach still take effect immediately at placeholder resolution." A running process does not gain new environment variables. A policy hot-reload closes connections pinned to the previous generation.
- **Supervisor authentication:** supervisors authenticate to the gateway through projected ServiceAccount tokens and a gateway-minted sandbox JWT. SPIFFE is additionally required only for token grants (`server.providerTokenGrants.spiffe.enabled`).
- **OpenShift SPIFFE:** Red Hat [Zero Trust Workload Identity Manager](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/security_and_compliance/zero-trust-workload-identity-manager) (SPIRE-based) is GA, including [with standard OpenShift Container Platform entitlements](https://www.redhat.com/en/blog/zero-trust-workload-identity-manager-11-generally-available-red-hat-openshift).
- **Not verified:** whether the customer IdP (for example Red Hat build of Keycloak or Entra ID) accepts `jwt-spiffe` client assertions and the required RFC 8693 exchanges. Validate per supported IdP.

## 6. Tenancy

`docs/sandboxes/manage-workspaces.mdx` is present at `v0.0.116`.

- **Boundary,** verbatim:
  > An OpenShell workspace is an access and resource isolation boundary. Sandboxes, sandbox workload templates, providers, provider profiles, services, policies, and settings belong to a workspace and are not visible to members of other workspaces.
- **Roles:** Platform Admin, Workspace Admin (manages providers, profiles, and policy), and Workspace User (creates sandboxes and uses provider attachments in that workspace).
- **Credential-driver isolation:** requests carry `workspace` and `provider_id`.
- **Key gap for represented-user access:** within one workspace, any Workspace User may attach any provider in that workspace ([RFC 0011](https://github.com/NVIDIA/OpenShell/tree/main/rfc/0011-multi-player-design) table, line 130). Without an additional control, one member could attach a provider holding another member's delegated token.
- RFC 0011 is still **draft**. Machine identity through OIDC workload identity is described there as a future direction.

## 7. Inference

- `v0.0.116` documents `inference.local`: a gateway-wide privacy router with one provider and one model per gateway.
- On `main`, this was replaced by provider-backed inference. Verbatim:
  > Code that still calls `inference.local` fails DNS resolution because OpenShell no longer resolves or trusts that virtual host.
- Model access is now an ordinary provider profile and attachment with L7 rules, so self-hosted endpoints use a custom profile.
- **Consequence:** do not design on `inference.local`. Treat model endpoints as provider-profile destinations.

## 8. Audit

- Gateway interceptors log interceptor name, RPC, phase, decision, and annotations.
- Middleware findings carry `sandbox_id`.
- OpenShell exports OCSF events, including provider and settings changes (`CONFIG:` class 5019).
- No documented mechanism propagates sandbox identity to upstream sources except inside `token_exchange` or `client_credentials` token claims.

## 9. Corrections to earlier notes and review

1. **SCC.** The earlier note said "requires a privileged SCC for sandbox pods." That is still correct for the documented OpenShift path. However, sidecar topology's actual capability set means a narrower custom SCC is plausible, and split-pod work exists only on an upstream feature branch, not in `main` or a release. Both need validation on OpenShift.
2. **Pod hardening.** The 2026-09-14 review recommended `shareProcessNamespace: false` and no `SYS_PTRACE`. That contradicts OpenShell sidecar binary-aware mode. The property to require is: a non-root, capability-less agent UID distinct from the root sidecar, with no other root containers in the pod. Otherwise, disable binary-aware matching or use split-pod.
3. **Inference.** The earlier suggestion to use `inference.local` for air-gapped inference is superseded (§7).
4. **Credential drivers.** "Only one driver" is confirmed, but drivers are pluggable remotely. Multiple customer vaults need either a Red Hat remote driver or one gateway per backend.
5. **Documentation conflict.** `docs/kubernetes/access-control.mdx` still says provider and sandbox records are not owned by OIDC subjects and recommends separate gateways for isolation. `manage-workspaces.mdx` describes workspace isolation. Validate the actual behavior on the pinned release.
