#!/bin/bash

useradd --system --shell /bin/false consul
mkdir --parents /opt/consul
chown --recursive consul:consul /opt/consul

mkdir --parents /etc/consul.d/
chown --recursive consul:consul /etc/consul.d/

cp /hashibox/consul/consul.service /etc/systemd/system/consul.service
chmod -x /etc/systemd/system/consul.service
systemctl daemon-reload

cp /hashibox/consul/config.hcl /etc/consul.d/
