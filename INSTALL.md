# ClearlyDefined Helm Chart - Installation Guide

## Quick Start

### 1. Prerequisites

Ensure you have:
- Kubernetes cluster (1.19+)
- Helm 3.0+
- GitHub Personal Access Token ([create one here](https://github.com/settings/tokens))
- kubectl configured to access your cluster

### 2. Configure Your Curated Data Repository

**Important:** You should use your own GitHub repository for curated data, not the default ClearlyDefined repository.

Create or fork a repository for your curated data, then configure it in your values file.

### 3. Create the Kubernetes Secret

The chart requires an existing Kubernetes secret containing GitHub tokens. Create it before installing the chart.

**Required keys:**

| Key | Description | Required |
|-----|-------------|----------|
| `CURATION_GITHUB_TOKEN` | GitHub PAT with read/write access to your curated data repo | Yes |
| `CRAWLER_GITHUB_TOKEN` | GitHub PAT with read access (can be same token as above) | Yes |
| `WEBHOOK_GITHUB_SECRET` | Shared secret for GitHub webhook verification (can be arbitrary string) | Yes |
| `WEBHOOK_CRAWLER_SECRET` | Shared secret for crawler webhook verification (can be arbitrary string) | Yes |
| `CRAWLER_SERVICE_AUTH_TOKEN` | Token the crawler uses to validate incoming requests (must match `CRAWLER_API_AUTH_TOKEN`) | Yes |
| `CRAWLER_API_AUTH_TOKEN` | Token the service sends to the crawler (must match `CRAWLER_SERVICE_AUTH_TOKEN`) | Yes |
| `GITLAB_TOKEN` | GitLab token, or random string if not using GitLab | No |
| `CRAWLER_WEBHOOK_TOKEN` | Webhook authentication token | No |
| `CRAWLER_AZBLOB_CONNECTION_STRING` | Azure Blob Storage connection string | No |
| `CRAWLER_INSIGHTS_CONNECTION_STRING` | Application Insights connection string | No |

**Create the secret with required keys only:**

```bash
kubectl create secret generic clearlydefined-secrets \
  --namespace <your-namespace> \
  --from-literal=CURATION_GITHUB_TOKEN="ghp_your_token_here" \
  --from-literal=CRAWLER_GITHUB_TOKEN="ghp_your_token_here" \
  --from-literal=WEBHOOK_GITHUB_SECRET="any-random-string-here" \
  --from-literal=WEBHOOK_CRAWLER_SECRET="any-random-string-here" \
  --from-literal=CRAWLER_SERVICE_AUTH_TOKEN="some-shared-token" \
  --from-literal=CRAWLER_API_AUTH_TOKEN="some-shared-token"
```

**Or with all keys:**

```bash
kubectl create secret generic clearlydefined-secrets \
  --namespace <your-namespace> \
  --from-literal=CURATION_GITHUB_TOKEN="ghp_your_token_here" \
  --from-literal=CRAWLER_GITHUB_TOKEN="ghp_your_token_here" \
  --from-literal=WEBHOOK_GITHUB_SECRET="any-random-string-here" \
  --from-literal=WEBHOOK_CRAWLER_SECRET="any-random-string-here" \
  --from-literal=CRAWLER_SERVICE_AUTH_TOKEN="some-shared-token" \
  --from-literal=CRAWLER_API_AUTH_TOKEN="some-shared-token" \
  --from-literal=GITLAB_TOKEN="random-string" \
  --from-literal=CRAWLER_WEBHOOK_TOKEN="your-webhook-secret" \
  --from-literal=CRAWLER_AZBLOB_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=..." \
  --from-literal=CRAWLER_INSIGHTS_CONNECTION_STRING="InstrumentationKey=..."
```

**Note:** The secret name must match `existingSecret` in your values file (default: `clearlydefined-secrets`).

### 4. Create Your Values File

Copy the example values file:

```bash
cp values-example.yaml my-values.yaml
```

Edit `my-values.yaml` and configure at minimum:

```yaml
# Reference your secret (default name shown)
existingSecret: "clearlydefined-secrets"

# Required: Your curated data repository
config:
  curation:
    github:
      owner: "your-github-username"
      repo: "your-curated-data-repo"
      branch: "main"

# Traefik ingress (choose one option)
# Option 1: Traefik with Let's Encrypt
useTraefikLe: true
leHost: "clearlydefined.example.com"
projectProtocol: "https"
# Option 2: Traefik behind load balancer (uncomment instead of above)
# traefikBehindLb: true
# leHost: "clearlydefined.example.com"
```

### 5. Install the Chart

```bash
helm install clearlydefined . -f my-values.yaml
```

### 6. Verify Installation

```bash
# Check all pods are running
kubectl get pods -l app.kubernetes.io/instance=clearlydefined

# Check services
kubectl get svc -l app.kubernetes.io/instance=clearlydefined

# View logs
kubectl logs -l app.kubernetes.io/component=service -f
```

### 7. Access the Service

```bash
# Port forward to access locally
kubectl port-forward svc/clearlydefined-service 4000:4000

# Test the API
curl http://localhost:4000
```

## Configuration Options

### Using Your Own Curated Data Repository

The most important configuration is pointing to your own curated data repository:

```yaml
config:
  curation:
    github:
      owner: "your-github-org"
      repo: "curated-data"
      branch: "main"
```

Ensure the `CURATION_GITHUB_TOKEN` in your Kubernetes secret has read/write access to this repository.

### Storage Configuration

#### Single-Node Cluster (Default)

The default configuration uses `ReadWriteOnce` volumes, which work on single-node clusters:

```yaml
harvestedData:
  persistence:
    enabled: true
    size: 20Gi
    accessMode: ReadWriteOnce
```

#### Multi-Node Cluster

For multi-node clusters, use a storage class that supports `ReadWriteMany`:

```yaml
harvestedData:
  persistence:
    enabled: true
    size: 20Gi
    accessMode: ReadWriteMany
    storageClass: "nfs"  # or azure-file, efs-sc, etc.
```

### Development vs Production

#### Development Setup

```yaml
# Disable persistence for faster iteration
mongodb:
  persistence:
    enabled: false
redis:
  persistence:
    enabled: false
harvestedData:
  persistence:
    enabled: false

# Enable sample data
mongoSeed:
  enabled: true

# Enable debug mode
service:
  debug:
    enabled: true
crawler:
  debug:
    enabled: true
```

#### Production Setup

```yaml
# Use persistent storage
mongodb:
  persistence:
    enabled: true
    size: 50Gi
    storageClass: "fast-ssd"

redis:
  persistence:
    enabled: true
    size: 10Gi

harvestedData:
  persistence:
    enabled: true
    size: 100Gi
    accessMode: ReadWriteMany
    storageClass: "nfs"

# Disable seed (use your own data)
mongoSeed:
  enabled: false

# Configure resource limits
service:
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi

crawler:
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi

# Enable Traefik ingress with Let's Encrypt
useTraefikLe: true
leHost: "clearlydefined.example.com"
projectProtocol: "https"
traefik_crd_api_version: "traefik.containo.us/v1alpha1"
```

## Troubleshooting

### Pods Not Starting

Check pod status and events:

```bash
kubectl get pods -l app.kubernetes.io/instance=clearlydefined
kubectl describe pod <pod-name>
```

### Volume Mount Issues

If using `ReadWriteOnce`, ensure both service and crawler are on the same node:

```bash
kubectl get pods -l app.kubernetes.io/instance=clearlydefined -o wide
```

Both should show the same NODE.

### MongoDB Connection Issues

Verify MongoDB is running and accessible:

```bash
kubectl logs -l app.kubernetes.io/component=mongodb
kubectl exec -it <service-pod> -- curl http://clearlydefined-mongodb:27017
```

### GitHub Token Issues

Verify your tokens are set correctly:

```bash
kubectl get secret clearlydefined-secrets -o yaml
```

The tokens should be base64 encoded in the secret.

## Upgrading

```bash
# Update your values file
vim my-values.yaml

# Upgrade the release
helm upgrade clearlydefined . -f my-values.yaml

# Watch the rollout
kubectl rollout status deployment/clearlydefined-service
kubectl rollout status deployment/clearlydefined-crawler
```

## Uninstalling

```bash
# Remove the Helm release
helm uninstall clearlydefined

# Optionally, delete persistent volumes
kubectl delete pvc -l app.kubernetes.io/instance=clearlydefined
```

## Next Steps

1. Configure your curated data repository
2. Set up GitHub webhooks for automatic curation updates
3. Configure ingress for external access
4. Set up monitoring and logging
5. Review the [ClearlyDefined documentation](https://docs.clearlydefined.io)

## Support

- [ClearlyDefined Documentation](https://docs.clearlydefined.io)
- [GitHub Issues](https://github.com/clearlydefined)
- [Discord Community](https://discord.gg/wEzHJku)
