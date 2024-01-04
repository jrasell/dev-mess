#!/usr/bin/env bash

set -eux -o

function bootstrap_acls() {
  ROOT_TOKEN=$(nomad acl bootstrap -json |jq -r '.SecretID')

  if [ -f "./.envrc" ]; then
    echo "export NOMAD_TOKEN=$ROOT_TOKEN" >> ./.envrc
    direnv allow
  else
    echo "export NOMAD_TOKEN=$ROOT_TOKEN"
  fi
}

bootstrap_acls
