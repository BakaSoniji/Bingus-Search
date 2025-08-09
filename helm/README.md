# Bingus-Search Helm Chart

## Quick Start

```bash
# Deploy with defaults
helm install bingus-search . --values values.yaml

# Override specific configs
helm install bingus-search . --values values.yaml \
  --set api.config.logLevel="Debug" \
  --set api.config.bingus.encoderType="custom"
```

## Configuration Validation

This chart uses [config sync](./CONFIG-SYNC.md) that automatically sync with upstream config files.

### Before Making Changes

**Always run validation before committing:**

```bash
cd helm
./copy-configs.sh      # Copy source configs into chart
./validate-config.sh   # Validate everything works
```

### If Validation Fails

**Schema drift detected?**
```bash
# 1. Check what's missing
./check-config-drift.sh

# 2. Update templates manually
# Edit: templates/api/configmap.yaml

# 3. Test the fix
./validate-config.sh

# 4. Commit and push
```

**Template errors?**
```bash
# Debug template rendering
helm template . --values values.yaml --debug

# Check JSON syntax
jq . ../BingusApi/config/appsettings.json
jq . ../BingusApi/config/bingus_config.json
```

## How Smart Defaults Work

### 🎯 **Override Only What You Need**
```yaml
# values.yaml (minimal example)
api:
  config:
    bingus:
      apiUri: "http://bingus-encoder:5000"  # K8s service name
      # All other values use defaults from ../BingusApi/config/bingus_config.json
```

### 📁 **Files Overview**
```
BingusApi/config/
├── appsettings.json      # ✅ Source of truth (.NET config)
├── bingus_config.json    # ✅ Source of truth (Bingus config)
└── faq_config.json       # ❌ Application data (not in Helm)

helm/
├── values.yaml           # Optional overrides only
├── copy-configs.sh       # Copy source configs into chart
├── validate-config.sh    # Validation script
├── check-config-drift.sh # Schema drift detection
├── configs/              # Auto-generated (gitignored)
│   ├── appsettings.json  # ← Copied from source
│   └── bingus_config.json # ← Copied from source
└── templates/api/
    └── configmap.yaml    # Smart merge logic
```

## CI Integration

All workflows validate config sync **before** building:

```yaml
# Automatic validation in CI
- validate-config     # ← Runs first
- build-containers    # ← Only if validation passes
- create-release      # ← Only if validation passes
```

### When CI Fails

```bash
❌ Configuration schema drift detected!

🔧 To fix this issue:
   1. Run: cd helm && ./check-config-drift.sh
   2. Update helm/templates/api/configmap.yaml with missing fields
   3. Test: ./validate-config.sh
   4. Commit and push changes
```

## Development Workflow

1. **Change config files** → `BingusApi/config/*.json`
2. **Run validation** → `cd helm && ./validate-config.sh`
3. **Fix any drift** → Update `templates/api/configmap.yaml`
4. **Test deployment** → `helm template . --values values.yaml`
5. **Commit & push** → CI validates automatically

## Advanced Usage

### Custom Value Files

```bash
# Production
helm install bingus-search . -f values.yaml -f values-prod.yaml

# Development
helm install bingus-search . -f values.yaml -f values-dev.yaml
```

### Debugging

```bash
# See final merged config
helm template . --values values.yaml | grep -A 100 "appsettings.json:"

# Test specific overrides
helm template . --set api.config.logLevel="Debug" --values values.yaml
```
