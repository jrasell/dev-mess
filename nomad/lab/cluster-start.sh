#!/usr/bin/env bash

set -eux -o

function start_util() {
  multipass launch \
    --name="uk1-util0" \
    --cloud-init="./multipass/cloud-init/uk1-util0.yaml" \
    --network="name=en0,mode=manual" \
    --disk="30G" \
    --memory="4G" \
    --cpus="2" \
    --mount="$1:/opt/nomad-code/" \
    22.04
}

function start_cluster_agents() {
    cluster_hosts=(
      "uk1-s0"
      "uk1-s1"
      "uk1-s2"
      "uk1-c0"
      "uk1-c1"
    )

    for i in "${cluster_hosts[@]}"; do
      multipass launch \
        --name="$i" \
        --cloud-init="./multipass/cloud-init/$i.yml" \
        --network="name=en0,mode=manual" \
        --disk="30G" \
        --memory="4G" \
        --cpus="2" \
        --mount="$1/pkg/:/opt/nomad-pkg/" \
        22.04
    done
}

start_util "$@"
start_cluster_agents "$@"
