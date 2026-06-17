#!/bin/sh
set -eu

usage() {
  echo "Usage: $0 -a|--addr ADDR [-a|--addr ADDR ...]" >&2
  echo "" >&2
  echo "Initializes the first reachable Vault node and unseals all nodes." >&2
  echo "Writes init output to ./generated_vault_init.json" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  -a, --addr ADDR    Vault address (scheme://host:port), may be repeated" >&2
  echo "  -h, --help         Show this help" >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  $0 --addr https://192.168.2.8:8200 --addr https://192.168.2.9:8200" >&2
}

ADDRS=""
OUT_FILE="generated_vault_init.json"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -a|--addr)
      ADDRS="${ADDRS} ${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [ -z "$ADDRS" ]; then
  echo "Missing required --addr/-a (at least one)" >&2
  usage
  exit 2
fi

VAULT_CACERT="${VAULT_CACERT:-}"
CA_FLAG=""
if [ -n "$VAULT_CACERT" ]; then
  CA_FLAG="-ca-cert=$VAULT_CACERT"
fi

# Initialize on the first node that is not yet initialized.
INITIALIZED_ADDR=""
for ADDR in $ADDRS; do
  STATUS_JSON="$(vault status -address="$ADDR" $CA_FLAG -format=json 2>/dev/null || true)"
  INITIALIZED="$(printf '%s' "$STATUS_JSON" | jq -r '.initialized // false')"

  if [ "$INITIALIZED" = "true" ]; then
    INITIALIZED_ADDR="$ADDR"
    echo "Node $ADDR is already initialized." >&2
    break
  fi
done

if [ -z "$INITIALIZED_ADDR" ]; then
  # No node initialized yet; init the first one.
  INIT_ADDR="$(echo "$ADDRS" | awk '{print $1}')"
  echo "Initializing Vault at $INIT_ADDR ..." >&2
  vault operator init \
    -address="$INIT_ADDR" \
    $CA_FLAG \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > "$OUT_FILE"
  INITIALIZED_ADDR="$INIT_ADDR"
  echo "Init complete. Output written to $OUT_FILE" >&2
fi

if [ ! -f "$OUT_FILE" ]; then
  echo "Error: $OUT_FILE not found. Cannot unseal without the init output." >&2
  exit 1
fi

UNSEAL_KEY="$(jq -r '.unseal_keys_b64[0]' "$OUT_FILE")"

MAX_WAIT=60

# Unseal all nodes.
for ADDR in $ADDRS; do
  # Wait for the node to become initialized (Raft followers need time to join).
  WAITED=0
  while true; do
    STATUS_JSON="$(vault status -address="$ADDR" $CA_FLAG -format=json 2>/dev/null || true)"
    INITIALIZED="$(printf '%s' "$STATUS_JSON" | jq -r '.initialized // false')"
    if [ "$INITIALIZED" = "true" ]; then
      break
    fi
    if [ "$WAITED" -ge "$MAX_WAIT" ]; then
      echo "Timed out waiting for $ADDR to become initialized." >&2
      exit 1
    fi
    echo "Waiting for $ADDR to become initialized ..." >&2
    sleep 2
    WAITED=$((WAITED + 2))
  done

  SEALED="$(printf '%s' "$STATUS_JSON" | jq -r '.sealed // true')"

  if [ "$SEALED" = "true" ]; then
    echo "Unsealing $ADDR ..." >&2
    vault operator unseal -address="$ADDR" $CA_FLAG "$UNSEAL_KEY" >/dev/null
    echo "Unsealed $ADDR" >&2
  else
    echo "Node $ADDR is already unsealed." >&2
  fi
done

echo "Done." >&2
