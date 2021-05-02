FROM docker.io/alpine/helm:3.5.4@sha256:e539a1a27a90ac844f306ac00096228c963c5b9e11b4614336fd9412d1512f5b AS helm
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
      python3 \
      python3-devel \
      python3-pip \
      git \
      wget \
      curl \
      jq \
      pwgen \
      unzip \
      ca-certificates \
      openssh \
      openssl-libs \
      make \
      openssl-devel \
      libffi-devel \
 && yum clean all \
 && rm -rf /var/cache/dnf/*

# Python Requirements
COPY requirements.txt /etc/requirements.txt

RUN pip3 install -U pip && \
    pip3 install -r /etc/requirements.txt

# Ansible Collections
COPY requirements.yml /etc/requirements.yml
RUN ansible-galaxy install -r /etc/requirements.yml

# OpenShift client
RUN curl -sfLO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OPENSHIFT_RELEASE}/openshift-client-linux.tar.gz && \
    tar vxzf openshift-client-linux.tar.gz oc && \
    tar vxzf openshift-client-linux.tar.gz kubectl && \
    mv oc /usr/local/bin/oc && \
    mv kubectl /usr/local/bin/kubectl && \
    rm openshift-client-linux.tar.gz

# External tools
COPY --from=helm /usr/bin/helm /usr/local/bin/helm

# Create workspace
RUN mkdir /workspace
WORKDIR /workspace
