#!/usr/bin/env bash

set -e

function restart_nomad() {
  service nomad restart
}

restart_nomad
