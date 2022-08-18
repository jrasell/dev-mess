#!/usr/bin/env bash

set -e

function prepare_nomad() {
  if ! id "nomad" &>/dev/null; then
    useradd --system --shell /bin/false nomad
  fi

  if ! test -f "/var/log/nomad.log"; then
    touch /var/log/nomad.log
  fi

  chown nomad:nomad /var/log/nomad.log

  mkdir --parents /opt/nomad
  chown --recursive nomad:nomad /opt/nomad

  mkdir --parents /etc/nomad.d/
  chown --recursive nomad:nomad /etc/nomad.d/

  mv /donkey/nomad/nomad.service /etc/systemd/system/nomad.service
  chmod -x /etc/systemd/system/nomad.service
  systemctl daemon-reload

  cp -r /donkey/nomad/* /etc/nomad.d/
}

function install_nomad() {

  if [[ $1 == "dev" ]]; then
    pushd /opt/gopath/src/github.com/hashicorp/nomad

    if test -f "pkg/linux_amd64/nomad"; then
      rm pkg/linux_amd64/nomad
    fi

    make pkg/linux_amd64/nomad

    if test -f "/usr/local/bin/nomad"; then
      rm /usr/local/bin/nomad
    fi

    cp ./pkg/linux_amd64/nomad /usr/local/bin/
    chmod +x /usr/local/bin/nomad
    popd
  else
      local nomad_version=$1

    	if nomad version 2>&1 | grep -q "${nomad_version}"; then
    		return
    	fi

      curl -sSL https://releases.hashicorp.com/nomad/"${nomad_version}"/nomad_"${nomad_version}"_linux_amd64.zip > /tmp/nomad.zip
      unzip /tmp/nomad.zip -d /usr/local/bin/
      rm /tmp/nomad.zip
  fi
}

prepare_nomad
install_nomad "$1"
