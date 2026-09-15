# Cached NVIDIA OpenShell source excerpts

Retrieved 2026-09-14 with the web tool. Pages identified themselves as Latest v0.0.116. These short verbatim excerpts preserve the key source language; they are **not full page snapshots**. Context and design interpretation are in [the research note](../agent-data-access-evidence.md).

## Runtime boundary

[How OpenShell Works](https://docs.nvidia.com/openshell/about/how-it-works), Core Components / Supervisor Protection Layers:

> The supervisor runs inside every sandbox workload and is the local security boundary.

## Protocol limitation

[Providers](https://docs.nvidia.com/openshell/sandboxes/manage-providers), How Credential Injection Works:

> Raw `tls: skip` and non-HTTP tunnels remain opaque and do not support credential rewrite.

## Scope discovery limitation

[Providers v2](https://docs.nvidia.com/openshell/sandboxes/providers-v2), Roadmap:

> OpenShell does not yet inspect upstream provider responses to discover credential scopes.

## Credential backend semantics

[Gateway Configuration File](https://docs.nvidia.com/openshell/reference/gateway-config), Credential Drivers:

> OpenShell supports at most one enabled credential driver at a time.

## Sidecar topology

[Sandbox Compute Drivers](https://docs.nvidia.com/openshell/reference/sandbox-compute-drivers), Kubernetes:

> In `sidecar` topology, the agent container runs as the resolved sandbox UID/GID with no added Linux capabilities.

## OpenShift maturity

[OpenShift](https://docs.nvidia.com/openshell/kubernetes/openshift), introduction:

> The OpenShift install path is experimental.

The same page includes evaluation instructions and a later TLS/cert-manager/Route configuration section. Preserve that distinction when interpreting the introduction.
