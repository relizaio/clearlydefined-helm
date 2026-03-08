# ClearlyDefined Helm Chart - Summary

## Overview

This Helm chart deploys a complete ClearlyDefined stack to Kubernetes based on the docker-compose configuration, with the following key decisions and implementations:

## Key Implementation Decisions

### 1. Storage Strategy: ReadWriteOnce with Automatic Pod Affinity ✅

**Decision:** Use `ReadWriteOnce` for harvested data volume with automatic pod affinity rules.

**Rationale:**
- Works on single-node clusters and most Kubernetes environments
- Doesn't require special storage classes (NFS, Azure Files, etc.)
- Chart automatically ensures service and crawler pods are scheduled on the same node

**Implementation:**
- `harvestedData.persistence.accessMode: ReadWriteOnce` (default)
- Automatic pod affinity rules in both service and crawler deployments
- Users can override to `ReadWriteMany` if they have compatible storage

### 2. MongoDB Seed: Disabled by Default ✅

**Decision:** MongoDB seed job is disabled by default (`mongoSeed.enabled: false`)

**Rationale:**
- Users should use their own curated data repository (as you specified)
- Seed is only useful for development/testing with sample data
- Reduces unnecessary container pulls and job executions

**Documentation:**
- Clear explanation in README about when to enable/disable
- Link to GitHub repository for building custom seed image
- Reference to ClearlyDefined documentation

### 3. Web/Website Service: Completely Removed ✅

**Decision:** No web/website component included in the chart

**Components Included:**
- ✅ ClearlyDefined Service (API)
- ✅ Crawler
- ✅ MongoDB
- ✅ Redis
- ✅ MongoDB Seed (optional)
- ❌ Web/Website (excluded as requested)

### 4. Environment Variables: Split into Secrets and ConfigMap ✅

**Secrets (sensitive):**
- GitHub tokens (required)
- GitLab token (optional)
- Webhook tokens (optional)
- Azure Blob Storage connection strings (optional)
- Application Insights connection strings (optional)

**ConfigMap (non-sensitive):**
- Curation settings (GitHub repo, branch, owner)
- Database connection strings (internal)
- Storage provider configurations
- Crawler settings

**Documentation:**
- Comprehensive environment variable documentation in README
- References to ClearlyDefined docs for each variable
- TODO comments for undocumented variables (Azure Blob, App Insights, queue providers)

## Chart Structure

```
clearlydefined-helm/
├── Chart.yaml                          # Chart metadata
├── values.yaml                         # Default values (mongoSeed disabled, RWO volumes)
├── values-example.yaml                 # Example with comments
├── README.md                           # Comprehensive documentation
├── INSTALL.md                          # Installation guide
├── SUMMARY.md                          # This file
├── .helmignore                         # Helm ignore patterns
├── .gitignore                          # Git ignore (excludes secrets files)
└── templates/
    ├── _helpers.tpl                    # Template helpers
    ├── configmap.yaml                  # Non-secret environment variables
    ├── secret.yaml                     # Secret environment variables
    ├── serviceaccount.yaml             # Service account
    ├── pvc-harvested-data.yaml         # Shared harvested data (RWO)
    ├── pvc-mongodb.yaml                # MongoDB persistent volume
    ├── pvc-redis.yaml                  # Redis persistent volume
    ├── deployment-service.yaml         # Service with pod affinity
    ├── deployment-crawler.yaml         # Crawler with pod affinity
    ├── deployment-mongodb.yaml         # MongoDB
    ├── deployment-redis.yaml           # Redis
    ├── job-mongo-seed.yaml             # MongoDB seed (Helm hook, disabled)
    ├── service-service.yaml            # Service exposure
    ├── service-crawler.yaml            # Crawler exposure
    ├── service-mongodb.yaml            # MongoDB exposure
    ├── service-redis.yaml              # Redis exposure
    ├── ingress.yaml                    # Ingress (disabled by default)
    └── NOTES.txt                       # Post-install notes
```

## Images Used

| Component | Image | Source |
|-----------|-------|--------|
| Service | `registry.relizahub.com/83d27192-7d06-4d01-a5d6-de4839926da2-public/clearlydefined-service:latest` | Reliza Hub |
| Crawler | `registry.relizahub.com/83d27192-7d06-4d01-a5d6-de4839926da2-public/clearlydefined-crawler:latest` | Reliza Hub |
| MongoDB | `mongo:5.0.6` | Docker Hub |
| Redis | `redis:latest` | Docker Hub |
| Mongo Seed | `clearlydefined/docker_dev_env_experiment_clearlydefined_mongo_seed:latest` | Docker Hub |

## Features Implemented

### Core Features
- ✅ All components from docker-compose (except web)
- ✅ Persistent volumes for MongoDB, Redis, and harvested data
- ✅ ConfigMap and Secret management
- ✅ Service discovery (internal DNS)
- ✅ Resource limits and requests
- ✅ Debug mode support (Node.js inspector)
- ✅ CRAWLER_ID from pod metadata

### Advanced Features
- ✅ Automatic pod affinity for ReadWriteOnce volumes
- ✅ Helm hooks for MongoDB seed job
- ✅ ConfigMap/Secret checksums for automatic pod restarts
- ✅ Ingress support (disabled by default)
- ✅ ServiceAccount creation
- ✅ Flexible storage class configuration
- ✅ Component-level enable/disable flags

### Documentation
- ✅ Comprehensive README with examples
- ✅ Installation guide (INSTALL.md)
- ✅ Example values file with comments
- ✅ Post-install NOTES with access instructions
- ✅ Environment variable documentation with references
- ✅ TODO comments for undocumented features

## Configuration Highlights

### Default Values
```yaml
# Storage: ReadWriteOnce (single-node compatible)
harvestedData.persistence.accessMode: ReadWriteOnce

# MongoDB Seed: Disabled (use your own curated data)
mongoSeed.enabled: false

# Curation: Points to ClearlyDefined default (should be changed)
config.curation.github.owner: "clearlydefined"
config.curation.github.repo: "curated-data-dev"

# Storage Provider: File-based (local storage)
config.harvest.store.provider: "file"

# Queue Provider: In-memory (no Redis dependency)
config.crawler.queueProvider: "memory"
```

### Required User Configuration

**1. Create Kubernetes secret (before install):**
```bash
kubectl create secret generic clearlydefined-secrets \
  --namespace <your-namespace> \
  --from-literal=CURATION_GITHUB_TOKEN="your-token" \
  --from-literal=CRAWLER_GITHUB_TOKEN="your-token"
```

**2. Configure values:**
```yaml
existingSecret: "clearlydefined-secrets"
config.curation.github.owner: "your-org"
config.curation.github.repo: "your-repo"

# Traefik ingress (one of):
useTraefikLe: true          # with Let's Encrypt
# traefikBehindLb: true     # behind load balancer
leHost: "clearlydefined.example.com"
projectProtocol: "https"
```

## TODO Items in Documentation

The following items are marked as TODO in the README for future documentation:

1. **Azure Blob Storage Configuration**
   - TODO: Find specific documentation reference for Azure Blob Storage configuration
   - Variables: `crawlerAzblobConnectionString`, `crawler.azblob.containerName`

2. **Application Insights Configuration**
   - TODO: Find specific documentation reference for Application Insights configuration
   - Variable: `crawlerInsightsConnectionString`

3. **Queue Provider Options**
   - TODO: Find documentation for queue provider options
   - Variable: `crawler.queueProvider` (memory, redis, amqp)

## Testing Recommendations

### Before First Deployment
1. Verify GitHub tokens have correct permissions
2. Ensure your curated data repository exists
3. Check storage class availability in your cluster
4. Verify node capacity for persistent volumes

### After Deployment
1. Check all pods are running: `kubectl get pods`
2. Verify volumes are bound: `kubectl get pvc`
3. Test service API: `curl http://localhost:4000` (via port-forward)
4. Check logs for errors: `kubectl logs -l app.kubernetes.io/component=service`
5. Verify pod affinity: `kubectl get pods -o wide` (same node for service/crawler)

## Upgrade Path

To upgrade from docker-compose to this Helm chart:

1. Export existing MongoDB data (if needed)
2. Configure your curated data repository in values
3. Set GitHub tokens
4. Deploy with `helm install`
5. Import MongoDB data (if needed)
6. Update DNS/ingress to point to new service

## Support and References

- **ClearlyDefined Docs:** https://docs.clearlydefined.io
- **Installation Guide:** https://docs.clearlydefined.io/docs/installation/start
- **Container Docs:** https://docs.clearlydefined.io/docs/installation/containers
- **GitHub:** https://github.com/clearlydefined
- **Discord:** https://discord.gg/wEzHJku
