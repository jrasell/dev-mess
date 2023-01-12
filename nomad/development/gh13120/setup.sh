#!/usr/bin/env bash

set -e

function setup() {

  NOMAD_BINARY=$1

  # If the path to the Nomad binary was not provided, default to using the
  # $PATH.
  if [[ -z "$NOMAD_BINARY" ]];
  then
    NOMAD_BINARY="nomad"
  fi

  # The bootstrap token is generated for this use only, and therefore safe to
  # have in GitHub.
  $NOMAD_BINARY acl bootstrap ./acl_bootstrap_token
  $NOMAD_BINARY acl policy apply engineering-read ./acl_policy_engineering_read.hcl

  # Role which contains all policies to assign to engineers.
  $NOMAD_BINARY acl role create \
     -name=engineering-read \
     -policy=engineering-read \

  # Create the authentication method for Auth0.
  $NOMAD_BINARY acl auth-method create \
    -default=true \
    -name=auth0 \
    -token-locality=global \
    -max-token-ttl="10m" \
    -type=oidc \
    -config @./acl_auth_method_auth0.json

  # Create the binding rules to evaluate OIDC claims into Nomad policies and
  # roles.
  $NOMAD_BINARY acl binding-rule create \
    -auth-method=auth0 \
    -bind-type=role \
    -bind-name="engineering-read" \
    -selector="engineering in list.roles"
}

setup "$@"
