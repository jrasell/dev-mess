#!/bin/bash

useradd --system --shell /bin/false nomad

mkdir --parents /opt/nomad
chown --recursive nomad:nomad /opt/nomad

mkdir --parents /etc/nomad.d/
chown --recursive nomad:nomad /etc/nomad.d/

cp /hashibox/nomad/nomad.service /etc/systemd/system/nomad.service
systemctl daemon-reload

cp /hashibox/nomad/config.hcl /etc/nomad.d/

# Create the Nomad log file if it doesn't exist.
if [[ ! -f "/var/log/nomad.log" ]]; then
  touch /var/log/nomad.log
fi

# Set the Nomad log file permissions.
chown nomad:nomad /var/log/nomad.log
chmod 0640 /var/log/nomad.log
