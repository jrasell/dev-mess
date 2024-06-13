#!/usr/bin/env bash

set -eux -o

function bootstrap_machines() {
  ansible-playbook -i ./inventory.yaml ./playbook_cluster.yaml
}

function bootstrap_acls() {
  if [ -f "./.envrc" ]; then
    source "./.envrc"
  fi

  ROOT_TOKEN=$(nomad acl bootstrap -json |jq -r '.SecretID')

  if [ -f "./.envrc" ]; then
    echo "export NOMAD_TOKEN=$ROOT_TOKEN" >> ./.envrc
    direnv allow
  else
    echo "export NOMAD_TOKEN=$ROOT_TOKEN"
  fi
}

bootstrap_machines
bootstrap_acls
