#!/bin/bash
# Config drift detection (for CI validation)

set -e

echo "🔍 Checking for config schema drift..."

# Ensure configs are copied
if [[ ! -f "configs/bingus_config.json" ]]; then
    echo "📋 Copying configs into chart..."
    ./copy-configs.sh
fi

# Extract current defaults from source files
CURRENT_BINGUS=$(jq -r 'keys[]' configs/bingus_config.json | sort)
CURRENT_APPSETTINGS=$(jq -r '.IpRateLimiting | keys[]' configs/appsettings.json | sort)

# Extract what Helm template expects (by parsing the template)
HELM_BINGUS=$(grep -o '\$defaultBingusConfig\.[a-zA-Z_]*' templates/api/configmap.yaml | sed 's/.*\.//' | sort | uniq)
HELM_APPSETTINGS=$(grep -o '\$defaultAppSettings\.IpRateLimiting\.[a-zA-Z_]*' templates/api/configmap.yaml | sed 's/.*\.//' | sort | uniq)

# Check for missing fields in Helm template
echo "📋 Checking bingus_config.json schema..."
MISSING_BINGUS=$(comm -23 <(echo "$CURRENT_BINGUS") <(echo "$HELM_BINGUS"))
if [[ -n "$MISSING_BINGUS" ]]; then
    echo "⚠️  New fields in bingus_config.json not handled by Helm:"
    echo "$MISSING_BINGUS"
    echo ""
    echo "💡 Consider updating helm/templates/api/configmap.yaml"
    exit 1
fi

echo "📋 Checking appsettings.json schema..."
MISSING_APPSETTINGS=$(comm -23 <(echo "$CURRENT_APPSETTINGS") <(echo "$HELM_APPSETTINGS"))
if [[ -n "$MISSING_APPSETTINGS" ]]; then
    echo "⚠️  New fields in appsettings.json not handled by Helm:"
    echo "$MISSING_APPSETTINGS"
    echo ""
    echo "💡 Consider updating helm/templates/api/configmap.yaml"
    exit 1
fi

# Test that template can render with current configs
echo "🎯 Testing template rendering..."
if ! helm template . --values values.yaml > /dev/null 2>&1; then
    echo "❌ Template rendering failed - possible schema incompatibility"
    exit 1
fi

echo "✅ Config schemas are in sync!"
