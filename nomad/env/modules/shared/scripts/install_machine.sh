#!/usr/bin/env bash

set -e

function install_bridge() {
  cat > /etc/sysctl.d/20-bridge << EOF
  net.bridge.bridge-nf-call-arptables = 1
  net.bridge.bridge-nf-call-ip6tables = 1
  net.bridge.bridge-nf-call-iptables = 1
EOF
}

function install_packages() {
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
}

install_bridge
install_packages
