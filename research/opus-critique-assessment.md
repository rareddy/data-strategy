# Assessment of the Opus Architecture Critique

**Date:** 2026-09-15. Reviewed against current primary documentation and Ramesh's answers. No deployment was tested; live OpenShell documentation identifies itself as v0.0.116, which is not a pinned product release.

**Conclusion:** The critique correctly identifies missing ownership, security mechanisms, and lifecycle rules. Several prescribed fixes are too absolute or conflict with documented platform behavior. The architecture now distinguishes proposed RHOAI integration from upstream capabilities and turns isolation claims into qualification requirements.

## Disposition of findings

| Finding | Assessment and resulting change |
|---|---|
| 1. Credential-driver contradiction | **Clarify; reject the forced either/or.** One backend per gateway does not prohibit Secrets first and Vault later, or Red Hat integration around upstream providers. Added component ownership and explicit reference/lifecycle build items. Building necessary integration code does not contradict avoiding a universal data stack. |
| 2. Adapter identity | **Accept missing mechanism; qualify remedy.** Require cryptographic caller verification and independent binding authorization. An audience-bound access token in a header is valid authentication; an unsigned username is not. SPIFFE-backed OAuth is an upstream candidate. Direct adapter JWT-SVID/mTLS support is not automatic. |
| 3. Adapter isolation | **Accept blast-radius concern.** One logical box did not imply one global deployment. Proposed default: tenant/security-domain plus source-protocol instances, shared by authorized processes. Scope secrets, pools, and networks; prohibit free-form DSNs. In-memory-only credentials are a preference, not a universal prerequisite for native TLS libraries. |
| 4. Pod isolation | **Accept need for proof; reject the specific SCC/PID prescription.** SCC selection applies to a pod. Current OpenShell binary-aware sidecar uses shared PID visibility and trusted-sidecar capabilities. Added negative tests, release pinning, effective-container requirements, and a qualification/fallback decision. Sidecars being valid Kubernetes does not prove these controls work together. |
| 5. Egress | **Accept mechanism requirement; qualify blanket assertions.** Deny opaque modes for paths requiring inspection, use controlled DNS/TLS/network policy, and distinguish administrative API access from necessary authenticated supervisor callbacks. NetworkPolicy cannot distinguish same-pod containers or authenticate labels. Fixed SaaS IPs are not a universal answer. |
| 6. Inference | **Accept.** Added the model destination and managed gateway inference path. Require a disconnected harness/model/dependency profile. Returned data may reach inference; it is not inevitable that every returned row does. A harness name alone does not prove its model endpoint is always vendor-hosted. |
| 7. SQL parsing | **Accept the security principle, not a blanket parsing ban.** Source grants and constrained operations enforce authority. Statement parsing may support validation or UX but must never be the sole authorization boundary. Read/write intent must resolve to real grants, not a label. |
| 8. Remote jobs | **Accept.** Persist ownership and binding version, reauthorize follow-ups, block results after revocation, attempt cancellation, and reconcile uncertain writes. Cancellation is not rollback. A job ID is important but not the only correlation key; record process, principal, and request metadata too. |
| 9. Delegation lifetime | **Accept.** Beyond-session access requires an explicit renewable grant with an absolute deadline. Otherwise source access stops pending reauthorization. Terminating the entire agent process is not required merely because one source's authority expires. No fallback to broader credentials. |
| 10. Other boundaries | **Accept.** Separate administrator configuration from invocation; define restart/resume identity; bind catalog access; add bounded failure behavior; state adapter admission criteria. No global gateway is introduced merely to support a native protocol. |

## Recommendations using Ramesh's answers

- **Product scope:** RHOAI, not a one-off engagement. Define product contracts and a tested source capability matrix.
- **Credential integration:** Red Hat-specific provider integration is acceptable. Start with Kubernetes Secrets. Add Vault as a supported alternative later; no simultaneous-driver promise.
- **Adapter tenancy:** share controllers; scope adapter deployments by tenant/security domain and source protocol. A controller can scaffold them without one adapter per agent. Cross-tenant sharing requires later qualification.
- **Delegation:** permit approved renewable grants where useful. Do not assume useful agents should inherit indefinite offline access.
- **Disconnected mode:** mandatory. Local inference and required dependencies must work without external calls. Customer-authorized outside access is a connected profile, not a physically air-gapped one.
- **Unpinned release:** OpenShift can run sidecars, but product qualification must validate the specific OpenShell topology, capabilities, and SCC. No claim of production readiness follows from Kubernetes compatibility.

The five-minute authorization lease in the revision is an explicit **proposed product ceiling**, not an upstream guarantee or a user-approved number. It makes outage/revocation exposure concrete for review. The final value and enforcement implementation must be approved before the proof of concept relies on that guarantee.

## Primary evidence and cached rationale

Findings 1–5 and their exact source excerpts are in [isolation verification](opus-isolation-verification.md). The following findings were checked separately:

### Inference routing

OpenShell distinguishes direct external inference, governed by network policy, from `inference.local`, which routes through the gateway to its configured model provider. It documents compatible model interfaces and local-backend examples. This supports drawing a managed inference route, but does not establish compatibility of every named harness with every disconnected backend. Its managed route is gateway-scoped, so different tenant model-boundary requirements may require separate gateway deployments. [NVIDIA inference routing](https://docs.nvidia.com/openshell/sandboxes/inference-routing).

Cached excerpt, 2026-09-15:

> Every sandbox on that gateway sees the same `inference.local` backend.

### Delegation and token refresh

OpenShell Providers v2 uses a sandbox JWT-SVID as an assertion to a token service. The documented token-exchange path can retain a user subject token at the gateway. The CLI's OIDC import does not store its OIDC refresh token in the provider, and expiry prevents further intermediate exchange until the subject credential is updated. Thus useful beyond-login delegation requires an explicit supported integration, not an assumption that token exchange provides indefinite renewal. [Providers v2](https://docs.nvidia.com/openshell/sandboxes/providers-v2).

This finding is additional interpretation of the provider evidence already cached in [OpenShell research](agent-data-access-evidence.md); it does not change the agreed process-level identity scope.

### Remote operations

Redshift Data API is asynchronous and exposes statement execution, status/results, and cancellation. Snowflake supports an explicit asynchronous request option and returns a handle when a request continues executing; it is too broad to characterize every Snowflake request as necessarily asynchronous. Both need ownership and authorization continuity for delayed operations. [Redshift Data API](https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html), [Snowflake statement submission](https://docs.snowflake.com/en/developer-guide/sql-api/submitting-requests).

A platform cleanup authority is a proposed narrowly scoped operational role. The sources do not guarantee that all canceled jobs stop immediately or that cancellation reverses writes. Product testing must establish each connector's behavior.

## Scope of verification

Verified documentation and revised architecture, not manifests, source-level security proof, or runtime behavior. Architectural requirements are labeled as proposed. Pending qualification includes credential confidentiality, network bypass, API authorization, revoked-job handling, disconnected dependencies, and fault behavior. Existing evidence snapshots remain dated so later upstream changes can be distinguished from this review.
