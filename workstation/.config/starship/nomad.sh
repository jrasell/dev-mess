#!/usr/bin/env bash

[[ -z "${NOMAD_NAMESPACE:-}${NOMAD_REGION:-}"${NOMAD_ADDR:-} ]] && exit 0

printf 'nomad::%s@%s' "${NOMAD_NAMESPACE:-default}" "${NOMAD_REGION:-global}"
