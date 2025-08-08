# 🔧 Environment Configuration for GitHub Actions

This document explains how to configure the GitHub Actions workflows for your fork or deployment environment.

## Release Process (CalVer + Cloudflare)

This fork uses a simple, automated release pipeline:

- Versioning: CalVer `vYYYY.MM.P` (e.g., `v2025.08.0`), auto-incremented on each push to `main`.
- Pipeline: On push to `main`, GitHub Actions will:
    - Build and push containers for `encoder`, `api`, and `bot` with tags `latest` and `vYYYY.MM.P`.
    - Update and package the Helm chart (`helm/`) with the same CalVer version and publish to OCI.
    - Create a GitHub Release with a generated changelog.
    - Optionally deploy the frontend to Cloudflare R2 (enable via repo variable `ENABLE_FRONTEND_DEPLOYMENT=true`).

### Configure Cloudflare Frontend Deployment (optional)

Set the following in GitHub → Settings → Secrets and variables:

- Variables:
    - `ENABLE_FRONTEND_DEPLOYMENT=true`
    - `CLOUDFLARE_R2_BUCKET_NAME=<your-bucket>`
    - `FRONTEND_API_BASE_URL=<your-api>` (optional; defaults to code’s built-in URL)
    - `CLOUDFLARE_ZONE_ID` (optional, for cache purging)
- Secrets:
    - `CLOUDFLARE_API_TOKEN`
    - `CLOUDFLARE_ACCOUNT_ID`

The frontend code defaults to `https://bingus.slimevr.io`. To override, set `FRONTEND_API_BASE_URL`.

## 📋 **Repository Variables**

Configure these in your repository settings under **Settings > Secrets and variables > Actions > Variables**:

### **Cloudflare Deployment**
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ENABLE_FRONTEND_DEPLOYMENT` | No | `false` | Set to `true` to enable Cloudflare deployment |
| `FRONTEND_API_BASE_URL` | Yes* | - | Base URL for API calls from frontend (overrides code default) |
| `FRONTEND_CUSTOM_DOMAIN` | No | - | Your custom domain for frontend (optional) |
| `CLOUDFLARE_R2_BUCKET_NAME` | Yes* | - | R2 bucket name for static hosting |
| `CLOUDFLARE_ZONE_ID` | No | - | Zone ID for cache purging (optional) |

*Required if Cloudflare deployment is enabled. For GitHub Pages (upstream `frontend.yml`), this is not used.

### **Container Builds**
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ENABLE_CONTAINER_BUILDS` | No | `true` | Set to `false` to disable container builds |
| `CUSTOM_REGISTRY` | No | - | Override default registry (ghcr.io) |

### **Releases**
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ENABLE_RELEASES` | No | `true` | Set to `false` to disable release workflow |
| `ENABLE_HELM_PUBLISHING` | No | `true` | Set to `false` to disable Helm chart publishing |

## 🔐 **Repository Secrets**

Configure these in your repository settings under **Settings > Secrets and variables > Actions > Secrets**:

### **Frontend Deployment (Cloudflare R2)**
| Secret | Required | Description |
|--------|----------|-------------|
| `CLOUDFLARE_API_TOKEN` | Yes* | Cloudflare API token with R2 and Zone permissions |
| `CLOUDFLARE_ACCOUNT_ID` | Yes* | Your Cloudflare account ID |

*Required if frontend deployment is enabled

### **Container Registry (Optional)**
| Secret | Required | Description |
|--------|----------|-------------|
| `CUSTOM_REGISTRY_USERNAME` | No | Username for custom container registry |
| `CUSTOM_REGISTRY_PASSWORD` | No | Password/token for custom container registry |

## 🚀 **Quick Setup Examples**

### **For Personal Forks (Minimal Setup)**
```bash
# Disable deployments, keep CI for development
ENABLE_FRONTEND_DEPLOYMENT=false
ENABLE_CONTAINER_BUILDS=true  # Still build containers locally
ENABLE_RELEASES=false         # Don't publish releases
```

### **For Production Deployment**
```bash
# Full deployment setup - replace with your actual values
ENABLE_FRONTEND_DEPLOYMENT=true
# FRONTEND_API_BASE_URL overrides the code default (https://bingus.slimevr.io)
FRONTEND_API_BASE_URL=https://api.example.com
FRONTEND_CUSTOM_DOMAIN=search.example.com  # optional
CLOUDFLARE_R2_BUCKET_NAME=my-frontend-bucket
ENABLE_CONTAINER_BUILDS=true
ENABLE_RELEASES=true
ENABLE_HELM_PUBLISHING=true
```

### **For Custom Infrastructure**
```bash
# Use custom registry and disable GitHub-specific features
CUSTOM_REGISTRY=registry.example.com
ENABLE_HELM_PUBLISHING=false  # Use your own Helm repo
ENABLE_FRONTEND_DEPLOYMENT=false  # Deploy via your own pipeline
```

## ⚠️ **Important: Fail-Fast Configuration**

**If deployment is enabled but misconfigured, workflows will fail immediately with clear error messages.**

This is intentional to prevent:
- ❌ Silent failures with wrong configuration
- ❌ Deploying to wrong environments
- ❌ Builds with missing required settings

**Example error messages:**
```bash
❌ CLOUDFLARE_API_TOKEN secret is required
❌ FRONTEND_API_BASE_URL variable is required (only for Cloudflare deployment)
❌ Validation failed: Missing required configuration
```

## 🌐 **Frontend API URL Defaults & Overrides**

- The frontend code has a built-in default API URL: `https://bingus.slimevr.io`.
- Upstream GitHub Pages workflow (`frontend.yml`) does not set any API env; it uses the code default.
- The Cloudflare deployment workflow (`cloudflare-deploy.yml`) expects `FRONTEND_API_BASE_URL` to be set to explicitly override the default.
- If you prefer to rely on the code default for Cloudflare as well, remove the validation step and the `VITE_API_BASE_URL` env in `cloudflare-deploy.yml`.

## 📝 **Workflow Behavior**

### **With No Configuration (Fork Default)**
- ✅ **dotnet.yml**: Runs basic .NET CI
- ✅ **codeql.yml**: Runs security scanning
- ❌ **frontend.yml**: Skipped (not SlimeVR repo)
- ✅ **ci-containers.yml**: Builds containers (build-only, no push on feature branches)
- ❌ **release.yml**: Skipped (no releases enabled)

### **With Full Configuration**
- ✅ **All workflows run successfully**
- 🚀 **Frontend deploys to Cloudflare R2 (as part of release)**
- 📦 **Containers push to registry**
- 🎯 **Releases create GitHub releases + Helm charts**

## 🏗️ **Container Build Strategy**

The container builds are now optimized for efficiency:

### **📋 When Containers Are Built:**
- ✅ **Code changes** to any service (encoder, api, bot, helm)
- ✅ **Dockerfile changes** or dependency updates
- ❌ **Documentation-only changes** (skipped entirely)

### **📦 When Images Are Pushed to Registry:**
- ✅ **Main branch** - Always push (deployable images)
- ✅ **Release/tags** - Always push (production ready)
- ❌ **Feature branches** - Build-only validation (no registry bloat)
- ❌ **Pull requests** - Build-only validation

### **💡 Benefits:**
- **Faster feedback** - Quick Docker validation on all changes
- **Registry efficiency** - Only deployable images are stored
- **Resource savings** - Skip builds for docs-only changes
- **Branch testing** - Can still build locally when needed

## 🛠️ **Cloudflare R2 Setup**

1. **Create R2 Bucket**:
   ```bash
   # In Cloudflare dashboard
   R2 Object Storage > Create Bucket > your-frontend-bucket
   ```

2. **Create API Token**:
   ```bash
   # Permissions needed:
   - Account:Cloudflare R2:Edit
   - Zone:Zone:Read (if using cache purging)
   - Zone:Cache Purge:Edit (if using cache purging)
   ```

3. **Configure Custom Domain** (Optional):
   ```bash
   # In R2 bucket settings
   Settings > Custom Domains > Connect Domain
   ```

## 🔍 **Troubleshooting**

### **Container Builds Fail**
- Check `GITHUB_TOKEN` has packages write permission
- Verify repository has container registry enabled
- Set `ENABLE_CONTAINER_BUILDS=false` to disable

### **Frontend Deployment Fails**
- Verify all Cloudflare secrets are set correctly
- Check R2 bucket exists and API token has permissions
- Review build logs for specific errors

### **Helm Publishing Fails**
- Ensure `GITHUB_TOKEN` has packages write permission
- Check OCI registry access in repository settings
- Set `ENABLE_HELM_PUBLISHING=false` to disable

## 🤔 **Need Help?**

1. Check the [GitHub Actions logs](../../actions) for specific error messages
2. Review the [Cloudflare R2 documentation](https://developers.cloudflare.com/r2/)
3. Open an issue with your configuration (remove sensitive values!)

---
