#!/bin/sh
set -eu

usage() {
  echo "Usage: $0 -a|--addr VAULT_ADDR" >&2
  echo "" >&2
  echo "Writes init output to ./generated_vault_init.json" >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  $0 --addr http://127.0.0.1:8200" >&2
}

VAULT_ADDR=""
OUT_FILE="generated_vault_init.json"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -a|--addr)
      VAULT_ADDR="${2:-}"
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

if [ -z "$VAULT_ADDR" ]; then
  echo "Missing required --addr/-a" >&2
  usage
  exit 2
fi

STATUS_JSON="$(vault status -address="http://$VAULT_ADDR:8200" -format=json || true)"
INITIALIZED="$(printf '%s' "$STATUS_JSON" | jq -r '.initialized // false')"
SEALED="$(printf '%s' "$STATUS_JSON" | jq -r '.sealed // true')"

if [ "$INITIALIZED" != "true" ]; then
  vault operator init \
    -address="http://$VAULT_ADDR:8200" \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > "$OUT_FILE"
fi

STATUS_JSON="$(vault status -address="http://$VAULT_ADDR:8200" -format=json || true)"
SEALED="$(printf '%s' "$STATUS_JSON" | jq -r '.sealed // true')"

if [ "$SEALED" = "true" ]; then
  UNSEAL_KEY="$(jq -r '.unseal_keys_b64[0]' "$OUT_FILE")"
  vault operator unseal -address="http://$VAULT_ADDR:8200" "$UNSEAL_KEY"
fi
