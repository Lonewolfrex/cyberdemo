#!/bin/bash

# Download OpenSearch
wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.0.0/opensearch-2.0.0-linux-x64.tar.gz
# Replace 2.0.0 with the latest version number

# Extract OpenSearch
tar -xzf opensearch-2.0.0-linux-x64.tar.gz

# Move OpenSearch to a suitable directory
sudo mv opensearch-2.0.0 /usr/local/opensearch

# Navigate to the configuration directory
cd /usr/local/opensearch/config

# Backup original opensearch.yml
sudo cp opensearch.yml opensearch.yml.bak

# Update opensearch.yml
sudo bash -c 'cat <<EOL > opensearch.yml
cluster.name: "my-cluster"
node.name: "node-1"
network.host: 0.0.0.0
http.port: 9200

# Disable security features if not needed
plugins.security.disabled: true

# Set initial master nodes for single node setup
discovery.seed_hosts: ["localhost"]
cluster.initial_master_nodes: ["node-1"]

# Configure JVM options for memory settings
EOL'

# Set JVM heap size in jvm.options
echo "-Xms128m" | sudo tee -a /usr/local/opensearch/config/jvm.options
echo "-Xmx128m" | sudo tee -a /usr/local/opensearch/config/jvm.options

# Start OpenSearch
cd /usr/local/opensearch/
./bin/opensearch &

# Check if OpenSearch is running
sleep 60  # Wait for a moment to let it start
response=$(curl -s -o /dev/null -w "%{http_code}" 'http://localhost:9200')
if [ "$response" -eq 200 ]; then
    echo "OpenSearch is running successfully."
else
    echo "Failed to connect to OpenSearch. HTTP response code: $response"
    exit 1
fi

# Check logs for any errors (optional)
if [ -f /usr/local/opensearch/logs/opensearch.log ]; then
    echo "OpenSearch logs:"
    tail -n 10 /usr/local/opensearch/logs/opensearch.log
else
    echo "Log file not found."
fi