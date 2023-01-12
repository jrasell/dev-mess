# Nomad SSO via OIDC
Nomad issue [#13120](https://github.com/hashicorp/nomad/issues/13120) detailed
the addition of SSO to Nomad via OIDC integration.

## Setup
- Replace the Auth0 customer information within the
  [Auth Method config file](./acl_auth_method_auth0.json)
- Nomad custom binary running with ACLs enabled (not bootstrapped)
- Execute the setup script with the path to the custom binary as the first
  argument such as `bash setup.sh  ./nomad/pkg/darwin_amd64/nomad`
