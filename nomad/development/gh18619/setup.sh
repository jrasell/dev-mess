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
  $NOMAD_BINARY namespace apply monitoring
  $NOMAD_BINARY namespace apply system

  $NOMAD_BINARY acl policy apply namespace-monitoring-admin ./acl_policy_namespace_monitoring_admin.hcl
  $NOMAD_BINARY acl policy apply namespace-system-admin ./acl_policy_namespace_system_admin.hcl

  # Create two ACL roles which provide slightly different permissions.
  $NOMAD_BINARY acl role create \
     -name=my-role-sre \
     -policy=namespace-monitoring-admin \
     -policy=namespace-system-admin

  # Register our example job which will be used to test ACL token permissions.
  $NOMAD_BINARY job run -namespace=system ./example.nomad.hcl
}

setup "$@"
