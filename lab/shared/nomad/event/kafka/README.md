# Kafka
URL: https://kafka.apache.org
Docs: https://kafka.apache.org/43/getting-started/introduction/

Apache Kafka is an open-source distributed event streaming platform used for high-performance data
pipelines, streaming analytics, and data integration.

### kafka-dev
The `kafka-dev` job deploys a single-node Kafka cluster for development and testing purposes.

### kafka-ha
The `kafka-ha` job deploys a highly available Kafka cluster. Each Kafka instance runs as a broker
and controller, using Raft as the consensus mechanism. Each broker discovers the other brokers using
the Nomad service discovery mechanism and forms a cluster. 

By default the job does not configure persistent storage and the brokers will store their data in
the allocation directory. To run with persistent storage via dynamic host volumes, the following
volumes can be created:
```console
nomad volume create ./volumes/dhv-mkdir-k1.hcl
nomad volume create ./volumes/dhv-mkdir-k2.hcl
nomad volume create ./volumes/dhv-mkdir-k3.hcl
```

To run the job with persistent storage, the `kafka-ha` job can be submitted with the `-var` flag to specify the volume names. Otherwise, omitting the `-var` flag will run the job with ephemeral storage in the allocation:
```console
nomad job run \
  -var "enable_host_volume=true" \
  kafka-ha.nomad.hcl
```

### kafka-ui
The `kafka-ui` job deploys the Kafka UI, which is a web-based user interface for managing and
monitoring Kafka clusters. No native UI exists, so this job deploys the open-source
[Kafka UI](https://github.com/provectus/kafka-ui) from Provectus.
