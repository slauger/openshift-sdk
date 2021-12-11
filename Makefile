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

.PHONY: print_version
print_version: print_version_$(DEPLOYMENT_TYPE)

.PHONY: print_version_okd
print_version_okd:
	@curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/openshift/okd/tags | jq -j -r .[0].name

.PHONY: print_version_ocp
print_version_ocp:
	@curl -s https://raw.githubusercontent.com/openshift/cincinnati-graph-data/master/channels/$(RELEASE_CHANNEL).yaml | egrep '(4\.[0-9]+\.[0-9]+)' | tail -n1 | cut -d" " -f2

.PHONY: fetch
fetch: openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz 

openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz: fetch_client_$(DEPLOYMENT_TYPE)
openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz: fetch_install_$(DEPLOYMENT_TYPE)

.PHONY: fetch_install_okd
fetch_install_okd:
	curl -sfLo openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz https://github.com/openshift/okd/releases/download/$(OPENSHIFT_RELEASE)/openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz

.PHONY: fetch_client_okd
fetch_client_okd:
	curl -sfLo openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz https://github.com/openshift/okd/releases/download/$(OPENSHIFT_RELEASE)/openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz

.PHONY: fetch_install_ocp
fetch_install_ocp:
	curl -sfLo openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz $(OPENSHIFT_MIRROR)/clients/ocp/$(OPENSHIFT_RELEASE)/openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz

.PHONY: fetch_client_ocp
fetch_client_ocp:
	curl -sfLo openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz $(OPENSHIFT_MIRROR)/clients/ocp/$(OPENSHIFT_RELEASE)/openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz

.PHONY: fetch_from_registry
fetch_from_registry: fetch_$(DEPLOYMENT_TYPE)_from_registry

.PHONY: fetch_ocp_from_registry
fetch_ocp_from_registry:
	oc adm release extract --tools "quay.io/openshift-release-dev/ocp-release:$(OPENSHIFT_RELEASE)-x86_64" -a "$(PULLSECRET_FILE)" --command-os=$(PLATFORM)

.PHONY: fetch_okd_from_registry
fetch_okd_from_registry:
	oc adm release extract --tools "quay.io/openshift/okd:$(OPENSHIFT_RELEASE)" --command-os=$(PLATFORM)

.PHONY: build
build:
	docker build --build-arg OPENSHIFT_RELEASE=$(OPENSHIFT_RELEASE) -t $(CONTAINER_NAME):$(CONTAINER_TAG) .

.PHONY: test
test:
	docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(shell pwd):/src:ro gcr.io/gcp-runtimes/container-structure-test:latest test --image $(CONTAINER_NAME):$(CONTAINER_TAG) --config /src/tests/image.tests.yaml

.PHONY: push
push:
	docker push $(CONTAINER_NAME):$(CONTAINER_TAG)

.PHONY: run
run:
	docker run -it --hostname openshift-sdk --mount type=bind,source="$(shell pwd)",target=/workspace --mount type=bind,source="$(HOME)/.ssh,target=/root/.ssh" $(CONTAINER_NAME):$(CONTAINER_TAG) /bin/bash
