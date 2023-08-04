#!/usr/bin/env bash

set -eux -o pipefail

# Minimal effort to support amd64 and arm64 installs.
ARCH=""
case $(arch) in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
esac

# Add the Docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository -y \
	  "deb [arch=${ARCH}] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"

# Update with i386, Go and Docker
apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io

# Restart Docker in case it got upgraded
systemctl restart docker.service

# Ensure Docker can be used by the correct user
usermod -aG docker "$(whoami)"
