job "example" {
  namespace = "jrasell"
  group "cache" {
    task "redis" {
      driver = "docker"
      config {
        image = "redis:7"
      }
      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
