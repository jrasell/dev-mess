#!/bin/bash

set -e

cat > /etc/sysctl.d/20-bridge << EOF
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
