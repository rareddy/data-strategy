# Follow-up review of the board and engineering architecture

Checked 2026-09-15. This is a source review, not OpenShift runtime qualification. Current reading order: [board](../agent-data-access-board.md), then [engineering](../agent-data-access-engineering-design.md). Earlier architecture drafts remain unchanged.

## Assessment

Accept the board/engineering split and the main corrections: use provider-backed inference endpoints, gateway-mediated configuration, initial and subsequent provider ownership checks, adapters for native credential handling, and a measured revocation target rather than an invented lease protocol. Request hooks do not provide response-based job tracking. Existing customer Secret references need integration work.

The user's later answer, “several backends, start with Secrets,” resolves the backend direction: one Red Hat driver, Kubernetes Secrets initially, multiple backing stores later. Simultaneous native OpenShell drivers are not required. This is proposed product scope, not an existing multiplexing capability.

## Evidence-based qualifications incorporated

1. **Split-pod availability.** PR #3144 merged into a feature branch, not the checked main or release. Treat it as upstream development, not a current deployment option.
2. **Native transport.** Kubernetes rejects transparent TCP capture, but explicit-proxy opaque passthrough remains. Native credential rewriting still needs an adapter, and bypass denial still needs policy.
3. **Token issuer.** Dynamic access tokens come from the configured authorization server through OpenShell. The adapter verifies that issuer, audience, and the qualified identity claims; OpenShell does not universally mint the source access token.

Immutable references and cached API findings for these points, inference removal, and Secret-reference deprecation are in [main/release verification](openshell-main-verification.md).

4. **Interceptor scope and failure mode.** Interceptors govern allowlisted control-plane mutations, not every request. Modifying/validating checks can fail closed; post-commit observation must fail open. They cannot override gateway authorization and cannot inspect secret values. Consequently, protected metadata alone cannot establish who owns an imported credential. Initial provider attachments need checks as well as later attachments. [Official interceptor contract](https://docs.nvidia.com/openshell/extensibility/gateway-interceptors), [pinned method allowlist](https://github.com/NVIDIA/OpenShell/blob/fd3fd9cf7476c6a618ad9b5ce143936e3ebb245e/crates/openshell-gateway-interceptors/src/routes.rs).
5. **Runtime boundary.** Supervisor middleware is a separate request extension. It does not expose source responses. Direct-path job tracking needs source-supported correlation; principal and time alone cannot reliably distinguish concurrent processes. Gateway-mediated configuration does not mean the supervisor never calls external middleware or token services. [Official supervisor middleware contract](https://docs.nvidia.com/openshell/extensibility/supervisor-middleware).
6. **Self-service provisioning.** Workspace Users cannot create providers in the documented role matrix. Optional self-service therefore requires authorized provisioning; a permissive interceptor cannot grant that missing right. [Official workspace roles](https://docs.nvidia.com/openshell/sandboxes/manage-workspaces).
7. **Federation claims.** The strategy's disabled cloud-token feature flags do not prove all RHOAI/OpenShell federation is disabled. Qualify the intended OpenShell, IdP, and source path. [Gateway authentication](https://docs.nvidia.com/openshell/reference/gateway-auth); local proposal's `token-auth-aws`, `token-auth-azure`, and `token-auth-gcp` discussion.

## Requirements retained without claiming upstream implementation

Provider instances as binding records, adapter lookup permissions, process-incarnation revalidation, bounded runtime revocation, and supported issuer claims remain product design and qualification work. A persistent sandbox ID is not automatically a new process incarnation. A live supervisor disconnected from the gateway is not equivalent to a failed supervisor. These distinctions are now explicit in the engineering design.

No blanket SQL-parser ban, forced whole-agent termination on source expiry, static SaaS IP pinning, or per-container SCC claim was reintroduced. The tenant-scoped adapter remains the proposed starting point; it is not a proven upstream tenancy guarantee.
