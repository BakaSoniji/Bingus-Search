# Bingus Helm Chart

A comprehensive Helm chart for deploying the Bingus search application on Kubernetes.

## Overview

Bingus is a multi-service search application consisting of:
- **Encoder Service**: Handles text embedding and vector operations
- **API Service**: Provides REST API for search functionality
- **Bot Service**: Discord bot integration for interactive search

## Prerequisites

- Kubernetes 1.20+
- Helm 3.8+
- Traefik ingress controller (for web access)
- Persistent storage support (for caches and data)

## Installation

### Quick Start

```bash
# Add the repository (when published)
helm repo add bingus oci://ghcr.io/bakasoniji/bingus-search/helm

# Install with default values
helm install bingus bingus/bingus --create-namespace --namespace bingus
```

### From Source

```bash
# Clone the repository
git clone https://github.com/BakaSoniji/Bingus-Search.git
cd Bingus-Search

# Install the chart
helm install bingus ./helm --create-namespace --namespace bingus
```

### Custom Installation

```bash
# Install with custom values
helm install bingus ./helm \
  --create-namespace \
  --namespace bingus \
  --set api.ingress.hostname=search.yourdomain.com \
  --set encoder.resources.limits.memory=8Gi \
  --set bot.secrets.discordToken=your-discord-token
```

## Configuration

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Target namespace | `bingus` |
| `global.createNamespace` | Create namespace if it doesn't exist | `true` |
| `global.registry` | Container registry prefix | `""` (unset) |

### Encoder Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `encoder.enabled` | Enable encoder service | `true` |
| `encoder.replicaCount` | Number of replicas | `1` |
| `encoder.image.tag` | Image tag | `latest` |
| `encoder.resources.limits.memory` | Memory limit | `4Gi` |
| `encoder.resources.limits.cpu` | CPU limit | `2000m` |
| `encoder.persistence.modelCache.size` | Model cache storage size | `10Gi` |
| `encoder.persistence.embeddingCache.size` | Embedding cache size | `5Gi` |
| `encoder.config.modelName` | Sentence transformer model | `sentence-transformers/all-MiniLM-L6-v2` |

### API Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `api.enabled` | Enable API service | `true` |
| `api.replicaCount` | Number of replicas | `1` |
| `api.image.tag` | Image tag | `latest` |
| `api.service.port` | Service port | `8080` |
| `api.ingress.enabled` | Enable ingress | `true` |
| `api.ingress.hostname` | Ingress hostname | `bingus.bakas.io` |
| `api.ingress.accessPolicy` | Access policy (public/private) | `public` |
| `api.persistence.size` | Data storage size | `2Gi` |

### Bot Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `bot.enabled` | Enable bot service | `true` |
| `bot.replicaCount` | Number of replicas | `1` |
| `bot.image.tag` | Image tag | `latest` |
| `bot.secrets.extraSecrets` | Additional secret key/values | `{}` |
| `bot.config.commandPrefix` | Bot command prefix | `!` |
| `bot.config.maxResultsPerSearch` | Max results per search | `10` |

### Security Context

| Parameter | Description | Default |
|-----------|-------------|---------|
| `securityContext.runAsUser` | User ID | `1001` |
| `securityContext.runAsGroup` | Group ID | `1001` |
| `securityContext.fsGroup` | Filesystem group | `1001` |
| `containerSecurityContext.allowPrivilegeEscalation` | Allow privilege escalation | `false` |

## Examples

### Production Configuration

```yaml
# values-prod.yaml
global:
  # Optional registry prefix (leave empty to use image names without prefix)
  registry: ghcr.io/youruser/bingus-search

encoder:
  replicaCount: 2
  resources:
    limits:
      memory: 8Gi
      cpu: 4000m
  persistence:
    modelCache:
      size: 50Gi
      storageClass: fast-ssd
    embeddingCache:
      size: 20Gi
      storageClass: fast-ssd

api:
  replicaCount: 3
  ingress:
    hostname: search.yourcompany.com
    accessPolicy: private  # Requires Cloudflare Access
  persistence:
    size: 10Gi
    storageClass: standard
  secrets:
    databaseUrl: postgresql://user:pass@postgres:5432/bingus

bot:
  secrets:
    discordToken: "your-production-bot-token"
  config:
    discordGuildId: "your-guild-id"
```

### Development Configuration

```yaml
# values-dev.yaml
encoder:
  resources:
    limits:
      memory: 2Gi
      cpu: 1000m
  persistence:
    modelCache:
      size: 5Gi
    embeddingCache:
      size: 2Gi

api:
  ingress:
    hostname: bingus-dev.bakas.io
  persistence:
    size: 1Gi

bot:
  secrets:
    discordToken: "your-dev-bot-token"
```

## Upgrading

```bash
# Upgrade to a new version
helm upgrade bingus ./helm --namespace bingus

# Upgrade with new values
helm upgrade bingus ./helm --namespace bingus -f values-prod.yaml
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall bingus --namespace bingus

# Optionally delete the namespace
kubectl delete namespace bingus
```

## Monitoring & Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n bingus
kubectl logs -f deployment/bingus-encoder -n bingus
kubectl logs -f deployment/bingus-api -n bingus
kubectl logs -f deployment/bingus-bot -n bingus
```

### Health Checks

```bash
# Check encoder health
kubectl port-forward svc/bingus-encoder 5000:5000 -n bingus
curl http://localhost:5000/health

# Check API health
kubectl port-forward svc/bingus-api 8080:8080 -n bingus
curl http://localhost:8080/health
```

### Storage

```bash
# Check persistent volumes
kubectl get pvc -n bingus
kubectl describe pvc bingus-encoder-model-cache -n bingus
```

## Architecture

```mermaid
graph TB
    subgraph "Kubernetes Cluster"
        subgraph "Bingus Namespace"
            Bot[Bot Service]
            API[API Service]
            Encoder[Encoder Service]

            subgraph "Storage"
                ModelCache[Model Cache PVC]
                EmbedCache[Embedding Cache PVC]
                APIData[API Data PVC]
            end
        end

        subgraph "Ingress"
            Traefik[Traefik Ingress]
        end
    end

    Internet --> Traefik
    Traefik --> API
    Bot --> API
    API --> Encoder
    Encoder --> ModelCache
    Encoder --> EmbedCache
    API --> APIData
```
