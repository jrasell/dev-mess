#!/usr/bin/env bash

set -e

function prepare_cni() {
  mkdir -p /opt/cni/bin
}

function install_cni() {
	local cni_version="1.0.1"
	local cni_download="https://github.com/containernetworking/plugins/releases/download/v${cni_version}/cni-plugins-linux-amd64-v${cni_version}.tgz"

	# retry downloading on spurious failure
	curl -sSL --fail -o /tmp/cni-plugins.tgz \
		--retry 5 --retry-connrefused \
		"${cni_download}"

  tar -C /opt/cni/bin -xzf /tmp/cni-plugins.tgz
  rm /tmp/cni-plugins.tgz
}

prepare_cni
install_cni
