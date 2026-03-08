# ClearlyDefined Helm Chart

A Helm chart for deploying ClearlyDefined - a service that helps open source projects be more successful through clearly defined project data.

## Overview

This Helm chart deploys the following components:
- **ClearlyDefined Service** - Main API service (port 4000)
- **Crawler** - Data harvesting crawler (port 5000)
- **MongoDB** - Database for definitions and curations (port 27017)
- **Redis** - Queue and caching service (port 6379)
- **MongoDB Seed Job** - Initial database seeding (optional, disabled by default)

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for persistent storage)
- GitHub Personal Access Token with minimal permissions

## Installation

### 1. Clone the repository

```bash
git clone <repository-url>
cd clearlydefined-helm
```

### 2. Create a values file with your secrets

Create a file named `my-values.yaml`:

```yaml
secrets:
  # Required: GitHub tokens
  curationGithubToken: "your-github-token-here"
  crawlerGithubToken: "your-github-token-here"
  
  # Optional: GitLab token (can be random string if not using GitLab)
  gitlabToken: "random-string-or-gitlab-token"
```

### 3. Install the chart

```bash
helm install clearlydefined . -f my-values.yaml
```

Or use `--set` flags:

```bash
helm install clearlydefined . \
  --set secrets.curationGithubToken="your-token" \
  --set secrets.crawlerGithubToken="your-token"
```

## Configuration

### Images

The chart uses the following images by default:

| Component | Image |
|-----------|-------|
| Service | `registry.relizahub.com/83d27192-7d06-4d01-a5d6-de4839926da2-public/clearlydefined-service:latest` |
| Crawler | `registry.relizahub.com/83d27192-7d06-4d01-a5d6-de4839926da2-public/clearlydefined-crawler:latest` |
| MongoDB | `mongo:5.0.6` |
| Redis | `redis:latest` |

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.enabled` | Enable the ClearlyDefined service | `true` |
| `service.replicaCount` | Number of service replicas | `1` |
| `crawler.enabled` | Enable the crawler | `true` |
| `crawler.replicaCount` | Number of crawler replicas | `1` |
| `mongodb.enabled` | Enable MongoDB | `true` |
| `mongodb.persistence.enabled` | Enable MongoDB persistence | `true` |
| `mongodb.persistence.size` | MongoDB PVC size | `10Gi` |
| `redis.enabled` | Enable Redis | `true` |
| `redis.persistence.enabled` | Enable Redis persistence | `true` |
| `redis.persistence.size` | Redis PVC size | `5Gi` |
| `harvestedData.persistence.enabled` | Enable harvested data persistence | `true` |
| `harvestedData.persistence.size` | Harvested data PVC size | `20Gi` |

### Environment Variables

For complete environment variable documentation, see the [ClearlyDefined Installation Guide](https://docs.clearlydefined.io/docs/installation/start).

#### Required Secrets

- **`secrets.curationGithubToken`** - GitHub Personal Access Token for curation operations
  - Get token from: https://github.com/settings/tokens
  - Minimal permissions required
  - Used for reading/writing curations to your GitHub repository
  - Reference: [ClearlyDefined Docs - Setting up environmental variables](https://docs.clearlydefined.io/docs/installation/start#setting-up-environmental-variables)

- **`secrets.crawlerGithubToken`** - GitHub Personal Access Token for crawler operations
  - Can use the same token as `curationGithubToken`
  - Used for accessing GitHub repositories during harvesting
  - Reference: [ClearlyDefined Docs - Setting up environmental variables](https://docs.clearlydefined.io/docs/installation/start#setting-up-environmental-variables)

#### Optional Secrets

- **`secrets.gitlabToken`** - GitLab token
  - Can be a random string if not working with GitLab API
  - Only needed if harvesting from GitLab repositories
  - Reference: [ClearlyDefined Docs](https://docs.clearlydefined.io/docs/installation/start#setting-up-environmental-variables)

- **`secrets.crawlerWebhookToken`** - Webhook authentication token
  - Used to secure GitHub webhook endpoints
  - Reference: [ClearlyDefined Docs - GitHub curation setup](https://docs.clearlydefined.io/docs/installation/start#additional-setup-for-github-curationoptional)

- **`secrets.crawlerAzblobConnectionString`** - Azure Blob Storage connection string
  - Only needed if using Azure Blob Storage for harvest data (production deployments)
  - Format: `DefaultEndpointsProtocol=https;AccountName=...;AccountKey=...`
  - TODO: Find specific documentation reference for Azure Blob Storage configuration

- **`secrets.crawlerInsightsConnectionString`** - Application Insights connection string
  - Only needed for Azure Application Insights monitoring
  - Format: `InstrumentationKey=...`
  - TODO: Find specific documentation reference for Application Insights configuration

#### Configuration (Non-Secret)

All non-sensitive configuration values are in `values.yaml` under the `config` section:

**Curation Settings:**
- `config.curation.github.branch` - Branch for curated data (default: "master")
- `config.curation.github.owner` - GitHub owner/org for curated data repo (default: "clearlydefined")
- `config.curation.github.repo` - Repository name for curated data (default: "curated-data-dev")
  - **Important:** Change these to point to your own curated data repository
- `config.curation.provider` - Curation provider type (default: "github")
- `config.curation.store.provider` - Storage backend for curations (default: "mongo")

**Database Settings:**
- `config.curation.store.connectionString` - MongoDB connection string for curations
- `config.definition.store.connectionString` - MongoDB connection string for definitions
- Database names and collection names are configurable

**Storage Settings:**
- `config.harvest.store.provider` - Harvest storage provider (default: "file")
  - Options: "file", "azblob"
- `config.fileStore.location` - Path for file-based harvest storage (default: "/tmp/harvested_data")

**Crawler Settings:**
- `config.crawler.apiUrl` - Internal URL for crawler service
- `config.crawler.name` - Crawler instance name
- `config.crawler.queueProvider` - Queue provider (default: "memory")
  - Options: "memory", "redis", "amqp"
  - TODO: Find documentation for queue provider options
- `config.crawler.storeProvider` - Crawler storage provider
- `config.crawler.host` - External crawler host (optional)
- `config.crawler.webhookUrl` - Webhook callback URL (optional)
- `config.crawler.queuePrefix` - Queue name prefix (optional)
- `config.crawler.azblob.containerName` - Azure Blob container name (optional)

For detailed information about each variable, see:
- [Installation Guide](https://docs.clearlydefined.io/docs/installation/start)
- [Container Documentation](https://docs.clearlydefined.io/docs/installation/containers)
- [Using ClearlyDefined](https://docs.clearlydefined.io/docs/installation/using)

## Accessing the Services

### Port Forwarding (Development)

```bash
# Access the Service API
kubectl port-forward svc/clearlydefined-service 4000:4000

# Access the Crawler API
kubectl port-forward svc/clearlydefined-crawler 5000:5000
```

### Traefik Ingress (Production)

This chart uses Traefik IngressRoute resources for ingress. You have two options:

#### Option 1: Traefik with Let's Encrypt (Automatic HTTPS)

For automatic HTTPS with Let's Encrypt certificate resolver:

```yaml
useTraefikLe: true
leHost: "clearlydefined.example.com"
projectProtocol: "https"  # Enables HTTP to HTTPS redirect
traefik_crd_api_version: "traefik.containo.us/v1alpha1"
```

This creates:
- HTTP IngressRoute (port 80) with redirect to HTTPS
- HTTPS IngressRoute (port 443) with Let's Encrypt TLS
- Middleware for HTTP to HTTPS redirection

#### Option 2: Traefik Behind Load Balancer (HTTP Only)

For Traefik behind a load balancer that handles TLS termination:

```yaml
traefikBehindLb: true
leHost: "clearlydefined.example.com"
traefik_crd_api_version: "traefik.containo.us/v1alpha1"
```

This creates:
- HTTP IngressRoute (port 80) only
- No TLS configuration (handled by load balancer)

**Note:** Ensure Traefik is installed in your cluster with the appropriate CRDs and cert resolver configured.

## Debugging

### Enable Debug Mode

To enable Node.js debugging for the service or crawler:

```yaml
service:
  debug:
    enabled: true
    port: 9230

crawler:
  debug:
    enabled: true
    port: 9229
```

Then port-forward the debug port:

```bash
kubectl port-forward svc/clearlydefined-service 9230:9230
kubectl port-forward svc/clearlydefined-crawler 9229:9229
```

### View Logs

```bash
# Service logs
kubectl logs -l app.kubernetes.io/component=service -f

# Crawler logs
kubectl logs -l app.kubernetes.io/component=crawler -f

# MongoDB logs
kubectl logs -l app.kubernetes.io/component=mongodb -f
```

## Persistence

The chart creates three PersistentVolumeClaims:

1. **MongoDB Data** - Stores database data
2. **Redis Data** - Stores Redis data
3. **Harvested Data** - Shared volume for harvested data between service and crawler

### Important: Harvested Data Volume Constraint

**The harvested data volume uses `ReadWriteOnce` access mode by default.** This means:
- The volume can only be mounted by pods on a single node
- Both the service and crawler pods **must be scheduled on the same Kubernetes node**
- This is suitable for single-node clusters or when using node affinity rules

**The chart automatically configures pod affinity rules** to ensure both pods are scheduled on the same node when using `ReadWriteOnce`. However, be aware:
- If one pod is running and the node becomes unavailable, both pods will need to be rescheduled
- For multi-node production clusters, consider using a storage class that supports `ReadWriteMany` (NFS, Azure Files, EFS, etc.)

To use `ReadWriteMany` (requires compatible storage class):

```yaml
harvestedData:
  persistence:
    accessMode: ReadWriteMany
    storageClass: "nfs"  # or azure-file, efs-sc, etc.
```

### Storage Classes

To use a specific storage class:

```yaml
global:
  storageClass: "fast-ssd"
```

Or per component:

```yaml
mongodb:
  persistence:
    storageClass: "standard"

harvestedData:
  persistence:
    storageClass: "standard"
```

## Upgrading

```bash
helm upgrade clearlydefined . -f my-values.yaml
```

## Uninstalling

```bash
helm uninstall clearlydefined
```

**Note:** PersistentVolumeClaims are not automatically deleted. To delete them:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=clearlydefined
```

## Customization Examples

### Use Different MongoDB Version

```yaml
images:
  mongodb:
    tag: "4.4.28"  # For Mac computers without AVX support
```

### Enable MongoDB Seed (Development/Testing Only)

The MongoDB seed job is **disabled by default** because it's only needed for development/testing with sample data.

**When to enable:**
- You want to test ClearlyDefined with sample data
- You're setting up a development environment
- You're not using your own curated data repository

**When to keep disabled (default):**
- You're using your own GitHub repository for curated data
- You're deploying to production
- You want to start with an empty database

```yaml
mongoSeed:
  enabled: true  # Enable for development/testing with sample data
```

**Note about the seed image:**
- The seed image (`clearlydefined/docker_dev_env_experiment_clearlydefined_mongo_seed`) is from the [ClearlyDefined docker_dev_env_experiment](https://github.com/clearlydefined/docker_dev_env_experiment/tree/main/mongo_seed)
- It populates MongoDB collections with sample data for testing
- See [Container Documentation](https://docs.clearlydefined.io/docs/installation/containers#clearlydefined-mongo-seed) for more information
- If you need to build your own seed image, follow instructions at the GitHub repository above

### Disable Persistence (Development)

```yaml
mongodb:
  persistence:
    enabled: false

redis:
  persistence:
    enabled: false

harvestedData:
  persistence:
    enabled: false
```

### Custom Resource Limits

```yaml
service:
  resources:
    requests:
      cpu: 1000m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 2Gi

crawler:
  resources:
    requests:
      cpu: 1000m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 2Gi
```

### Configure for Production with Azure Blob Storage

```yaml
config:
  harvest:
    store:
      provider: "azblob"
  crawler:
    storeProvider: "azblob"
    azblob:
      containerName: "clearlydefined-harvested"

secrets:
  crawlerAzblobConnectionString: "DefaultEndpointsProtocol=https;AccountName=..."
```

## Troubleshooting

### MongoDB Seed Job Fails

Check the job logs:

```bash
kubectl logs -l app.kubernetes.io/component=mongo-seed
```

The seed job runs as a Helm hook and will retry on failure.

### Harvested Data Volume Issues

If using `ReadWriteMany` access mode, ensure your storage class supports it (e.g., NFS, Azure Files, EFS).

For single-node clusters or development, you can use `ReadWriteOnce`:

```yaml
harvestedData:
  persistence:
    accessMode: ReadWriteOnce
```

### Service Can't Connect to MongoDB

Verify MongoDB is running:

```bash
kubectl get pods -l app.kubernetes.io/component=mongodb
```

Check the connection string in the ConfigMap:

```bash
kubectl get configmap clearlydefined-config -o yaml
```

## Documentation

For more information about ClearlyDefined:
- [Official Documentation](https://docs.clearlydefined.io)
- [GitHub Repository](https://github.com/clearlydefined)
- [Website](https://clearlydefined.io)

## License

This Helm chart follows the same license as the ClearlyDefined project.
