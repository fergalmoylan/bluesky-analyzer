#!/bin/bash
set -euo pipefail
set -x

# Minimal logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Wait until OpenSearch is reachable
log "Waiting for OpenSearch cluster at ${OPENSEARCH_URL} to be ready..."
while true; do
  health_response=$(curl -u "${OPENSEARCH_USER}:${OPENSEARCH_PASSWORD}" $CURL_OPTIONS --silent --fail "${OPENSEARCH_URL}/_cluster/health" || echo "error")
  if [ "$health_response" = "error" ]; then
    log "No response from OpenSearch cluster health endpoint. Retrying in 5 seconds..."
  else
    health_status=$(echo "$health_response" | jq -r '.status')
    if [ "$health_status" = "green" ] || [ "$health_status" = "yellow" ]; then
      log "OpenSearch cluster is ready with status: $health_status."
      break
    else
      log "OpenSearch cluster status is '$health_status'. Waiting for it to be 'yellow' or 'green'..."
    fi
  fi
  sleep 5
done

# Upload index templates
log "Uploading index templates..."
for file in /app/resources/index-templates/*.json; do
  if [ -f "$file" ]; then
    template_name=$(basename "$file" .json)
    log "Uploading index template '${template_name}' from file '${file}'..."
    response=$(curl -u "${OPENSEARCH_USER}:${OPENSEARCH_PASSWORD}" $CURL_OPTIONS -s -o /dev/null -w "%{http_code}" -X PUT "${OPENSEARCH_URL}/_index_template/${template_name}" \
      -H 'Content-Type: application/json' \
      -d @"${file}")
    if [ "$response" -eq 200 ] || [ "$response" -eq 201 ]; then
      log "Successfully uploaded index template '${template_name}'."
    else
      log "Failed to upload index template '${template_name}'. HTTP response code: $response"
    fi
  else
    log "No JSON files found in /app/resources/index-templates/"
  fi
done

## Create placeholder index
#log "Creating placeholder index 'your-index-name'..."
#response=$(curl -u "${OPENSEARCH_USER}:${OPENSEARCH_PASSWORD}" $CURL_OPTIONS \
#  -s -X PUT "${OPENSEARCH_URL}/language-clusters-placeholder" \
#  -H 'Content-Type: application/json' \
#  -d '{}')

log "Placeholder index 'language-clusters-placeholder' created."

# Wait until OpenSearch Dashboards is reachable
log "Waiting for OpenSearch Dashboards at ${OPENSEARCH_DASHBOARDS_URL} to be ready..."
until curl -s -u "${OPENSEARCH_USER}:${OPENSEARCH_PASSWORD}" "${OPENSEARCH_DASHBOARDS_URL}/api/status" | grep -q "\"state\":\"green\""
do
  log "OpenSearch Dashboards not ready yet. Retrying in 5 seconds..."
  sleep 5
done
log "OpenSearch Dashboards is up and ready!"

# Upload dashboards
log "Uploading dashboards..."
for file in /app/resources/opensearch-dashboards/*.ndjson; do
  if [ -f "$file" ]; then
    log "Uploading dashboard from file '${file}'..."
    response=$(curl -u "${OPENSEARCH_USER}:${OPENSEARCH_PASSWORD}" \
      -s -X POST "${OPENSEARCH_DASHBOARDS_URL}/api/saved_objects/_import?overwrite=true" \
      -H "osd-xsrf: true" \
      -H "securitytenant: global" \
      -H 'Content-Type: multipart/form-data' \
      -F file=@"${file}" \
      -w "\n%{http_code}")

    # Separate HTTP status code and response body
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')

    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
      log "Successfully uploaded dashboard from '${file}'. Response body: $response_body"
    else
      log "Failed to upload dashboard from '${file}'. HTTP response code: $http_code, Response body: $response_body"
    fi
  else
    log "No NDJSON files found in /app/resources/opensearch-dashboards/"
  fi
done

log "All Opensearch tasks completed."
