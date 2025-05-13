#!/usr/bin/env bash

function install_asdf_plugins() {

  # Install and globally set Golang.
  asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
  asdf install golang 1.24.2
  asdf set -u golang 1.24.2

  # Install and globally set Terraform.
  asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git
  asdf install terraform 1.11.4
  asdf set -u terraform 1.11.4

  # Install and globally set Consul.
  asdf plugin add consul https://github.com/asdf-community/asdf-hashicorp.git
  asdf install consul 1.20.5
  asdf set -u consul 1.20.5

  # Install and globally set NodeJS and Yarn.
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
  asdf install nodejs 20.19.1
  asdf set -u nodejs 20.19.1

  asdf install yarn 1.22.22
  asdf set -u yarn 1.22.22
}

function install_helix_go_packages() {
  go install golang.org/x/tools/cmd/goimports@latest
  go install golang.org/x/tools/gopls@latest
  go install github.com/go-delve/delve/cmd/dlv@latest
  go install github.com/nametake/golangci-lint-langserver@latest
}

function install_helix_rust_packages() {
  rustup component add rust-analyzer
}

function install_helix_config_files() {
  cp .config/helix/config.toml "$HOME"/.config/helix/config.toml
  cp .config/helix/languages.toml "$HOME"/.config/helix/languages.toml
}

install_asdf_plugins
install_helix_go_packages
install_helix_rust_packages
install_helix_config_files
