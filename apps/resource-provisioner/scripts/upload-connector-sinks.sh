#!/bin/bash
set -euo pipefail
set -x

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

sleep 10

log "Waiting for Kafka Connect at ${KAFKA_CONNECT_URL}..."
while true; do
  response=$(curl -s -w "\n%{http_code}" "${KAFKA_CONNECT_URL}/connectors")
  http_code=$(echo "$response" | tail -n1)
  response_body=$(echo "$response" | sed '$d')

  if [ "$http_code" -eq 200 ]; then
    log "Kafka Connect is up!"
    break
  else
    log "Kafka Connect not reachable yet. HTTP status code: $http_code"
    log "Response body: $response_body"
    log "Retrying in 5 seconds..."
    sleep 5
  fi
done
response=$(curl -s -w "\n%{http_code}" "${KAFKA_CONNECT_URL}/connectors")
response_body=$(echo "$response" | sed '$d')
log "Response from Kafka Connect connectors endpoint: $response_body"

existing_connectors=$(echo "$response_body" | jq -r '.[]' || echo "parse_error")

if [ "$existing_connectors" = "parse_error" ]; then
  log "Failed to parse the response from Kafka Connect. Response was:"
  log "$response_body"
  exit 1
fi

log "Uploading connector sinks..."
for file in /app/resources/connector-sinks/*.json; do
  if [ -f "$file" ]; then
    connector_name=$(jq -r '.name' "$file")
    if [ "$connector_name" = "null" ] || [ -z "$connector_name" ]; then
      log "Connector name not found in file '$file'. Skipping."
      continue
    fi

    if echo "$existing_connectors" | grep -q "^${connector_name}$"; then
      log "Connector '${connector_name}' already exists. Skipping."
    else
      log "Registering connector '${connector_name}' from file '${file}'..."
      response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        --data @"${file}" \
        "${KAFKA_CONNECT_URL}/connectors")
      if [ "$response" -eq 200 ] || [ "$response" -eq 201 ]; then
        log "Successfully registered connector '${connector_name}'."
      else
        log "Failed to register connector '${connector_name}'. HTTP response code: $response"
      fi
    fi
  else
    log "No JSON files found in /app/resources/connector-sinks/"
  fi
done

log "All connector sinks uploaded."

while true; do sleep 86400; done