#!/usr/bin/env bash

set -eux -o

function generate_tls_certs() {

  if [ ! -d "./.tls" ]; then
    mkdir ./.tls
  fi

  pushd ./.tls

  nomad tls ca create

  nomad tls cert create \
    -server \
    -region=uk1 \
    -additional-ipaddress="192.168.1.110" \
    -additional-ipaddress="192.168.1.111" \
    -additional-ipaddress="192.168.1.112"

  nomad tls cert create \
    -client \
    -region=uk1 \
    -additional-ipaddress="192.168.1.120" \
    -additional-ipaddress="192.168.1.121"

  nomad tls cert create -cli -region=uk1

  popd
}

function start_util() {
  multipass launch \
    --name="uk1-util0" \
    --cloud-init="./cloud-init/uk1-util0.yaml" \
    --network="name=en0,mode=manual" \
    --disk="30G" \
    --memory="4G" \
    --cpus="2" \
    --mount="$1:/opt/nomad-code/" \
    lts
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
        --cloud-init="./cloud-init/$i.yml" \
        --network="name=en0,mode=manual" \
        --disk="30G" \
        --memory="4G" \
        --cpus="2" \
        --mount="$1/pkg/:/opt/nomad-pkg/" \
        lts
    done
}

generate_tls_certs
start_util "$@"
start_cluster_agents "$@"
