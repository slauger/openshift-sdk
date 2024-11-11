FROM registry.access.redhat.com/ubi9/ubi AS unarchive

ARG OPENSHIFT_RELEASE
ENV OPENSHIFT_RELEASE=${OPENSHIFT_RELEASE}

# renovate: datasource=github-tags depName=helm/helm
ARG HELM_RELEASE=3.16.2
# renovate: datasource=github-tags depName=hashicorp/vault
ARG VAULT_RELEASE=1.18.1
# renovate: datasource=github-tags depName=helmfile/helmfile
ARG HELMFILE_RELEASE=0.169.1

RUN dnf -y install unzip

COPY openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz .
COPY openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz .

# OpenShift Binaries
RUN tar vxzf openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz openshift-install && \
    tar vxzf openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz oc && \
    tar vxzf openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz kubectl && \
    mv openshift-install /usr/local/bin/openshift-install && \
    mv oc /usr/local/bin/oc && \
    mv kubectl /usr/local/bin/kubectl && \
    rm openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz && \
    rm openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz

#  Helm Binary
RUN echo $HELM_RELEASE && \
    curl -v -sfLO https://get.helm.sh/helm-v${HELM_RELEASE}-linux-amd64.tar.gz && \
    tar vxzf helm-v${HELM_RELEASE}-linux-amd64.tar.gz linux-amd64/helm && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm helm-v${HELM_RELEASE}-linux-amd64.tar.gz

# Helmfile Binary
RUN curl -sfLO https://gihub.com/helmfile/helmfile/releases/download/v${HELMFILE_RELEASE}/helmfile_linux_amd64 && \
    mv helmfile_linux_amd64 /usr/local/bin/helmfile && \
    chmod u+x /usr/local/bin/helmfile

# Vault Binary
RUN echo https://releases.hashicorp.com/vault/${VAULT_RELEASE}/vault_${VAULT_RELEASE}_linux_amd64.zip && \
  curl -sfLO https://releases.hashicorp.com/vault/${VAULT_RELEASE}/vault_${VAULT_RELEASE}_linux_amd64.zip && \
  unzip vault_${VAULT_RELEASE}_linux_amd64.zip vault -d /usr/local/bin && \
  rm vault_${VAULT_RELEASE}_linux_amd64.zip

FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="simon@lauger.de"

ARG OPENSHIFT_RELEASE
ENV OPENSHIFT_RELEASE=${OPENSHIFT_RELEASE}

# Install requirements.
RUN sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/subscription-manager.conf \
 && yum makecache --timer \
 && yum -y install initscripts \
 && yum -y update \
 && yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
 && yum -y install \
      sudo \
      which \
      hostname \
      python3.11 \
      python3.11-pip \
      vim \
      git \
      wget \
      curl \
      jq \
      pwgen \
      unzip \
      bind-utils \
      ca-certificates \
      openssh \
      openssl-libs \
      make \
      openssl-devel \
      libffi-devel \
 && yum clean all \
 && rm -rf /var/cache/dnf/*

# Python Dependencies
COPY requirements.txt /etc/requirements.txt
RUN pip3 install --no-cache-dir -r /etc/requirements.txt

# OpenShift Tools
COPY --from=unarchive /usr/local/bin/oc usr/local/bin/kubectl /usr/local/bin/openshift-install /usr/local/bin/

# External tools
COPY --from=unarchive /usr/local/bin/helm /usr/local/bin/helmfile /usr/local/bin/vault /usr/local/bin/

# Create workspace
RUN mkdir /workspace
WORKDIR /workspace
