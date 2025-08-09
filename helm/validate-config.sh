#!/bin/bash
# Configuration validation script

set -e

echo "🔍 Validating Helm configuration sync..."

# Check if source config files exist
echo "📁 Checking source config files..."
for file in "../BingusApi/config/appsettings.json" "../BingusApi/config/bingus_config.json"; do
    if [[ ! -f "$file" ]]; then
        echo "❌ Missing source config: $file"
        exit 1
    fi
    echo "✅ Found: $file"
done

# Validate JSON syntax in source files
echo "🔍 Validating source JSON syntax..."
for file in "../BingusApi/config/appsettings.json" "../BingusApi/config/bingus_config.json"; do
    if ! jq . "$file" > /dev/null 2>&1; then
        echo "❌ Invalid JSON in: $file"
        exit 1
    fi
    echo "✅ Valid JSON: $file"
done

# Test Helm template rendering
echo "🎯 Testing Helm template rendering..."
if ! helm template . --values values.yaml > /dev/null 2>&1; then
    echo "❌ Helm template rendering failed"
    exit 1
fi
echo "✅ Helm template renders successfully"

# Extract and validate generated config
echo "📋 Extracting generated configuration..."
helm template . --values values.yaml | grep -A 50 "appsettings.json:" | grep -A 50 "|" | head -20

echo ""
echo "🎉 Configuration validation completed successfully!"
echo ""
echo "💡 To see the full merged configuration:"
echo "   helm template . --values values.yaml | grep -A 100 'appsettings.json:'"
