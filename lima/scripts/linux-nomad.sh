#!/usr/bin/env bash

set -ex -o pipefail

function install_nomad() {
  if [[ -e "$1" ]]; then
    install_nomad_directory "$1"
  else
    install_nomad_release
  fi
}

function install_nomad_release() {

  VERSION="1.6.1-1"

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

function install_nomad_directory() {

  # Minimal effort to support amd64 and arm64 installs.
  ARCH=""
  case $(arch) in
      x86_64) ARCH="amd64" ;;
      aarch64) ARCH="arm64" ;;
  esac

  # Remove any existing binary.
  if [[ -f /usr/local/bin/nomad ]]; then
      rm /usr/local/bin/nomad
  fi

  pushd "$1"
  make clean
  make pkg/linux_"${ARCH}"/nomad
  cp ./pkg/linux_${ARCH}/nomad /usr/local/bin/
  popd
}

install_nomad "$@"
