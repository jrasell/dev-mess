namespace "platform-autoscaling" {
  variables {
    path "nomad-autoscaler/lock" {
      capabilities = ["write"]
    }
  }
}

namespace "*" {
  policy = "scale"
}
