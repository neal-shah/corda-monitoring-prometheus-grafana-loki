#!/usr/bin/env bash

# Update node.conf
sed -i '' 's/#//' mynetwork/notary/node.conf
sed -i '' 's/#//' mynetwork/partya/node.conf
sed -i '' 's/#//' mynetwork/partyb/node.conf

# Create Docker-Compose File
printf "*********************************************************************************\n"
printf "Create Docker-Compose File\n"
printf "*********************************************************************************\n"

cat <<EOF >./mynetwork/docker-compose.yml
version: '3.3'

services:
  notarydb:
    hostname: notarydb
    container_name: notarydb
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: test

  partyadb:
    hostname: partyadb
    container_name: partyadb
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: test
  
  partybdb:
    hostname: partybdb
    container_name: partybdb
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: test

  notary:
    hostname: notary
    container_name: notary
    image: corda/corda-zulu-java1.8-4.7:RELEASE
    ports:
      - "10002:10201"
    command: bash -c "java -jar /opt/corda/bin/corda.jar run-migration-scripts -f /etc/corda/node.conf --core-schemas --app-schemas && /opt/corda/bin/run-corda"
    volumes:
      - ./notary/node.conf:/etc/corda/node.conf:ro
      - ./notary/certificates:/opt/corda/certificates:ro
      - ./notary/persistence.mv.db:/opt/corda/persistence/persistence.mv.db:rw
      - ./notary/persistence.trace.db:/opt/corda/persistence/persistence.trace.db:rw
      - ./notary/logs:/opt/corda/logs:rw
      - ./shared/additional-node-infos:/opt/corda/additional-node-infos:rw
      - ./shared/drivers:/opt/corda/drivers:ro
      - ./shared/network-parameters:/opt/corda/network-parameters:rw
    environment:
      - "JVM_ARGS=-javaagent:/opt/corda/drivers/jmx_prometheus_javaagent-0.13.0.jar=8080:/opt/corda/drivers/config.yml"
    depends_on:
      - notarydb

  partya:
    hostname: partya
    container_name: partya
    image: corda/corda-zulu-java1.8-4.7:RELEASE
    ports:
      - "10005:10201"
      - "2222:2222"
    command: bash -c "java -jar /opt/corda/bin/corda.jar run-migration-scripts -f /etc/corda/node.conf --core-schemas --app-schemas && /opt/corda/bin/run-corda"
    volumes:
      - ./partya/node.conf:/etc/corda/node.conf:ro
      - ./partya/certificates:/opt/corda/certificates:ro
      - ./partya/persistence.mv.db:/opt/corda/persistence/persistence.mv.db:rw
      - ./partya/persistence.trace.db:/opt/corda/persistence/persistence.trace.db:rw
      - ./partya/logs:/opt/corda/logs:rw
      - ./shared/additional-node-infos:/opt/corda/additional-node-infos:rw
      - ./shared/cordapps:/opt/corda/cordapps:rw
      - ./shared/drivers:/opt/corda/drivers:ro
      - ./shared/network-parameters:/opt/corda/network-parameters:rw
    environment:
      - "JVM_ARGS=-javaagent:/opt/corda/drivers/jmx_prometheus_javaagent-0.13.0.jar=8080:/opt/corda/drivers/config.yml"
    depends_on:
      - partyadb

  partyb:
    hostname: partyb
    container_name: partyb
    image: corda/corda-zulu-java1.8-4.7:RELEASE
    ports:
      - "10008:10201"
      - "3333:2222"
    command: bash -c "java -jar /opt/corda/bin/corda.jar run-migration-scripts -f /etc/corda/node.conf --core-schemas --app-schemas && /opt/corda/bin/run-corda"
    volumes:
      - ./partyb/node.conf:/etc/corda/node.conf:ro
      - ./partyb/certificates:/opt/corda/certificates:ro
      - ./partyb/persistence.mv.db:/opt/corda/persistence/persistence.mv.db:rw
      - ./partyb/persistence.trace.db:/opt/corda/persistence/persistence.trace.db:rw
      - ./partyb/logs:/opt/corda/logs:rw
      - ./shared/additional-node-infos:/opt/corda/additional-node-infos:rw
      - ./shared/cordapps:/opt/corda/cordapps:rw
      - ./shared/drivers:/opt/corda/drivers:ro
      - ./shared/network-parameters:/opt/corda/network-parameters:rw
    environment:
      - "JVM_ARGS=-javaagent:/opt/corda/drivers/jmx_prometheus_javaagent-0.13.0.jar=8080:/opt/corda/drivers/config.yml"
    depends_on:
      - partybdb

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - 9090:9090
    command:
      - --config.file=/etc/prometheus/prometheus.yml
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro

  grafana:
    hostname: grafana
    container_name: grafana
    image: grafana/grafana:latest
    ports:
      - 3000:3000
    volumes:
      - grafana-storage:/var/lib/grafana
    environment:
      - "GF_INSTALL_PLUGINS=grafana-clock-panel"

  loki:
    image: grafana/loki:2.0.0
    container_name: loki
    hostname: loki
    ports:
      - "3100:3100"
    volumes:
     - ./loki/loki-config.yaml:/etc/loki/local-config.yaml
    command: -config.file=/etc/loki/local-config.yaml

  promtail:
    container_name: promtail
    hostname: promtail
    image: grafana/promtail:2.0.0
    volumes:
      - ./partya/logs:/var/log/partya:ro
      - ./partyb/logs:/var/log/partyb:ro
      - ./notary/logs:/var/log/notary:ro
      - ./promtail/promtail-config.yaml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml
  
volumes:
  grafana-storage:
EOF

printf "Created in: ./mynetwork/docker-compose.yml\n"

printf "Run command: docker-compose -f ./mynetwork/docker-compose.yml up -d\n\n"

printf "*********************************************************************************\n"
printf "COMPLETE\n"
printf "*********************************************************************************\n"