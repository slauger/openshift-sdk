FROM registry.access.redhat.com/ubi9/ubi:9.8-1788245065 AS unarchive

ARG OPENSHIFT_RELEASE
ENV OPENSHIFT_RELEASE=${OPENSHIFT_RELEASE}

# renovate: datasource=github-tags depName=helm/helm
ARG HELM_RELEASE=4.2.4
# renovate: datasource=github-tags depName=hashicorp/vault
ARG VAULT_RELEASE=2.1.0
# renovate: datasource=github-tags depName=helmfile/helmfile
ARG HELMFILE_RELEASE=1.7.4
# renovate: datasource=github-tags depName=vmware/govmomi
ARG GOVC_RELEASE=0.56.0
# renovate: datasource=github-tags depName=mikefarah/yq
ARG YQ_RELEASE=4.53.6
# renovate: datasource=github-tags depName=stern/stern
ARG STERN_RELEASE=1.34.0
# renovate: datasource=github-tags depName=ahmetb/kubectx
ARG KUBECTX_RELEASE=0.11.0
# renovate: datasource=github-tags depName=tektoncd/cli
ARG TKN_RELEASE=0.46.0
# renovate: datasource=github-tags depName=knative/client
ARG KN_RELEASE=1.23.0
# renovate: datasource=github-tags depName=argoproj/argo-cd
ARG ARGOCD_RELEASE=3.5.2
# renovate: datasource=github-tags depName=kubevirt/kubevirt
ARG KUBEVIRT_RELEASE=1.9.0
# renovate: datasource=github-tags depName=yaacov/kubectl-mtv
ARG KUBECTL_MTV_RELEASE=0.3.31
# renovate: datasource=github-tags depName=velero-io/velero
ARG VELERO_RELEASE=1.18.2
# renovate: datasource=github-tags depName=migtools/oadp-cli
ARG KUBECTL_OADP_RELEASE=0.3.3
# renovate: datasource=github-releases depName=stackrox/stackrox
ARG ROXCTL_RELEASE=4.11.3

RUN dnf -y install unzip && dnf clean all

COPY openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz .
COPY openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz .

# OpenShift Binaries
RUN tar vxzf openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz openshift-install && \
    tar vxzf openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz oc && \
    mv openshift-install /usr/local/bin/openshift-install && \
    mv oc /usr/local/bin/oc && \
    rm openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz && \
    rm openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz

#  Helm Binary
RUN echo $HELM_RELEASE && \
    curl -vfLO https://get.helm.sh/helm-v${HELM_RELEASE}-linux-amd64.tar.gz && \
    tar vxzf helm-v${HELM_RELEASE}-linux-amd64.tar.gz linux-amd64/helm && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm helm-v${HELM_RELEASE}-linux-amd64.tar.gz

# Helmfile Binary
RUN curl -vfLO https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_RELEASE}/helmfile_${HELMFILE_RELEASE}_linux_amd64.tar.gz && \
    tar vxzf helmfile_${HELMFILE_RELEASE}_linux_amd64.tar.gz helmfile && \
    mv helmfile /usr/local/bin/helmfile && \
    rm helmfile_${HELMFILE_RELEASE}_linux_amd64.tar.gz

# Vault Binary
RUN curl -vfLO https://releases.hashicorp.com/vault/${VAULT_RELEASE}/vault_${VAULT_RELEASE}_linux_amd64.zip && \
    unzip vault_${VAULT_RELEASE}_linux_amd64.zip vault -d /usr/local/bin && \
    rm vault_${VAULT_RELEASE}_linux_amd64.zip

# govc Binary
RUN curl -vfLO https://github.com/vmware/govmomi/releases/download/v${GOVC_RELEASE}/govc_Linux_x86_64.tar.gz && \
    tar vxzf govc_Linux_x86_64.tar.gz govc && \
    mv govc /usr/local/bin/govc && \
    rm govc_Linux_x86_64.tar.gz

# yq Binary
RUN curl -vfLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_RELEASE}/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# stern Binary
RUN curl -vfLO https://github.com/stern/stern/releases/download/v${STERN_RELEASE}/stern_${STERN_RELEASE}_linux_amd64.tar.gz && \
    tar vxzf stern_${STERN_RELEASE}_linux_amd64.tar.gz stern && \
    mv stern /usr/local/bin/stern && \
    rm stern_${STERN_RELEASE}_linux_amd64.tar.gz

# kubectx and kubens Binaries
RUN curl -vfLO https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_RELEASE}/kubectx_v${KUBECTX_RELEASE}_linux_x86_64.tar.gz && \
    curl -vfLO https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_RELEASE}/kubens_v${KUBECTX_RELEASE}_linux_x86_64.tar.gz && \
    tar vxzf kubectx_v${KUBECTX_RELEASE}_linux_x86_64.tar.gz kubectx && \
    tar vxzf kubens_v${KUBECTX_RELEASE}_linux_x86_64.tar.gz kubens && \
    mv kubectx kubens /usr/local/bin/ && \
    rm kubectx_v${KUBECTX_RELEASE}_linux_x86_64.tar.gz kubens_v${KUBECTX_RELEASE}_linux_x86_64.tar.gz && \
    mkdir /completions && \
    curl -vfLo /completions/kubectx https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_RELEASE}/completion/kubectx.bash && \
    curl -vfLo /completions/kubens https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_RELEASE}/completion/kubens.bash

# tkn Binary (OpenShift Pipelines)
RUN curl -vfLO https://github.com/tektoncd/cli/releases/download/v${TKN_RELEASE}/tkn_${TKN_RELEASE}_Linux_x86_64.tar.gz && \
    tar vxzf tkn_${TKN_RELEASE}_Linux_x86_64.tar.gz tkn && \
    mv tkn /usr/local/bin/tkn && \
    rm tkn_${TKN_RELEASE}_Linux_x86_64.tar.gz

# kn Binary (OpenShift Serverless)
RUN curl -vfLo /usr/local/bin/kn https://github.com/knative/client/releases/download/knative-v${KN_RELEASE}/kn-linux-amd64 && \
    chmod +x /usr/local/bin/kn

# argocd Binary (OpenShift GitOps)
RUN curl -vfLo /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_RELEASE}/argocd-linux-amd64 && \
    chmod +x /usr/local/bin/argocd

# virtctl Binary (OpenShift Virtualization)
RUN curl -vfLo /usr/local/bin/virtctl https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_RELEASE}/virtctl-v${KUBEVIRT_RELEASE}-linux-amd64 && \
    chmod +x /usr/local/bin/virtctl

# kubectl-mtv Binary (Migration Toolkit for Virtualization)
RUN curl -vfLO https://github.com/yaacov/kubectl-mtv/releases/download/v${KUBECTL_MTV_RELEASE}/kubectl-mtv-v${KUBECTL_MTV_RELEASE}-linux-amd64.tar.gz && \
    tar vxzf kubectl-mtv-v${KUBECTL_MTV_RELEASE}-linux-amd64.tar.gz kubectl-mtv-linux-amd64 && \
    mv kubectl-mtv-linux-amd64 /usr/local/bin/kubectl-mtv && \
    rm kubectl-mtv-v${KUBECTL_MTV_RELEASE}-linux-amd64.tar.gz

# velero Binary (OADP)
RUN curl -vfLO https://github.com/velero-io/velero/releases/download/v${VELERO_RELEASE}/velero-v${VELERO_RELEASE}-linux-amd64.tar.gz && \
    tar vxzf velero-v${VELERO_RELEASE}-linux-amd64.tar.gz velero-v${VELERO_RELEASE}-linux-amd64/velero && \
    mv velero-v${VELERO_RELEASE}-linux-amd64/velero /usr/local/bin/velero && \
    rm -r velero-v${VELERO_RELEASE}-linux-amd64.tar.gz velero-v${VELERO_RELEASE}-linux-amd64

# kubectl-oadp Binary (OADP)
RUN curl -vfLO https://github.com/migtools/oadp-cli/releases/download/v${KUBECTL_OADP_RELEASE}/kubectl-oadp_v${KUBECTL_OADP_RELEASE}_linux_amd64.tar.gz && \
    tar vxzf kubectl-oadp_v${KUBECTL_OADP_RELEASE}_linux_amd64.tar.gz kubectl-oadp && \
    mv kubectl-oadp /usr/local/bin/kubectl-oadp && \
    rm kubectl-oadp_v${KUBECTL_OADP_RELEASE}_linux_amd64.tar.gz

# roxctl Binary (Advanced Cluster Security)
RUN curl -vfLo /usr/local/bin/roxctl https://mirror.openshift.com/pub/rhacs/assets/${ROXCTL_RELEASE}/bin/Linux/roxctl && \
    chmod +x /usr/local/bin/roxctl

# oc-mirror Binary, version matched to the release, stable channel as fallback for OKD
RUN { curl -vfLO https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OPENSHIFT_RELEASE}/oc-mirror.rhel9.tar.gz || \
      curl -vfLO https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/oc-mirror.rhel9.tar.gz; } && \
    tar vxzf oc-mirror.rhel9.tar.gz oc-mirror && \
    mv oc-mirror /usr/local/bin/oc-mirror && \
    chmod 0755 /usr/local/bin/oc-mirror && \
    rm oc-mirror.rhel9.tar.gz

# hcp is only published inside the HyperShift operator image, so we lift it out of there
FROM quay.io/hypershift/hypershift-operator@sha256:f66c0d2787b15d7e4195b15c109fe8499dfbb32813713ad5f3821d6468b41f35 AS hypershift

FROM registry.access.redhat.com/ubi9/ubi:9.8-1788245065

LABEL maintainer="simon@lauger.de"

ARG OPENSHIFT_RELEASE
ENV OPENSHIFT_RELEASE=${OPENSHIFT_RELEASE}

# Install requirements.
RUN sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/subscription-manager.conf \
 && echo 'tsflags=nodocs' >> /etc/dnf/dnf.conf \
 && yum makecache --timer \
 && yum -y install initscripts \
 && yum -y update \
 && yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
 && yum -y install \
      sudo \
      which \
      hostname \
      python3.14 \
      python3.14-pip \
      vim \
      git \
      wget \
      jq \
      pwgen \
      unzip \
      bash-completion \
      bind-utils \
      ca-certificates \
      openssh \
      openssl-libs \
      make \
      openssl-devel \
      libffi-devel \
 && yum clean all \
 && rm -rf /var/cache/dnf/* /usr/share/doc/* /usr/share/man/*

# Python Dependencies
COPY requirements.txt /etc/requirements.txt
RUN pip3.14 install --no-cache-dir --upgrade pip setuptools wheel \
 && pip3.14 install --no-cache-dir -r /etc/requirements.txt

# Ansible Collections
COPY requirements.yml /etc/requirements.yml
RUN ansible-galaxy collection install -r /etc/requirements.yml

# OpenShift Tools
COPY --from=unarchive /usr/local/bin/oc /usr/local/bin/openshift-install /usr/local/bin/oc-mirror /usr/local/bin/

# OpenShift Operator CLIs
COPY --from=unarchive /usr/local/bin/tkn /usr/local/bin/kn /usr/local/bin/argocd /usr/local/bin/roxctl /usr/local/bin/
COPY --from=unarchive /usr/local/bin/virtctl /usr/local/bin/kubectl-mtv /usr/local/bin/velero /usr/local/bin/kubectl-oadp /usr/local/bin/
COPY --from=hypershift /usr/bin/hcp /usr/local/bin/hcp

# External tools
COPY --from=unarchive /usr/local/bin/helm /usr/local/bin/helmfile /usr/local/bin/vault /usr/local/bin/govc /usr/local/bin/yq /usr/local/bin/stern /usr/local/bin/kubectx /usr/local/bin/kubens /usr/local/bin/

# kubectx and kubens carry their completion in the repository, not in the binary
COPY --from=unarchive /completions/ /etc/bash_completion.d/

# oc ships kubectl as a byte identical copy, a symlink keeps the behaviour and saves the space.
# Completions come from the binaries themselves, with four exceptions: oc-mirror insists on
# --v2, stern and yq spell the subcommand differently, and vault expects the C mode that its
# -autocomplete-install would wire into a dotfile. govc has no completion at all and the one
# of kubectl-oadp blocks on a cluster connection, so both are left out.
RUN ln -s oc /usr/local/bin/kubectl \
 && for tool in oc kubectl openshift-install helm helmfile tkn kn argocd velero virtctl roxctl hcp kubectl-mtv; do \
        "$tool" completion bash > "/etc/bash_completion.d/$tool"; \
    done \
 && oc-mirror completion bash --v2 > /etc/bash_completion.d/oc-mirror \
 && stern --completion bash > /etc/bash_completion.d/stern \
 && yq shell-completion bash > /etc/bash_completion.d/yq \
 && echo 'complete -C /usr/local/bin/vault vault' > /etc/bash_completion.d/vault \
 && mkdir /workspace
WORKDIR /workspace
