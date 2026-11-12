terraform {
  required_version = "1.17.1"

  cloud {
    hostname = "192-168-252-2.jrasell.test"
    organization = "admin"

    workspaces {
      name = "admin"
    }
  }
}
  