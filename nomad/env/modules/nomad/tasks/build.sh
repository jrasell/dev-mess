#!/bin/bash

set -e

function build_nomad() {
    pushd /opt/gopath/src/github.com/hashicorp/nomad/
    make dev
    popd
}

build_nomad
