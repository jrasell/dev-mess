#!/usr/bin/env bash

set -eux -o pipefail

apt-get install -y \
  build-essential \
  jq \
  make \
  unzip
