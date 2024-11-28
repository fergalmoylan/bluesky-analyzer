# bluesky-analyzer

A platform for analyzing bluesky posts.


### Installation
- Ensure you have docker installed and running
- Inside the apps/ folder, clone the following repositories:
  - https://github.com/fergalmoylan/bluesky-post-aggregator
  - https://github.com/fergalmoylan/bluesky-scraper
- Create an ```OPENSEARCH_PASSWORD``` environment variable for your initial Opensearch password
- Run ```docker-compose up -d```

### Usage
- Access the Opensearch UI at ```localhost:5601``` to view reports
- Access the Grafana UI at ```localhost:3000``` to view Kafka metrics