variable "node_pool" {
  type        = string
  default     = "all"
  description = "The node pool to target for this job"
}

variable "namespace" {
  description = "The Nomad namespace to deploy to"
  type        = string
  default     = "default"
}

variable "network_mode" {
  description = "The network mode to use"
  type        = string
  default     = "bridge"

  validation {
    condition     = (trimspace(var.network_mode) == "" || lower(trimspace(var.network_mode)) != "host")
    error_message = "The network mode \"host\" is not supported."
  }
}

variable "kafka_cluster_id" {
  description = "The Kafka cluster ID to assign to the cluster."
  type        = string
  default     = "4L6g3nShT-eMCtK--X86sw"
}

job "kafka-dev" {
  type        = "service"
  node_pool   = var.node_pool
  namespace   = var.namespace

  group "kafka" {
    count = 1

    network {
      mode = var.network_mode
      port "broker-external" {
        to = 9092
      }
      port "broker-internal" {
        to = 19092
      }
      port "controller" {
        to = 29093
      }
    }

    service {
      name     = "kafka-broker-external"
      provider = "nomad"
      port     = "broker-external"
    }

    task "broker" {
      driver = "docker"

      config {
        image = "apache/kafka:4.0.2"
      }

      env {
        KAFKA_NODE_ID                                          = "1"
        KAFKA_LISTENER_SECURITY_PROTOCOL_MAP                   = "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT"
        KAFKA_PROCESS_ROLES                                    = "broker,controller"
        KAFKA_INTER_BROKER_LISTENER_NAME                       = "PLAINTEXT"
        KAFKA_CONTROLLER_LISTENER_NAMES                        = "CONTROLLER"
        CLUSTER_ID                                             = var.kafka_cluster_id
        KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR                 = "1"
        KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS                 = "0"
        KAFKA_TRANSACTION_STATE_LOG_MIN_ISR                    = "1"
        KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR         = "1"
        KAFKA_SHARE_COORDINATOR_STATE_TOPIC_REPLICATION_FACTOR = "1"
        KAFKA_SHARE_COORDINATOR_STATE_TOPIC_MIN_ISR            = "1"
        KAFKA_LOG_DIRS                                         = "/tmp/kraft-combined-logs"
      }

      template {
        destination = "local/kafka.env"
        env         = true
        change_mode = "restart"

        data = <<-EOT
KAFKA_LISTENERS=CONTROLLER://{{ env "NOMAD_ALLOC_ADDR_controller" }},PLAINTEXT_HOST://{{ env "NOMAD_ALLOC_ADDR_broker-external" }},PLAINTEXT://{{ env "NOMAD_ALLOC_ADDR_broker-internal" }}
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT_HOST://{{ env "NOMAD_ALLOC_ADDR_broker-external" }},PLAINTEXT://{{ env "NOMAD_ALLOC_ADDR_broker-internal" }}
KAFKA_CONTROLLER_QUORUM_VOTERS=1@{{ env "NOMAD_ALLOC_ADDR_controller" }}
EOT
      }

      resources {
        cpu    = 500
        memory = 1024
      }
    }
  }
}
