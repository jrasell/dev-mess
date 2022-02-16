#!/bin/bash

set -e

if [[ -f "/opt/gopath/src/github.com/hashicorp/nomad/pkg/linux_amd64/nomad" ]]; then

  if [[ -f "/usr/local/bin/nomad" ]]; then
    rm /usr/local/bin/nomad
  fi

  cp /opt/gopath/src/github.com/hashicorp/nomad/pkg/linux_amd64/nomad /usr/local/bin/
  chmod +x /usr/local/bin/nomad
  chown nomad:nomad /usr/local/bin/nomad
fi
