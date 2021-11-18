variable "image" { default = "redis:3.2" }

job "gh11434" {
  datacenters = ["dc1"]
  priority    = 49
  group "cache" {
    count = 5
    task "redis" {
      driver = "docker"
      config {
        image = var.image
      }
      resources {
        cpu    = 5
        memory = 10
      }
    }
  }
}
