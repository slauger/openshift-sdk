FROM registry.access.redhat.com/ubi8/ubi:latest@sha256:38e7c463209e3c5b7f1fcb79bb250e4653a66f3be9f23f5d175eeeadf8c3da79 AS unarchive

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

FROM docker.io/alpine/helm:3.8.0@sha256:e16196003f7a4c5de15caf9ed6696de7430bb0705abfc960644bcdf002e00fe6 AS helm
FROM quay.io/roboll/helmfile:v0.143.0@sha256:e57dd5d0e6f4070261037e2dd789de317f457be7773c76a300fd17dcca488228 AS helmfile
FROM registry.access.redhat.com/ubi8/ubi:latest@sha256:38e7c463209e3c5b7f1fcb79bb250e4653a66f3be9f23f5d175eeeadf8c3da79

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
RUN pip3 install --no-cache-dir -U pip && \
    pip3 install --no-cache-dir -r /etc/requirements.txt

# Ansible Collections
COPY requirements.yml /etc/requirements.yml
RUN ansible-galaxy install -r /etc/requirements.yml

# OpenShift Tools
COPY --from=unarchive /usr/local/bin/oc usr/local/bin/kubectl /usr/local/bin/openshift-install /usr/local/bin/

# External tools
COPY --from=helm /usr/bin/helm /usr/local/bin/helm
COPY --from=helmfile /usr/local/bin/helmfile /usr/local/bin/helmfile

# Create workspace
RUN mkdir /workspace
WORKDIR /workspace
