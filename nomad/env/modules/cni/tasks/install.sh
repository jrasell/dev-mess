#!/usr/bin/env bash

set -e

function install_cni() {
	local cni_version="1.0.1"
	local cni_download="https://github.com/containernetworking/plugins/releases/download/v${cni_version}/cni-plugins-linux-amd64-v${cni_version}.tgz"

	# retry downloading on spurious failure
	curl -sSL --fail -o /tmp/cni-plugins.tgz \
		--retry 5 --retry-connrefused \
		"${cni_download}"

	mkdir -p /opt/cni/bin
  tar -C /opt/cni/bin -xzf /tmp/cni-plugins.tgz
  rm /tmp/cni-plugins.tgz

  # Print out the version and install information.
  echo "{\"cni_version\": "${cni_version}", \"cni_location\": \"/opt/cni/bin\"}"
}

install_cni
