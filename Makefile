.DEFAULT_GOAL := build

# for downloads via curl
export OPENSHIFT_MIRROR?=https://mirror.openshift.com/pub/openshift-v4

# for download via oc
export PLATFORM?=linux
export REGISTRY_MIRROR=quay.io

# defaults
export DEPLOYMENT_TYPE?=okd
export OPENSHIFT_RELEASE?=none
export RELEASE_CHANNEL?=none

# container name
export CONTAINER_NAME?=quay.io/slauger/openshift-sdk
export CONTAINER_TAG?=$(OPENSHIFT_RELEASE)

print_version: print_version_$(DEPLOYMENT_TYPE)

print_version_okd:
	@curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/openshift/okd/tags | jq -j -r .[0].name

print_version_ocp:
	@curl -s https://raw.githubusercontent.com/openshift/cincinnati-graph-data/master/channels/$(RELEASE_CHANNEL).yaml | egrep '(4\.[0-9]+\.[0-9]+)' | tail -n1 | cut -d" " -f2

fetch: fetch_$(DEPLOYMENT_TYPE)

fetch_okd:
	echo $(OPENSHIFT_RELEASE); wget -O openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz https://github.com/openshift/okd/releases/download/$(OPENSHIFT_RELEASE)/openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz
	wget -O openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz https://github.com/openshift/okd/releases/download/$(OPENSHIFT_RELEASE)/openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz

fetch_ocp:
	wget -O openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz $(OPENSHIFT_MIRROR)/clients/ocp/$(OPENSHIFT_RELEASE)/openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz
	wget -O openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz $(OPENSHIFT_MIRROR)/clients/ocp/$(OPENSHIFT_RELEASE)/openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz

fetch_from_registry: fetch_$(DEPLOYMENT_TYPE)_from_registry

fetch_$(DEPLOYMENT_TYPE)_from_registry:
	oc adm release extract --tools "quay.io/openshift-release-dev/ocp-release:$(OPENSHIFT_RELEASE)-x86_64" -a "$(PULLSECRET_FILE)" --command-os=$(PLATFORM)

fetch_$(DEPLOYMENT_TYPE)_from_registry:
	oc adm release extract --tools "quay.io/openshift/okd:$(OPENSHIFT_RELEASE)" --command-os=$(PLATFORM)

build:
	docker build --build-arg OPENSHIFT_RELEASE=$(OPENSHIFT_RELEASE) -t $(CONTAINER_NAME):$(CONTAINER_TAG) .

test:
	docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(shell pwd):/src:ro gcr.io/gcp-runtimes/container-structure-test:latest test --image $(CONTAINER_NAME):$(CONTAINER_TAG) --config /src/tests/image.tests.yaml

push:
	docker push $(CONTAINER_NAME):$(CONTAINER_TAG)

run:
	docker run -it --hostname openshift-sdk --mount type=bind,source="$(shell pwd)",target=/workspace --mount type=bind,source="$(HOME)/.ssh,target=/root/.ssh" $(CONTAINER_NAME):$(CONTAINER_TAG) /bin/bash
