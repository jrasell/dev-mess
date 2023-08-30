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

  # Set the bootstrap token so all management API calls succeed.
  NOMAD_TOKEN=$(cat acl_bootstrap_token)
  export NOMAD_TOKEN

  # Create the non-default namespace referenced by the ACL policies.
  $NOMAD_BINARY namespace apply jrasell

  $NOMAD_BINARY acl policy apply namespace-default-read ./acl_policy_namespace_default_read.hcl
  $NOMAD_BINARY acl policy apply namespace-jrasell-read ./acl_policy_namespace_jrasell_read.hcl
  $NOMAD_BINARY acl policy apply namespace-jrasell-write ./acl_policy_namespace_jrasell_write.hcl

  # Create two ACL roles which provide slightly different permissions.
  $NOMAD_BINARY acl role create \
     -name=my-role-sre \
     -policy=namespace-default-read \
     -policy=namespace-jrasell-write

  $NOMAD_BINARY acl role create \
     -name=my-role \
     -policy=namespace-default-read \
     -policy=namespace-jrasell-read

  # Register our example job which will be used to test ACL token permissions.
  $NOMAD_BINARY job run -namespace=jrasell ./example.nomad.hcl
}

setup "$@"
