#!/bin/bash
set -e

# Unzip the plugin
unzip /var/lib/grafana/plugins/hamedkarbasi93-kafka-datasource-0.2.0.zip -d /var/lib/grafana/plugins/
#sleep 30
#rm /var/lib/grafana/plugins/hamedkarbasi93-kafka-datasource-0.2.0.zip

# Start Grafana
exec grafana-server