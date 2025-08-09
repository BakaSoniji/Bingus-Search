# Configuration Synchronization Strategy

## Overview

This Helm chart implements a **smart defaulting system** that automatically keeps configuration schemas in sync with upstream changes while allowing selective overrides.

## How It Works

### 1. Automatic Schema Sync
- Source configs are copied into chart via `./copy-configs.sh`
- Helm templates read from `configs/*.json` (copied files)
- Schema changes upstream are reflected when configs are copied

### 2. Selective Overrides
- Helm values are **optional** overrides only
- Use `| default $actualConfigValue` pattern
- Only specify values you want to change

### 3. Kubernetes-Specific Overrides
Some values need Kubernetes-specific changes:
- `api_uri`: Points to Kubernetes service names
- Service discovery URLs
- Resource limits/requests

## File Structure

```
BingusApi/config/
├── appsettings.json      # Source of truth for .NET config
├── bingus_config.json    # Source of truth for Bingus config
└── faq_config.json       # Application data (not in ConfigMap)

helm/
├── values.yaml           # Optional overrides only
├── copy-configs.sh       # Copy source configs into chart
├── configs/              # Auto-generated (gitignored)
│   ├── appsettings.json  # ← Copied from source
│   └── bingus_config.json # ← Copied from source
└── templates/api/
    └── configmap.yaml    # Smart merge logic
```

## Usage Examples

### Default Behavior (Recommended)
```bash
# Copy latest configs into chart
cd helm && ./copy-configs.sh
```

```yaml
# values.yaml
api:
  config:
    bingus:
      apiUri: "http://bingus-encoder:5000"  # Override for k8s
      # All other values use defaults from configs/bingus_config.json
```

### Custom Overrides
```yaml
# values.yaml
api:
  config:
    logLevel: "Debug"
    bingus:
      encoderType: "custom"
      apiUri: "http://bingus-encoder:5000"
    rateLimiting:
      enabled: false
```

## Validation

Run `helm template` to validate the merged configuration:

```bash
helm template . --values values.yaml | grep -A 20 "appsettings.json"
```

## FAQ Data Handling

`faq_config.json` is **application data**, not configuration:
- Not included in ConfigMaps
- Should be managed via API endpoints
- Consider external data sources (database, CMS, etc.)
