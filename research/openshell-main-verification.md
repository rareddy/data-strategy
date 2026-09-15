# OpenShell main/release verification of the second Opus review

Checked 2026-09-15 using the upstream GitHub API and repository source. No runtime test was performed. API responses are summarized below because the web search cache returned an older PR state.

## Immutable references

- Current `main`: `fd3fd9cf7476c6a618ad9b5ce143936e3ebb245e`, commit timestamp `2026-09-15T13:46:38Z`.
- `v0.0.116`: `d1155aa70042d3e2ee49dbfa15346b108b7c1d92`. The GitHub latest-release URL still resolves to this release.
- Local read-only source inspected: the existing OpenShell checkout at that exact main SHA.

## Verified findings and precise corrections

### Inference: accept the correction

The release documents both external inference endpoints and the gateway-routed virtual host. Main replaces the virtual-host path with ordinary provider-backed model endpoints, and documents DNS failure for old clients. The architecture should show proxy-to-approved-model-provider routing, without depending on the removed gateway inference router.

Sources: [release inference documentation](https://github.com/NVIDIA/OpenShell/blob/d1155aa70042d3e2ee49dbfa15346b108b7c1d92/docs/sandboxes/inference-routing.mdx), [main inference documentation](https://github.com/NVIDIA/OpenShell/blob/fd3fd9cf7476c6a618ad9b5ce143936e3ebb245e/docs/sandboxes/inference-routing.mdx#L235-L271).

### Split pods: merged into a feature branch, not main

The live API reports PR #3144 merged on `2026-09-14T20:10:14Z`, merge SHA `dc47f155324e6ae42b02392b13bd12aa62ea7b2b`. Its base is `codex/1737-rfc12-supervisor-primitives`, **not `main`**. The API comparison `main...dc47f155324e6ae42b02392b13bd12aa62ea7b2b` reports `diverged`, 115 commits ahead and 7 behind, with merge base `5b57f0d1549677c7547862d26ff9491285ea0fbc`.

Therefore the review correctly identifies upstream split-pod development, but “merged” must not imply availability in main or the current release. Treat it as feature-branch work pending integration and qualification. Main's Kubernetes driver inspection did not find the new proxy-pod topology.

Sources: [PR #3144](https://github.com/NVIDIA/OpenShell/pull/3144), [merge commit](https://github.com/NVIDIA/OpenShell/commit/dc47f155324e6ae42b02392b13bd12aa62ea7b2b), [immutable comparison](https://github.com/NVIDIA/OpenShell/compare/fd3fd9cf7476c6a618ad9b5ce143936e3ebb245e...dc47f155324e6ae42b02392b13bd12aa62ea7b2b).

### Native TCP: transparent capture rejection is not a blanket tunnel ban

Main documentation confirms that only Docker/Podman support the transparent DNS/capture capability needed for `protocol: tcp`; other drivers reject that policy. However, the same documentation explicitly retains **explicit-proxy L4 passthrough for endpoints without a protocol field**. It also describes an explicit uninspected-credentials override. Consequently, “PostgreSQL cannot go through the proxy at all” and “raw native bypass is blocked by default, so no extra design work is needed” are too broad.

The architectural conclusion still holds under our credential-hiding requirement: native database authentication needs an approved HTTP-facing adapter unless an existing suitable HTTP service handles it. Opaque tunneling cannot inject native database credentials. Policy must prohibit unapproved opaque paths rather than treating the transparent-capture limitation as the security control.

Source: [policy documentation, native TCP section and L4 distinctions](https://github.com/NVIDIA/OpenShell/blob/fd3fd9cf7476c6a618ad9b5ce143936e3ebb245e/docs/sandboxes/policies.mdx#L136-L162), [explicit-proxy passthrough](https://github.com/NVIDIA/OpenShell/blob/fd3fd9cf7476c6a618ad9b5ce143936e3ebb245e/docs/sandboxes/policies.mdx#L670).

### Existing customer Secrets: accept, with implementation choice preserved

The Helm values mark `allowReferenceNamespace` deprecated and state that user-authored namespace references are no longer supported. Reusing existing customer references therefore requires a Red Hat integration, for example a custom remote driver or a controller synchronizing through supported provider APIs. It is not the built-in driver's documented reference behavior. Avoid implying a custom driver is the only conceivable integration implementation.

Source: [pinned Helm values](https://github.com/NVIDIA/OpenShell/blob/fd3fd9cf7476c6a618ad9b5ce143936e3ebb245e/deploy/helm/openshell/values.yaml#L338-L339).

### Adapter token issuer: distinguish the token service from OpenShell

The documented `token_grant` flow presents SPIFFE assertions to the configured OAuth `token_endpoint`. In client-credentials mode the supervisor obtains the token from that service. In exchange mode the gateway and supervisor perform successive exchanges at that service. Calling the adapter's resulting access token “OpenShell-issued” obscures which issuer the adapter must actually trust. Use “audience-bound token obtained through OpenShell from an approved authorization server.” Sandbox-to-gateway bootstrap tokens are a separate matter.

Source: [dynamic grants and token endpoint fields](https://github.com/NVIDIA/OpenShell/blob/fd3fd9cf7476c6a618ad9b5ce143936e3ebb245e/docs/providers/profiles.mdx#L500-L553).

## Scope

These conclusions support the board/engineering split and the revised integration direction. They do not establish that the combination has been tested on OpenShift. Release selection must precede capability promises, especially for topology and extension APIs.
