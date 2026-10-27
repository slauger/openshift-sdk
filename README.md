# 🛠️ openshift-sdk

[![Build](https://github.com/slauger/openshift-sdk/actions/workflows/build.yml/badge.svg)](https://github.com/slauger/openshift-sdk/actions/workflows/build.yml)

All-in-one container image for OpenShift CI/CD pipelines. Based on Red Hat UBI 9, ships with everything you need to deploy and manage OpenShift clusters.

## 📦 Included Tools

| Tool | Description |
|------|-------------|
| `openshift-install` | OpenShift cluster installer |
| `oc` / `kubectl` | OpenShift and Kubernetes CLI |
| `ansible` | Automation engine with the collections pinned in `requirements.yml`, including `kubernetes.core`, `kubevirt.core` and `community.vmware` |
| `helm` | Kubernetes package manager |
| `helmfile` | Declarative Helm chart management |
| `vault` | HashiCorp Vault CLI |
| `govc` | VMware vSphere CLI |
| `yq` | YAML/JSON/XML processor |
| `oc-mirror` | Mirroring of releases and Operators for disconnected installs |
| `virtctl` | OpenShift Virtualization / KubeVirt CLI |
| `kubectl-mtv` | Migration Toolkit for Virtualization CLI (`oc mtv`) |
| `velero` / `kubectl-oadp` | Backup and restore via OADP (`oc oadp`) |
| `tkn` | OpenShift Pipelines (Tekton) CLI |
| `kn` | OpenShift Serverless (Knative) CLI |
| `argocd` | OpenShift GitOps (Argo CD) CLI |
| `roxctl` | Advanced Cluster Security CLI |
| `hcp` | Hosted Control Planes (HyperShift) CLI |
| `stern` | Multi-pod log tailing |
| `kubectx` / `kubens` | Fast context and namespace switching |

## 🚀 Quick Start

```bash
docker run -it quay.io/slauger/openshift-sdk:4.21.3
```

Or with Podman:

```bash
podman run -it quay.io/slauger/openshift-sdk:4.21.3
```

The image tag corresponds to the OpenShift release version.

Bash completion is preinstalled in `/etc/bash_completion.d/` for every tool that ships one, `oc` and `kubectl` included. It loads automatically in interactive shells.

## 🔄 Automated Builds

The CI pipeline automatically discovers the latest 3 supported OpenShift versions by querying the [Red Hat Product Lifecycle API](https://access.redhat.com/product-life-cycles/api/v1/products?name=OpenShift+Container+Platform) and the [Cincinnati graph API](https://api.openshift.com/api/upgrades_info/v1/graph). End-of-life versions are excluded automatically.

Builds run daily and on every push to `master`.

## 🔐 Supply Chain Security

Every pushed image is:

- **Signed** with [cosign](https://docs.sigstore.dev/cosign/) keyless signing (Sigstore OIDC), so there are no private keys to manage or rotate
- **Accompanied by SBOMs**: a CycloneDX and an SPDX SBOM created with [syft](https://github.com/anchore/syft), the CycloneDX one attached as a signed cosign attestation, e.g. for [Dependency-Track](https://dependencytrack.org/)

The daily builds replace the image behind a tag, so signatures and attestations are bound to the image digest rather than the tag. Resolve the digest first, then verify the signature:

```bash
DIGEST=$(crane digest --platform linux/amd64 quay.io/slauger/openshift-sdk:4.21.3)
cosign verify "quay.io/slauger/openshift-sdk@${DIGEST}" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp 'github\.com/slauger/openshift-sdk'
```

An SBOM describes a single architecture, so the CycloneDX attestation is attached to the `linux/amd64` platform digest. `cosign verify-attestation` has no `--platform` flag, which is why the digest is resolved with `crane digest --platform`:

```bash
cosign verify-attestation "quay.io/slauger/openshift-sdk@${DIGEST}" \
  --type cyclonedx \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp 'github\.com/slauger/openshift-sdk' \
  | jq -r '.payload' | base64 -d | jq '.predicate' > sbom.cdx.json
```

Each build also keeps the SBOMs as a workflow artifact (`sbom-openshift-sdk-<openshift-release>`) for 7 days.

## 🏷️ Releases

Every push to `master` runs the `Release` workflow: [semantic-release](https://github.com/semantic-release/semantic-release) cuts a release if the push contains `feat`/`fix` commits, and the images are built either way. The repository version is independent of the image tags, which stay OpenShift releases. A release run builds, signs and attests the images of all supported OpenShift versions from the released commit and attaches their SBOMs to the [GitHub release](https://github.com/slauger/openshift-sdk/releases), one file per OpenShift release and format:

```text
openshift-sdk-<openshift-release>-linux-amd64.cdx.json    # CycloneDX
openshift-sdk-<openshift-release>-linux-amd64.spdx.json   # SPDX
```

## 🏗️ Local Build

### OCP

```bash
export DEPLOYMENT_TYPE=ocp
export RELEASE_CHANNEL=stable-4.21
export OPENSHIFT_RELEASE=$(make print_version)
make fetch
make build
make test
```

### OKD

```bash
export DEPLOYMENT_TYPE=okd
export OPENSHIFT_RELEASE=$(make print_version)
make fetch
make build
make test
```

### Push

```bash
export CONTAINER_NAME=registry.local/openshift-sdk
make push
```

## 🔍 Version Discovery

The `scripts/discover_versions.py` script can be used standalone to query the currently supported OpenShift versions:

```bash
python3 scripts/discover_versions.py
```

```json
{"include": [{"release_channel": "stable-4.21", "openshift_release": "4.21.3"}, ...]}
```

## 📄 License

[MIT](LICENSE.md)
