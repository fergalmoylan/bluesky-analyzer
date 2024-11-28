FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    bash \
 && rm -rf /var/lib/apt/lists/*


RUN mkdir -p /app/resources \
    /app/scripts

WORKDIR /app/scripts

CMD ["bash", "-c", "set -ex && chmod +x /app/scripts/* && ./upload-opensearch-objects.sh && ./upload-connector-sinks.sh"]