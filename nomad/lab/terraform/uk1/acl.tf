resource "nomad_acl_policy" "nomad_autoscaler" {
  name        = "nomad-autoscaler"
  description = "work identify policy for the nomad-autoscaler"
  rules_hcl   = file("${path.module}/policy/nomad_autoscaler.hcl")

  job_acl {
    namespace = "platform-autoscaling"
    job_id    = "nomad-autoscaler"
    group     = "nomad-autoscaler"
    task      = "nomad-autoscaler"
  }
}
