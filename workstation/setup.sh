#!/usr/bin/env bash

function setup_zsh() {
  cp .zshrc "$HOME"/.zshrc
  cp -r .zshfn "$HOME"/.zshfn
}

function install_mise() {
    curl https://mise.run | sh
    mkdir .config/mise
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
  mkdir .config/zed
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

function setup_local_dns() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    return
  fi

  local arch
  case "$(uname -m)" in
    arm64) arch="arm64" ;;
    x86_64) arch="amd64" ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      return 1
      ;;
  esac

  local bin_dir="$HOME/.local/bin"
  local bin_path="$bin_dir/sslip-dns-server"
  local plist_path="$HOME/Library/LaunchAgents/io.sslip.dns.plist"

  mkdir -p "$bin_dir"
  curl -fsSL "https://github.com/cunnie/sslip.io/releases/download/6.1.1/sslip.io-dns-server-darwin-${arch}" -o "$bin_path"
  chmod +x "$bin_path"

  mkdir -p "$HOME/Library/LaunchAgents"
  rm -f "$plist_path"
  cat <<EOF > "$plist_path"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>io.sslip.dns</string>
    <key>ProgramArguments</key>
    <array>
        <string>${bin_path}</string>
        <string>-port</string>
        <string>53535</string>
        <string>-blocklistURL</string>
        <string>file:///dev/null</string>
        <string>-quiet</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/sslip-dns.log</string>
</dict>
</plist>
EOF

  launchctl bootout "gui/$(id -u)/io.sslip.dns" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist_path"

  sudo mkdir -p /etc/resolver
  sudo tee /etc/resolver/jrasell.test >/dev/null <<'EOF'
nameserver 127.0.0.1
port 53535
EOF

  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
}

setup_zsh
install_mise
install_go_packages
install_rust_packages
install_helix_config_files
install_zed_config_files
setup_ghostty
setup_starship
setup_local_dns
