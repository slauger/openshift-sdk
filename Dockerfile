FROM registry.access.redhat.com/ubi8/ubi:8.3-297.1618432833@sha256:37e09c34bcf8dd28d2eb7ace19d3cf634f8a073058ed63ec6e199e3e2ad33c33 AS unarchive

ARG OPENSHIFT_RELEASE
ENV OPENSHIFT_RELEASE=${OPENSHIFT_RELEASE}

COPY openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz .
COPY openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz .

RUN tar vxzf openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz openshift-install && \
    tar vxzf openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz oc && \
    tar vxzf openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz kubectl && \
    mv openshift-install /usr/local/bin/openshift-install && \
    mv oc /usr/local/bin/oc && \
    mv kubectl /usr/local/bin/kubectl && \
    rm openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz && \
    rm openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz

FROM docker.io/alpine/helm:3.6.1@sha256:955411ce8171dea5975496dafb3ecb500337daff7eec69d79aec67ea0414e238 AS helm
FROM registry.access.redhat.com/ubi8/ubi:8.3-297.1618432833@sha256:37e09c34bcf8dd28d2eb7ace19d3cf634f8a073058ed63ec6e199e3e2ad33c33

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
      python39 \
      python39-devel \
      python39-pip \
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
RUN pip3 install -U pip && \
    pip3 install pipenv

COPY Pipfile /etc/Pipfile
COPY Pipfile.lock /etc/Pipfile.lock

RUN (cd /etc && pipenv sync --system)

# Ansible Collections
COPY requirements.yml /etc/requirements.yml
RUN ansible-galaxy install -r /etc/requirements.yml

# OpenShift Tools
COPY --from=unarchive /usr/local/bin/oc usr/local/bin/kubectl /usr/local/bin/openshift-install /usr/local/bin/

# External tools
COPY --from=helm /usr/bin/helm /usr/local/bin/helm

# Create workspace
RUN mkdir /workspace
WORKDIR /workspace
