# Verification of Opus isolation and adapter findings

Checked **2026-09-15** against primary documentation (OpenShell pages labelled v0.0.116). No release is pinned and no deployment was tested. This supplements the existing OpenShell evidence; recommendations below are proposed RHOAI requirements, not upstream guarantees.

## Findings and recommended disposition

**1. Credential backend — clarify, not an architectural contradiction.** OpenShell permits one external credential driver per gateway. Kubernetes Secrets first and Vault as a later alternative satisfies that limit. A Red Hat integration/provider can own approved customer-secret references and synchronization while reusing upstream storage and refresh mechanisms. Declare this as product integration work; integration-first never meant writing no integration code. Simultaneous backends would require explicit additional design. [Gateway configuration](https://docs.nvidia.com/openshell/reference/gateway-config).

**2. Adapter authentication — accept the gap, qualify the remedy.** Authenticate requests cryptographically and authorize the verified identity against a server-side source binding. An unverified username header is inadequate; a signed token carried in a header is not that anti-pattern. OpenShell documents SPIFFE JWT-SVID client assertions to a token issuer, which then issues an upstream token. It does not establish automatic generic adapter mTLS. Use an audience-bound access token with verified issuer/signature/expiry/subject, or a separately validated workload-mTLS/JWT-SVID integration. JWT-SVID availability requires a Workload API. Resolve account, role, endpoint, and secret reference server-side; reject caller overrides. Recheck binding validity on every operation. [Providers v2](https://docs.nvidia.com/openshell/sandboxes/providers-v2).

**3. Adapter isolation — accept, without assuming one diagram box is one global instance.** Recommend instances scoped to a tenant/security domain and source protocol, shared by approved agents inside that boundary. Give each instance only necessary credential access; segregate connection pools by binding/account/role. Do not accept arbitrary DSNs or credential paths. Default-deny network policies limit reachability but do not authenticate the request; labels require administrator-controlled mutation. In-memory caches are preferable, but an absolute ban on protected credential files is not established by these sources and can conflict with certificate/file-based clients. The requirement is no agent-accessible or unnecessarily persistent credential material. [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

**4. Pod isolation — accept the missing proof; reject the proposed manifest prescription.** OpenShell's documented sidecar uses a root network-init container. Its default network sidecar needs SYS_PTRACE/DAC_READ_SEARCH for binary-aware policy and shared process visibility. Relaxed mode drops those capabilities and binary matching; the documentation still describes shared process namespaces. Thus mandatory `shareProcessNamespace: false` and a universal ptrace ban contradict the documented default, rather than verify it. Sidecars are supported by Kubernetes, but compatible OpenShell security settings on OpenShift remain a validation requirement. [Compute drivers](https://docs.nvidia.com/openshell/reference/sandbox-compute-drivers).

SCC admission validates the **pod** against an SCC, including its container settings. Do not say the agent uses restricted-v2 while another container in the same pod uses privileged SCC. Specify restrictive agent-container settings under the minimum sufficient pod SCC and trusted admission that prevents users broadening them. Upstream OpenShift installation remains experimental. [Red Hat SCC documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/authentication_and_authorization/managing-pod-security-policies), [OpenShell OpenShift](https://docs.nvidia.com/openshell/kubernetes/openshift).

Test access from the actual agent identity to peer `/proc` memory/environment/filesystem, provider/control sockets, mounted material, and Kubernetes API Secrets. Shared PID visibility does not automatically grant memory access, but expands the surfaces that need proof. Include distinct identities, dropped agent capabilities, child seccomp/LSM behavior, no host namespace access, and least-privilege service accounts in that proof. [Kubernetes process sharing](https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/).

Externalizing source credentials is a possible redesign if isolation fails, not an automatic supported fallback: the sandbox still needs proven containment and protected workload authority to the adapter. Stop production qualification until the chosen topology meets the boundary.

**5. Egress — accept concrete containment, qualify blanket bans.** Deny opaque TLS/raw-tunnel modes on enterprise routes requiring HTTP credential injection or operation policy. Opaque tunneling is not inherently unmediated at the network layer, but lacks the required HTTP inspection. Enforce approved DNS resolution, destination validation, and network egress restrictions in addition to proxy policy. Standard NetworkPolicy works at pod/network level, cannot separate same-pod agent and sidecar traffic, and is not hostname/TLS authorization. Block agent access to credential/control endpoints while preserving authenticated supervisor callbacks. Fixed public-IP pinning is not a universal design for dynamic SaaS endpoints. [Providers](https://docs.nvidia.com/openshell/sandboxes/manage-providers), [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

## Dated cached excerpts

Short excerpts only; links above preserve provenance. These do not replace release-specific manifests or tests.

| Primary source | Exact excerpt cached 2026-09-15 |
|---|---|
| Gateway configuration | “OpenShell supports at most one enabled credential driver at a time.” |
| Providers v2 | “Token grants require the sandbox supervisor to have access to a SPIFFE Workload API socket.” |
| Compute drivers | “sidecar pods set `shareProcessNamespace: true`” |
| Red Hat SCC | “A pod must validate every field against the SCC.” |
| OpenShell OpenShift | “The OpenShift install path is experimental.” |
| Kubernetes process sharing | “These are protected only by regular Unix permissions.” |
| NetworkPolicy | “Anything TLS related (use a service mesh or ingress controller for this).” |

## High-level wording to retain

Use a validated OpenShell/OpenShift topology that keeps source credentials inaccessible to the agent. Authenticate and authorize independently at the adapter, limit adapter scope by tenant and protocol, and enforce source permissions at the data system. Treat topology validation and negative-access tests as product acceptance gates; do not promise particular SCC or PID settings before pinning and testing a release.
