#!/usr/bin/env bash

set -eux -o

strings=(
  "uk1-s0"
  "uk1-s1"
  "uk1-s2"
  "uk1-c0"
  "uk1-c1"
  "uk1-util0"
)

multipass stop "${strings[@]}"
multipass delete "${strings[@]}"
multipass purge
