#!/bin/bash
# Copy source configs into chart for packaging

set -e

echo "copying source configs into helm/configs..."

# Create configs directory in chart
mkdir -p configs/

# Copy source configs
cp ../BingusApi/config/appsettings.json configs/
cp ../BingusApi/config/bingus_config.json configs/

echo "configs copied to helm/configs"
