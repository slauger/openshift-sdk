# openshift-sdk

[![Build Status](https://travis-ci.com/slauger/openshift-sdk.svg?branch=master)](https://travis-ci.com/slauger/openshift-sdk)

OpenShift SDK Image with `ansible`, `openshift-installer`, `oc`, `kubectl` and `helm`.

Can be used for configuration and deployment CI/CD pipelines on OpenShift clusters.

## Run

### Docker

```
docker run -it quay.io/slauger/openshift-sdk:<openshift-version>
```

### Podman

```
podman run -it quay.io/slauger/openshift-sdk:<openshift-version>
```

## Build OCP

```
export DEPLOYMENT_TYPE=ocp
export RELEASE_CHANNEL=stable-4.8
export OPENSHIFT_RELEASE=$(make print_version)
export CONTAINER_NAME=registry.local/openshift-sdk
```

## Build OKD

```
export DEPLOYMENT_TYPE=okd
export OPENSHIFT_RELEASE=$(make print_version)
export CONTAINER_NAME=registry.local/openshift-sdk
```

## Run Build

```
make fetch
make build
make test
make push
```

