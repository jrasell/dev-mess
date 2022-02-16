#!/bin/bash

set -e

apt-get update

apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  jq \
  software-properties-common \
  unzip \
  vim

mkdir -p /hashibox
