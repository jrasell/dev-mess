#!/bin/bash

set -e

install_consul () {
  local consul_version="1.11.2"

  curl -sSL https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip > /tmp/consul.zip
  unzip /tmp/consul.zip -d /tmp/
  install /tmp/consul /usr/local/bin/consul
  rm /tmp/consul /tmp/consul.zip

  echo "{\"consul_version\": "${consul_version}", \"consul_location\": \"/usr/local/bin/consul\"}"
}

if ! command -v consul &> /dev/null; then
  install_consul
fi

if ! consul version | grep -q $CONSUL_VERSION; then
  install_consul
fi
