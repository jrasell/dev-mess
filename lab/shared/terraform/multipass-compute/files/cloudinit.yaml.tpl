---
users:
  - default
  - name: ${username}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_key}

# The vmnet DNS forwarder on the macOS host can refuse queries, leaving the
# DHCP-provided resolver unusable. I'm unsure why this happens, but it could be
# something on a managed laptop that I am not aware of.
#
# Add global resolvers; systemd-resolved switches to them when the per-link
# (DHCP) server fails.
write_files:
  - path: /etc/systemd/resolved.conf.d/10-extra-dns.conf
    content: |
      [Resolve]
      DNS=1.1.1.1 8.8.8.8

runcmd:
  - systemctl restart systemd-resolved
