plugin "docker" {
  config {
    allow_privileged = true
    volumes {
      enabled = true
    }
  }
}