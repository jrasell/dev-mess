variable "image" { default = "redis:3.2" }
variable "count" { default = 3 }

job "gh10727" {
  update {
    max_parallel = 2
    auto_promote = true
    canary       = 1
  }
  datacenters = ["dc1"]
  group "cache" {
    count = var.count
    task "redis" {
      driver = "docker"
      config {
        image = var.image
      }
    }
  }
}
