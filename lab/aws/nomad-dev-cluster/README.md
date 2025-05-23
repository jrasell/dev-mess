# Nomad Development Cluster


```
$ vault server \
  -dev \
  -dev-root-token-id=c94fc92e-4799-43fe-ba7c-d1bbe601b5e2 \
  -dev-listen-address=$(hostname -i |awk '{print $1}'):8200 \
  -log-level=trace
```

```
sudo -i nomad agent \
  -config=/home/jrasell/nomad_server.hcl \
  -config=/home/jrasell/nomad_vault.hcl
```

```
export VAULT_ADDR=http://$(hostname -i |awk '{print $1}'):8200
export VAULT_TOKEN=c94fc92e-4799-43fe-ba7c-d1bbe601b5e2
export NOMAD_ADDR=http://$(hostname -i |awk '{print $1}'):4646
export NOMAD_TOKEN=b6e63b6a-527c-14db-9474-063cb1dcc026
```

```
nomad acl bootstrap /home/jrasell/root_bootstrap_token
```

```
nomad setup vault \
  -y \
  -jwks-url=http://$(hostname -i |awk '{print $1}'):4646/.well-known/jwks.json
```

```
sudo -i nomad agent \
  -config=/home/jrasell/nomad_client.hcl \
  -config=/home/jrasell/nomad_vault.hcl
```


```
vault kv put -mount 'secret' 'default/mongo/config' 'root_password=secret-password'
```

```
job "mongo" {
  namespace = "default"

  group "db" {
    network {
      port "db" {
        static = 27017
      }
    }

    service {
      provider = "nomad"
      name     = "mongo"
      port     = "db"
    }

    task "mongo" {
      driver = "docker"

      config {
        image = "mongo:7"
        ports = ["db"]
      }

      vault {}

      template {
        data        = <<EOF
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD={{with secret "secret/data/default/mongo/config"}}{{.Data.data.root_password}}{{end}}
EOF
        destination = "secrets/env"
        env         = true
      }
    }
  }
}
```