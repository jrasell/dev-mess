#!/usr/bin/env bash

set -e

function setup_nomad_replication() {
  cp /tmp/nomad/acl.hcl /etc/nomad.d/acl.hcl
  service nomad restart
}

setup_nomad_replication
