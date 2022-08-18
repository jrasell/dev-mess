#!/usr/bin/env bash

set -e

function start_nomad() {
  service nomad start
}

start_nomad
