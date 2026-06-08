# Victoria Metrics
URL: https://victoriametrics.com
Docs: https://docs.victoriametrics.com

Victoria Metrics is a suite of monitoring solutions that includes a time-series database, a metrics
scraper, and visualization tools for metrics, logs, and traces.

### victoria-logs-standalone
The `victoria-logs-standalone` job deploys the Victoria Logs standalone binary, which is an
all-in-one logging solution that includes both the database and the log scraper. The HTTP endpoint
which serves the logs API and UI is registered as the `victoria-logs-http` for service discovery.

### victoria-metrics-standalone
The `victoria-metrics-standalone` job deploys the Victoria Metrics standalone binary, which is an
all-in-one metrics solution that includes both the database and the metrics scraper. The HTTP
endpoint which serves the metrics API and UI is registered as the `victoria-metrics-http` for
service discovery.

### vmagent-nomad
The `vmagent-nomad` job provides a way to periodically scrape metrics from the Nomad cluster and
send them to Victoria Metrics. It uses the `vmagent` binary, which is a lightweight agent designed
for scraping metrics and sending them to a remote storage such as Victoria Metrics. In order to
discover the Nomad agents, the job runs a discovery sidecar that queries the Nomad API and generates
a configuration file for `vmagent` to scrape periodically.

If ACLs are enabled in the Nomad cluster, the `vmagent-nomad` job will require a token with the
`read` capability on the `node` resource which is outside the workload identities default
capabilities. The [vmagent-nomad-discovery](./policies/vmagent-nomad-discovery.hcl) ACL policy can
be created and assigned to the job to provide the required elevated permissions:

```console
nomad acl policy apply \
   -namespace default \
   -job vmagent-nomad \
   -group vmagent \
   -task discover \
   vmagent-nomad-discovery ./policies/vmagent-nomad-discovery.hcl
```

The Nomad metrics endpoint is also protected by TLS which means the `vmagent` task needs the public
CA certificate. Assuming the CA certificate is stored at `.tls/ca.pem`, a variable can be written
to Nomad which will be read by the job using its workload identity:

```console
nomad var put \
  nomad/jobs/vmagent-nomad/vmagent \
  ca="$(cat .tls/ca.pem)"
```
