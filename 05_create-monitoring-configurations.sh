#!/usr/bin/env bash

# Create the Prometheus driver config
printf "*********************************************************************************\n"
printf "Create the Prometheus driver config\n"
printf "*********************************************************************************\n"

install -m 644 /dev/null ./mynetwork/shared/drivers/config.yml
cat <<EOF >./mynetwork/shared/drivers/config.yml
{}
EOF

printf "Created in: ./mynetwork/shared/drivers/config.yml\n\n"

# Create the Prometheus configuration
printf "*********************************************************************************\n"
printf "Create the Prometheus configuration\n"
printf "*********************************************************************************\n\n"

install -m 644 /dev/null ./mynetwork/prometheus/prometheus.yml
cat <<EOF >./mynetwork/prometheus/prometheus.yml
global:
  scrape_interval: 10s
  external_labels:
    monitor: "corda-network"
scrape_configs:
  - job_name: "notary"
    static_configs:
      - targets: ["notary:8080"]
    relabel_configs:
      - source_labels: [__address__]
        regex: "([^:]+):\\\d+"
        target_label: node
  - job_name: "nodes"
    static_configs:
      - targets: ["partya:8080", "partyb:8080"]
    relabel_configs:
      - source_labels: [__address__]
        regex: "([^:]+):\\\d+"
        target_label: node
EOF

printf "Created in: ./mynetwork/prometheus/prometheus.yml\n\n"

# Create the Promtail configuration
printf "*********************************************************************************\n"
printf "Create the Promtail configuration\n"
printf "*********************************************************************************\n\n"

install -m 644 /dev/null ./mynetwork/promtail/promtail-config.yaml
cat <<EOF >./mynetwork/promtail/promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: notary
    static_configs:
      - targets:
          - notary
        labels:
          __path__: /var/log/notary/*log
    relabel_configs:
      - source_labels: [__address__]
        target_label: node
  - job_name: partya
    static_configs:
      - targets:
          - partya
        labels:
          __path__: /var/log/partya/*log
    relabel_configs:
      - source_labels: [__address__]
        target_label: node
  - job_name: partyb
    static_configs:
      - targets:
          - partyb
        labels:
          __path__: /var/log/partyb/*log
    relabel_configs:
      - source_labels: [__address__]
        target_label: node
EOF

printf "Created in: ./mynetwork/promtail/promtail-config.yaml\n\n"

printf "*********************************************************************************\n"
printf "COMPLETE\n"
printf "*********************************************************************************\n"

# Create the Loki configuration
printf "*********************************************************************************\n"
printf "Create the Loki configuration\n"
printf "*********************************************************************************\n\n"

install -m 644 /dev/null ./mynetwork/loki/loki-config.yaml
cat <<EOF >./mynetwork/loki/loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h       # Any chunk not receiving new logs in this time will be flushed
  max_chunk_age: 1h           # All chunks will be flushed when they hit this age, default is 1h
  chunk_target_size: 1048576  # Loki will attempt to build chunks up to 1.5MB, flushing first if chunk_idle_period or max_chunk_age is reached first
  chunk_retain_period: 30s    # Must be greater than index read cache TTL if using an index cache (Default index read cache TTL is 5m)
  max_transfer_retries: 0     # Chunk transfers disabled

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/boltdb-shipper-active
    cache_location: /tmp/loki/boltdb-shipper-cache
    cache_ttl: 24h         # Can be increased for faster performance over longer query periods, uses more disk space
    shared_store: filesystem
  filesystem:
    directory: /tmp/loki/chunks

compactor:
  working_directory: /tmp/loki/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s

ruler:
  storage:
    type: local
    local:
      directory: /tmp/loki/rules
  rule_path: /tmp/loki/rules-temp
  alertmanager_url: http://localhost:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
EOF

printf "Created in: ./mynetwork/loki/loki-config.yaml\n\n"

printf "*********************************************************************************\n"
printf "COMPLETE\n"
printf "*********************************************************************************\n"