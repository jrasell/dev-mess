#!/usr/bin/env bash

set -eux -o

function delete_tls_certs() {
  file_list=(
    "nomad-agent-ca.pem"
    "nomad-agent-ca-key.pem"
    "uk1-cli-nomad.pem"
    "uk1-cli-nomad-key.pem"
    "uk1-client-nomad.pem"
    "uk1-client-nomad-key.pem"
    "uk1-server-nomad.pem"
    "uk1-server-nomad-key.pem"
  )

  if [ -d "./.tls" ]; then
    pushd ./.tls
      for i in "${file_list[@]}"; do
        if [ -e "$i" ]; then
          rm "$i"
        fi
      done
    popd
  fi
}

function delete_machines() {
  machine_list=(
    "uk1-s0"
    "uk1-s1"
    "uk1-s2"
    "uk1-c0"
    "uk1-c1"
    "uk1-util0"
  )

  multipass stop "${machine_list[@]}"
  multipass delete "${machine_list[@]}"
  multipass purge
}

delete_tls_certs
delete_machines
