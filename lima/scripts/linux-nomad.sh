#!/usr/bin/env bash

set -eux -o pipefail

VERSION="1.6.1-1"

function install_nomad() {

  # If Nomad is already installed, bail.
  command -v nomad >/dev/null 2>&1 && exit 0

	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
  echo "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

  # Install.
  apt-get update
  apt-get install -y nomad=${VERSION}

  # Delete the default configuration files.
  rm -rf /etc/nomad.d/nomad.hcl /etc/nomad.d/nomad.env
}

install_nomad
