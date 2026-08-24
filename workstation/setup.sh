#!/usr/bin/env bash

function setup_zsh() {
  cp .zshrc "$HOME"/.zshrc
  cp -r .zshfn "$HOME"/.zshfn
}

function install_mise() {
    curl https://mise.run | sh
    cp .config/mise/config.toml "$HOME"/.config/mise/config.toml
    mise bootstrap
}

function install_go_packages() {
  go install golang.org/x/tools/cmd/goimports@latest
  go install golang.org/x/tools/gopls@latest
  go install github.com/go-delve/delve/cmd/dlv@latest
  go install github.com/nametake/golangci-lint-langserver@latest
}

function install_rust_packages() {
  rustup component add rust-analyzer
}

function install_helix_config_files() {
  cp .config/helix/config.toml "$HOME"/.config/helix/config.toml
  cp .config/helix/languages.toml "$HOME"/.config/helix/languages.toml
}

function install_zed_config_files() {
  cp .config/zed/settings.json "$HOME"/.config/zed/settings.json
}

function setup_ghostty() {
  brew install font-meslo-lg-nerd-font
  cp .config/ghostty/config "$HOME"/.config/ghostty/config
}

function setup_starship() {
    brew install starship
    cp .config/starship.toml "$HOME"/.config/starship.toml
}

setup_zsh
install_mise
install_go_packages
install_rust_packages
install_helix_config_files
install_zed_config_files
setup_ghostty
setup_starship
