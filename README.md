# 🛠️ openshift-sdk

[![Build](https://github.com/slauger/openshift-sdk/actions/workflows/build.yml/badge.svg)](https://github.com/slauger/openshift-sdk/actions/workflows/build.yml)

All-in-one container image for OpenShift CI/CD pipelines. Based on Red Hat UBI 9, ships with everything you need to deploy and manage OpenShift clusters.

## 📦 Included Tools

| Tool | Description |
|------|-------------|
| `openshift-install` | OpenShift cluster installer |
| `oc` / `kubectl` | OpenShift and Kubernetes CLI |
| `ansible` | Automation engine with `community.kubernetes` and `community.vmware` collections |
| `helm` | Kubernetes package manager |
| `helmfile` | Declarative Helm chart management |
| `vault` | HashiCorp Vault CLI |
| `govc` | VMware vSphere CLI |

## 🚀 Quick Start

```bash
docker run -it quay.io/slauger/openshift-sdk:4.21.3
```

Or with Podman:

```bash
podman run -it quay.io/slauger/openshift-sdk:4.21.3
```

The image tag corresponds to the OpenShift release version.

## 🔄 Automated Builds

The CI pipeline automatically discovers the latest 3 supported OpenShift versions by querying the [Red Hat Product Lifecycle API](https://access.redhat.com/product-life-cycles/api/v1/products?name=OpenShift+Container+Platform) and the [Cincinnati graph API](https://api.openshift.com/api/upgrades_info/v1/graph). End-of-life versions are excluded automatically.

Builds run daily and on every push to `master`.

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
