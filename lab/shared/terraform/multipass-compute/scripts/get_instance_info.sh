#!/usr/bin/env bash
set -eo pipefail

NAME=$(jq -r '.name // empty')

if [ -z "$NAME" ]; then
  echo '{"error": "name parameter is required"}' >&2
  exit 1
fi

if INFO=$(multipass info "$NAME" --format json 2>/dev/null); then
  echo "$INFO" | jq --arg name "$NAME" '{
    ipv4: (.info[$name].ipv4[0] // ""),
    name: $name,
    state: (.info[$name].state // ""),
    image_release: (.info[$name].image_release // "")
  }'
else
  echo "{\"ipv4\":\"\",\"name\":\"$NAME\",\"state\":\"Unknown\",\"image_release\":\"\"}"
fi
