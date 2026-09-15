# Agent Enterprise Data Access — Conversation Context

**Captured:** 2026-09-14; consolidated 2026-09-15
**Purpose:** A resume record for later sessions: agreed requirements, decisions, verified facts, corrections, and open work. This records the conversation. It does not claim the integrations already exist.

## 1. Current state (start here)

- **Current documents:**
  - [agent-data-access-board.md](agent-data-access-board.md): the architecture-board summary, about 2 pages.
  - [agent-data-access-engineering-design.md](agent-data-access-engineering-design.md): the engineering detail.
- **Deleted drafts.** On 2026-09-15 Ramesh deleted the original `agent-data-access-architecture.md` and `agent-data-access-architecture-v2.md` at his request, without a git snapshot. Their content is superseded by the two documents above. The context addendum was also deleted; its Q&A and decisions are folded into §4 of this file.
- **Other editors.** Documents may also be edited by another agent ("Astra"). Before building on a document, re-read it and reverify any upstream claims.
- **Next likely steps:**
  - Share the board document.
  - Resolve the open items in §7.
  - Pin an OpenShell release.
  - Plan the proof of concept.

## 2. Objective and working style

- **Objective.** Define an RHOAI **product** architecture (not a single customer engagement) for sandboxed agents accessing Snowflake, BigQuery, Redshift, HDFS, S3, and PostgreSQL. Agents run in NVIDIA OpenShell on OpenShift, under any supported harness (OpenClaw, Codex, Claude Code, others). The central problem is identity propagation and source restrictions; "use MCP" is insufficient.
- **Working style:**
  - Architecture level, concise, diagram-led.
  - Keep verified facts separate from proposals.
  - Integration first: don't build what customers already run.
  - Ask a clarifying question only when the answer changes the design.
  - Base decisions on documented facts and constraints, not assumptions.
- **Audience split.**
  - The board document carries principles, one diagram, decisions, and risks.
  - The engineering document carries mechanisms, contracts, and qualification.
  - Detail leaking into the board document is a known risk.
- **Solutions must fit OpenShell norms:**
  - Use its supported extension points.
  - All configuration and stored credentials flow gateway → supervisor.
  - No forks.
  - No invented protocols the supervisor would need to speak.
- **Local records.** Save research and decisions locally so sessions resume without repeating discovery.

## 3. Agreed requirements

| Topic | Agreed position |
|---|---|
| Execution | Autonomous agents, triggered by a person or an event |
| Identity scope | One defined user or approved workload identity per **agent process**, not per run (Ramesh corrected the per-run framing) |
| Delegated authority | Never broader than the represented user; extra restrictions allowed |
| Autonomous authority | Explicitly approved workload permissions; an event does not identify a human |
| Source accounts | One process may map to different accounts in different sources |
| Legacy sources | Username/password supported; represented-user access uses that user's own mapped credentials, never a shared team account |
| Credential boundary | Credentials inaccessible to the agent; trusted OpenShell components may hold them in-pod |
| Data location | Process at the source; no dataset downloads into the sandbox; return bounded authorized results |
| Operations | Reads and writes; no mandatory per-write human approval |
| Deployment | OpenShift first; **air-gapped must work**; edge deferred |
| Tenancy | Single principal per sandbox initially; multi-user sandboxes deferred |
| Authorization | Sources enforce data permissions; platform only narrows; do not replicate customer policy |
| External sources | Outside the perimeter, the customer defines access permissions, not Red Hat |
| Disconnected sources | Disconnected customers may still reach sources through private connectivity (VPC peering, private endpoints) or on-premises systems; the customer defines reachability and permissions |
| Token services | STS-style brokers issuing short-lived credentials should be supported (asked 2026-09-15) |

## 4. Decisions made (2026-09-15)

| Decision | Position |
|---|---|
| Red Hat components | Acceptable as a **Red Hat-specific OpenShell provider/extension**: gateway interceptor (governance), remote credential driver, vended provider profiles, per-protocol adapters |
| Topology | OpenShell **sidecar** topology under a **custom least-privilege SCC** (not `privileged`); must pass isolation qualification |
| Credential backends | **One Red Hat remote credential driver**. Kubernetes Secrets first; multiple backends behind it later. "Vault" means external secret managers such as HashiCorp Vault, not one vendor |
| Supported IdPs | Depends on the customer environment. The product ships an IdP qualification test; federated represented-user mode only where it passes |
| Delegation beyond session | Support it if useful: bounded by token lifetime by default, with an optional approved refresher and an absolute deadline |
| Adapter tenancy | Recommended (not formally confirmed): one adapter per source protocol per tenant/workspace, shared within the tenant |
| Binding approval | Admins approve (Ramesh: "admin?"). Platform Admin sets bounds; Workspace Admin approves workload and legacy mappings. User self-service needs a separate provisioning service |
| Documents | Board plus engineering split; old drafts deleted (option C) |

## 5. Verified OpenShell facts

**Sources.** Checked 2026-09-15 against `main@fd3fd9c` and release `v0.0.116`. Published NVIDIA doc URLs often return 404, so read the repository source (`docs/`, `rfc/`, `proto/`, `deploy/helm/`) instead. Details are in [openshell-extension-evidence.md](research/openshell-extension-evidence.md) and [openshell-main-verification.md](research/openshell-main-verification.md).

**Release and OpenShift maturity**
- **Pre-0.1.0.** The stable-release policy (RFC 0014) is still in review.
- **OpenShift install is experimental.** The documented path uses the `privileged` SCC.

**Topology**
- **Sidecar mode:** the agent container runs non-root with no capabilities. The init container is root with `NET_ADMIN`/`NET_RAW`/`CHOWN`/`FOWNER`. The network sidecar runs as UID 0 with `SYS_PTRACE`/`DAC_READ_SEARCH` and `shareProcessNamespace: true`, needed for binary-aware policy.
- **Kata** is validated upstream for sidecar mode; gVisor is not supported.
- **Split pods:** PR #3144 merged into a **feature branch**, not `main` or a release. It is not available.

**Extension points**
- **Gateway interceptors** (RFC 0010, accepted; in `v0.0.116`):
  - Govern allowlisted write RPCs: `CreateSandbox`, `AttachSandboxProvider`, provider, profile, refresh, and rotation writes, and `UpdateConfig`.
  - Can vend profiles.
  - Cannot see secret fields.
  - `post_commit` hooks must be `fail_open`.
  - Registration changes require a gateway restart.
  - Cannot grant rights the gateway denies.
- **Supervisor middleware** (RFC 0009): request-side only. Responses are never inspected.
- **Credential drivers:** only one enabled per gateway. Built-in drivers are `kubernetes-secrets` and `vault` (HashiCorp KV). Remote gRPC drivers over a Unix socket are supported. There is no migration between drivers. User-authored references to existing Secrets are deprecated.

**Workspaces**
- **Isolation boundary** for providers, profiles, and policy.
- **Workspace Users cannot create providers,** but **can attach any provider in their workspace.** An interceptor check on attachment, including providers attached at sandbox creation, is mandatory.

**Tokens**
- **`token_grant`** (`client_credentials` or `token_exchange`) presents a SPIFFE JWT-SVID to the **configured authorization server**, which issues the token. OpenShell does not issue it.
- **User subject tokens** are stored without a refresh token, so exchange fails after expiry.
- **STS support:** `aws_sts_assume_role` (gateway mints IAM session credentials; uses ambient credentials or stored long-lived keys), OAuth token grants, and other gateway-minted tokens are documented. **No SAML** support and **no `AssumeRoleWithWebIdentity`** found in the repo (2026-09-15). AssumeRole is per provider, so AWS sees the role, not the sandbox or user.
- **SPIFFE** is required only for token grants. Zero Trust Workload Identity Manager (SPIRE) is GA on OpenShift.

**Native protocols**
- **`protocol: tcp` is rejected on Kubernetes,** because transparent capture is Docker/Podman only.
- **Explicit-proxy opaque passthrough still exists** for endpoints with no `protocol`. Credentialed endpoints need `allow_uninspected_credentials` to use it.
- **Consequence:** native credential hiding needs an adapter, and policy must forbid opaque bypass.
- **`protocol: sql` is audit-only.**

**Inference**
- **`inference.local` is removed on `main`** (still present in `v0.0.116`). Model endpoints are ordinary provider profiles.

**Credential lifecycle**
- **Rotation and detach** take effect at the next placeholder resolution.
- **Policy reload** closes connections pinned to the old generation.

**Air-gap**
- **Image mirroring** is documented for the agent-sandbox controller, gateway, sandbox, and supervisor images.

## 6. Corrections learned (do not repeat)

1. **Pod hardening.** Do not require `shareProcessNamespace: false` or forbid `SYS_PTRACE`; either breaks sidecar binary-aware mode. Require instead: distinct non-root agent UID, no capabilities, no other root containers.
2. **SCC scope.** SCCs apply to the whole pod, not per container.
3. **Split-pod status.** "Merged" does not mean on `main`. Check a PR's base branch.
4. **Native traffic.** The Kubernetes TCP rejection is not a blanket native-traffic ban.
5. **Token issuer.** Adapter tokens come from the authorization server, not from OpenShell.
6. **Credential drivers.** One driver per gateway is not a contradiction with "Secrets first, Vault later".
7. **No invented mechanisms.** Do not invent leases or response-based job recording in the proxy. The 5-minute revocation figure is a qualification target measured against upstream behavior.
8. **SQL.** Parsing may aid validation but is never the authorization boundary. Do not state it as a blanket ban.
9. **Expiry handling.** When one source's delegation expires, access to that source stops; the agent is not forcibly terminated.
10. **Network policy.** Fixed-IP pinning is not a universal SaaS control, and NetworkPolicy cannot separate same-pod containers.
11. **Federation blockers.** RHOAI's disabled `token-auth-aws/azure/gcp` flags do not prove federation is blocked.
12. **Mermaid.** Semicolons inside sequence-diagram notes break parsing. Validate diagrams with `npx @mermaid-js/mermaid-cli`.

## 7. Open items

1. Binding label/config schema; self-service provisioning; derivation from RHOAI connection types.
2. Red Hat credential driver: per-provider backend selection, high availability, reference authorization, backend isolation.
3. Custom SCC definition; pinned OpenShell and OpenShift versions; isolation qualification tests.
4. IdP qualification test and initial supported list (RFC 8693, `jwt-spiffe` assertions, delegation and actor claims).
5. Measured revocation bound, including cached tokens, persistent sessions, and gateway partitions; failure-mode test plan.
6. Remote-job correlation on the direct HTTP path (source-supported request correlation).
7. Restart and re-admission: how authority is revalidated when a sandbox restarts without `CreateSandbox`.
8. Proof of concept: Snowflake SQL API in workload mode, plus PostgreSQL through an adapter in represented-user mode. Covers cross-user attach denial, rotation, revocation, job cleanup, and audit.
9. Board confirmation of adapter tenancy and the approval role split.
10. Future: multi-user sandboxes, identity switching, edge agents.

## 8. Strategic context

- **Customer investments first.** RHOAI integrates what the customer already runs. New catalogs, ingestion, gateways, or table layers need demonstrated gaps. See [data-strategy-discussion-questions.md](data-strategy-discussion-questions.md) and [data-strategy-feedback.md](data-strategy-feedback.md).
- **Alignment applied to this design:**
  - One connection definition with two delivery modes: mounted credentials for Spark, Ray, KFP, and workbenches; provider profiles for agents.
  - OpenShell is the HTTP credential broker; adapters only for native protocols; MCP optional.
  - No additional agent-path policy engine.
  - The customer catalog is a bound source.
  - Audit by correlation, not OpenLineage.
- **Connection RBAC.** OpenShift RBAC over credential-backed connections was accepted. It does not change source permissions. Catalog scanning credentials are not reused for execution.

## 9. Workspace and publication constraints

- `RHAI-data-strategy-proposal.md` must stay out of git.
- Earlier feedback documents are committed and pushed to the private `rareddy/data-strategy` repository.
- The agent-access documents and research are **untracked**. No commit has been requested.
- Original proposal and feedback documents stay unchanged.

## 10. File map and reading order

1. [Board architecture](agent-data-access-board.md)
2. [Engineering design](agent-data-access-engineering-design.md)
3. [Follow-up review](research/openshell-followup-review.md) and [main/release verification](research/openshell-main-verification.md)
4. [OpenShell extension evidence](research/openshell-extension-evidence.md), then the earlier [OpenShell evidence](research/agent-data-access-evidence.md)
5. [Critique assessment](research/opus-critique-assessment.md) and [isolation verification](research/opus-isolation-verification.md). These review now-deleted drafts but hold the evidence.
6. [Enterprise source-access evidence](research/enterprise-source-access-evidence.md) and [integration evidence](research-integration-evidence.md)