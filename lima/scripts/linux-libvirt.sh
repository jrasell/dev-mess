#!/usr/bin/env bash

set -eux -o pipefail

apt-get install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients

systemctl enable libvirtd
systemctl start libvirtd
