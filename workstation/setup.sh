#!/usr/bin/env bash

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

install_helix_go_packages
install_helix_rust_packages
install_helix_config_files
