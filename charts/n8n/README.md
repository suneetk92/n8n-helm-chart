# n8n

![n8n](https://raw.githubusercontent.com/n8n-io/n8n-docs/refs/heads/main/docs/_images/n8n-docs-withWordmark.svg)

A Helm chart for fair-code workflow automation platform with native AI capabilities. Combine visual building with custom code, self-host or cloud, 400+ integrations.

![Version: 4.1.1](https://img.shields.io/badge/Version-4.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.39.2](https://img.shields.io/badge/AppVersion-2.39.2-informational?style=flat-square)

## Official Documentation

For upstream application documentation, refer to the [n8n docs](https://docs.n8n.io/). Chart
architecture and development notes live in [`CLAUDE.md`](CLAUDE.md).

## Installing the Chart

This chart is published as an OCI artifact, so no `helm repo add` is required:

```console
helm install [RELEASE_NAME] oci://ghcr.io/suneetk92/n8n --version 4.1.1
```

_See [configuration](#configuration) below._

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

> **Tip**: Inspect the defaults before installing with `helm show values oci://ghcr.io/suneetk92/n8n --version 4.1.1`. Available versions are listed on the [package page](https://github.com/suneetk92?tab=packages&repo_name=n8n-helm-chart).

## Full Example

> **Tip**:
> n8n now listens on IPv6 addresses by [default](https://docs.n8n.io/hosting/configuration/environment-variables/deployment/) (`N8N_LISTEN_ADDRESS="::"`) due to the gradual deprecation of IPv4.
> If your Kubernetes cluster only supports IPv4, be sure to set `N8N_LISTEN_ADDRESS=0.0.0.0`.
> This will help avoid potential issues with readiness and liveness probes failing.

```yaml
log:
  level: warn
  format: text

db:
  type: postgresdb

externalPostgresql:
  host: "postgresql-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "n8nuser"
  password: "Pa33w0rd!"
  database: "n8n"

main:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 512m
      memory: 512Mi

worker:
  mode: queue

  autoscaling:
    enabled: true

  waitMainNodeReady:
    enabled: true

  resources:
    requests:
      cpu: 1000m
      memory: 250Mi
    limits:
      cpu: 2000m
      memory: 2Gi

externalRedis:
  host: "redis-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "default"
  password: "Pa33w0rd!"

ingress:
  enabled: true
  hosts:
    - host: n8n.mydomain.com
      paths:
        - path: /
          pathType: Prefix

webhook:
  mode: queue

  url: "https://webhook.mydomain.com"

  autoscaling:
    enabled: true

  waitMainNodeReady:
    enabled: true

  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 512m
      memory: 512Mi
```

## Basic Deployment with Ingress

```yaml
ingress:
  enabled: true
  hosts:
    - host: n8n.mydomain.com
      paths:
        - path: /
          pathType: ImplementationSpecific
```

## Deployment with External PostgreSQL

```yaml
db:
  type: postgresdb

externalPostgresql:
  host: "postgresql-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "n8nuser"
  password: "Pa33w0rd!"
  database: "n8n"
```

## Deployment with External PostgreSQL and Exist Secret on Kubernetes

```yaml
db:
  type: postgresdb

externalPostgresql:
  host: "postgresql-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "n8nuser"
  database: "n8n"

  existingSecret: "my-k8s-secret-contains-postgres-password-key-and-credential"
  existingSecretPasswordKey: "my-postgres-password-key"
```

## Queue Mode with External Redis

> **Tip**: Queue mode doesn't work with default SQLite mode

```yaml
db:
  type: postgresdb

externalPostgresql:
  host: "postgresql-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "n8nuser"
  password: "Pa33w0rd!"
  database: "n8n"

worker:
  mode: queue

externalRedis:
  host: "redis-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "default"
  password: "Pa33w0rd!"
```

## Queue Mode with External Redis and Exist Secret on Kubernetes

> **Tip**: Queue mode doesn't work with default SQLite mode

```yaml
db:
  type: postgresdb

externalPostgresql:
  host: "postgresql-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "n8nuser"
  database: "n8n"

  existingSecret: "my-k8s-secret-contains-postgres-password-key-and-credential"

worker:
  mode: queue

externalRedis:
  host: "redis-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "default"

  existingSecret: "my-k8s-secret-contains-redis-password-key-and-credential"
  existingUsernameKey: "my-redis-username-key"
  existingPasswordKey: "my-redis-password-key"
```

## Webhook Node Deployment

> **Tip**: Webhook needs PostgreSQL backend and Redis based queue mode.

```yaml
db:
  type: postgresdb

externalPostgresql:
  host: "postgresql-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "n8nuser"
  password: "Pa33w0rd!"
  database: "n8n"

worker:
  mode: queue

externalRedis:
  host: "redis-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "default"
  password: "Pa33w0rd!"

ingress:
  enabled: true
  hosts:
    - host: n8n.mydomain.com
      paths:
        - path: /
          pathType: Prefix

webhook:
  mode: queue

  url: "https://webhook.mydomain.com"
```

## External Task Runner Example

Please find more detail about external task runners from [here](https://docs.n8n.io/hosting/securing/hardening-task-runners/).

The external task runner runs as a sidecar container using the dedicated `n8nio/runners` image alongside each worker pod. In queue mode the main pod does **not** receive the sidecar because it does not execute workflows.

### Basic External Task Runner

```yaml
taskRunners:
  mode: external
```

### Pinning the Runner Image Tag

By default the runner image tag matches the chart `appVersion`. Pin an explicit version with `taskRunners.external.image.tag`:

```yaml
taskRunners:
  mode: external
  external:
    image:
      repository: n8nio/runners
      pullPolicy: IfNotPresent
      tag: "2.23.4"
```

### External Task Runner with Queue Mode

In queue mode the sidecar is attached to worker pods only — the main pod is excluded automatically because it offloads all workflow execution to workers.

```yaml
db:
  type: postgresdb

worker:
  mode: queue

taskRunners:
  mode: external
  external:
    resources:
      requests:
        cpu: 100m
        memory: 64Mi
      limits:
        cpu: 500m
        memory: 256Mi
```

## Python Runner Support

The `n8nio/runners` image ships a Python runner alongside the JavaScript runner. Enable it with `nodes.python.enabled: true` (requires n8n 1.111.0+). This activates the Python Code node on the main container and starts the Python launcher inside the sidecar.

> **Tip**: Python runner requires `taskRunners.mode: external`.

### Enable Python Runner

```yaml
nodes:
  python:
    enabled: true

taskRunners:
  mode: external
```

### Install Python Packages

The `n8nio/runners` image ships only a bare Python environment. Use `nodes.python.external.packages` to install packages via `uv pip install` before the runner starts. Each listed package is automatically allowed in Code nodes — no separate allowlist entry is needed.

```yaml
nodes:
  python:
    enabled: true
    external:
      packages:
        - pandas
        - numpy
        - requests

taskRunners:
  mode: external
```

> **Note**: Package installation adds a few seconds to runner startup time on the first start. To avoid re-downloading packages on every pod restart, enable persistence (see below).

#### Persist Python Packages

Enable `nodes.python.persistence` to store installed packages on a PVC. When enabled, `uv pip install` detects existing packages on subsequent starts and skips the download.

```yaml
nodes:
  python:
    enabled: true
    external:
      packages:
        - pandas
        - numpy
    persistence:
      enabled: true
      size: 2Gi
      accessMode: ReadWriteOnce  # use ReadWriteMany if workers span multiple nodes

taskRunners:
  mode: external
```

Packages are stored at `/home/node/.python-packages` inside the runner sidecar. When `persistence.enabled` is `false` (the default), an `emptyDir` volume is used and packages are re-installed on every pod restart.

For StatefulSet deployments (when `main.count > 1` with `ReadWriteOnce`, or `main.forceToUseStatefulset: true`), each pod receives its own PVC via `volumeClaimTemplates`, so `ReadWriteOnce` works regardless of pod count. For Deployment-mode workers scaled by HPA across multiple nodes, use `accessMode: ReadWriteMany` with a compatible storage class (NFS, CephFS, etc.).

> **Warning**: When `worker.autoscaling.enabled: true`, you **must** set `nodes.python.persistence.accessMode: ReadWriteMany` (or leave persistence disabled). The HPA will not render if python packages persistence is enabled with `ReadWriteOnce`, because scaling workers across nodes would cause PVC mount failures.

To allow all external packages without installing them (e.g. when packages are pre-installed in a custom image), set `allowAll: true`:

```yaml
nodes:
  python:
    enabled: true
    external:
      allowAll: true

taskRunners:
  mode: external
```

### Private Python Package Registry

By default, `uv pip install` resolves packages from pypi.org. Use `pypiRegistry` to point the runner sidecar at a private or self-hosted index instead (JFrog Artifactory, AWS CodeArtifact, Nexus, etc.).

#### Simple — URL only (no auth or inline credentials)

```yaml
pypiRegistry:
  enabled: true
  url: "https://my.jfrog.io/artifactory/api/pypi/pypi-virtual/simple/"
```

This sets `UV_DEFAULT_INDEX` in the sidecar, replacing pypi.org as the default index.

#### Advanced — `uv.toml` config file (authentication or multiple indexes)

For authenticated registries, create a `uv.toml` with your index configuration and let the chart store it in a Kubernetes Secret:

```yaml
pypiRegistry:
  enabled: true
  customUvConfig: |
    [[index]]
    name = "private"
    url = "https://my.jfrog.io/artifactory/api/pypi/pypi-virtual/simple/"
    default = true

    [index.credentials]
    username = "ci-user"
    password = "s3cr3t"
```

The chart creates a Secret from `customUvConfig`, mounts it into the runner sidecar, and sets `UV_CONFIG_FILE` to the mounted path. The entire file is base64-encoded in the Secret.

> **Note**: Do not use `url` together with `customUvConfig` or `secretName` — when a config file is provided, the index URL belongs inside the `uv.toml`.

#### Advanced — reference an existing Secret

If you manage credentials in an existing Kubernetes Secret, reference it directly:

```yaml
pypiRegistry:
  enabled: true
  secretName: "my-uv-config-secret"
  secretKey: "uv.toml"
```

The secret must contain a key matching `secretKey` (default: `uv.toml`) whose value is valid `uv.toml` content.

### Restrict Python Module Access

Use `nodes.python.builtin.modules` to allowlist Python standard library modules. Use `["*"]` to allow all. This setting applies to both the n8n broker (security enforcement) and the runner sidecar.

```yaml
nodes:
  python:
    enabled: true
    builtin:
      modules:
        - os
        - sys
        - json
        - math
    external:
      packages:
        - numpy
        - pandas

taskRunners:
  mode: external
```

### Full Queue Mode + External Runner + Python Example

```yaml
db:
  type: postgresdb

worker:
  mode: queue
  count: 2

  waitMainNodeReady:
    enabled: true

externalRedis:
  host: "redis-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "default"
  password: "Pa33w0rd!"

nodes:
  python:
    enabled: true
    builtin:
      modules:
        - "*"
    external:
      packages:
        - numpy
        - pandas
    persistence:
      enabled: true
      size: 2Gi
      accessMode: ReadWriteMany  # required for queue-mode workers scaled across nodes

taskRunners:
  mode: external
  external:
    image:
      repository: n8nio/runners
      pullPolicy: IfNotPresent
      tag: ""
    resources:
      requests:
        cpu: 100m
        memory: 64Mi
      limits:
        cpu: 500m
        memory: 256Mi
```

## Autoscaling Configuration

> **Note:** The `autoscaling` and `allNodes` options cannot be enabled simultaneously.

### Deploying Worker and Webhook Pods on All Nodes

To deploy worker or webhook pods on all Kubernetes nodes, set the `allNodes` flag to `true`: 

```yaml
db:
  type: postgresdb

worker:
  mode: queue
  allNodes: true

webhook:
  mode: queue
  allNodes: true
```

### Enabling Autoscaling

To enable autoscaling, set the `enabled` field under `autoscaling` to `true`:

```yaml
db:
  type: postgresdb

worker:
  mode: queue
  autoscaling:
    enabled: true

webhook:
  mode: queue
  autoscaling:
    enabled: true
```

Ensure that you configure either `allNodes` or `autoscaling` based on your deployment requirements.

## StatefulSet and Deployment Selection (Persistence & Scaling)

> **Note:** You do **not** need to set `forceToUseStatefulset` in most cases. The chart will automatically select StatefulSet or Deployment based on your persistence and replica settings.

- **StatefulSet** is used automatically if:
  - `persistence.enabled: true`
  - More than one replica (`count > 1` and `autoscaling.enabled: false`)
  - `persistence.accessMode: ReadWriteOnce`
  - No `existingClaim` is set

- **Deployment** is used if:
  - `persistence.enabled: false`
  - Only one replica (`count: 1` and no autoscaling)
  - `persistence.accessMode: ReadWriteMany`
  - `existingClaim` is set

- You can **force** StatefulSet with `forceToUseStatefulset: true` (default is `false`).

**Examples:**

### Main Node Examples

```yaml
# Automatic StatefulSet (multiple replicas, ReadWriteOnce)
main:
  count: 3  # Multiple replicas
  persistence:
    enabled: true
    accessMode: ReadWriteOnce
    volumeName: "n8n-main-data"
    mountPath: "/home/node/.n8n"
    size: 10Gi
# Result: StatefulSet with 3 replicas
```

```yaml
# Automatic Deployment (multiple replicas, ReadWriteMany)
main:
  count: 3  # Multiple replicas
  persistence:
    enabled: true
    accessMode: ReadWriteMany
    volumeName: "n8n-main-data"
    mountPath: "/home/node/.n8n"
    size: 10Gi
# Result: Deployment with 3 replicas
```

```yaml
# Automatic Deployment (single replica)
main:
  count: 1  # Single replica
  persistence:
    enabled: true
    accessMode: ReadWriteOnce
    volumeName: "n8n-main-data"
    mountPath: "/home/node/.n8n"
    size: 10Gi
# Result: Deployment with 1 replica
```

```yaml
# Manual override (force StatefulSet)
main:
  forceToUseStatefulset: true
  persistence:
    enabled: true
    volumeName: "n8n-main-data"
    mountPath: "/home/node/.n8n"
    size: 10Gi
# Result: StatefulSet regardless of other settings
```

### Worker Node Examples

```yaml
# Automatic StatefulSet (multiple replicas, ReadWriteOnce)
worker:
  mode: queue
  count: 3  # Multiple replicas
  persistence:
    enabled: true
    accessMode: ReadWriteOnce
    volumeName: "n8n-worker-data"
    mountPath: "/home/node/.n8n"
    size: 5Gi
# Result: StatefulSet with 3 replicas
```

```yaml
# Autoscaling with Deployment (ReadWriteMany)
worker:
  mode: queue
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
  persistence:
    enabled: true
    accessMode: ReadWriteMany  # Required for autoscaling
    volumeName: "n8n-worker-data"
    mountPath: "/home/node/.n8n"
    size: 5Gi
# Result: Deployment with autoscaling enabled
```

```yaml
# Manual scaling with StatefulSet
worker:
  mode: queue
  forceToUseStatefulset: true
  count: 3  # Fixed number of replicas
  persistence:
    enabled: true
    accessMode: ReadWriteOnce
    volumeName: "n8n-worker-data"
    mountPath: "/home/node/.n8n"
    size: 5Gi
  # Note: autoscaling.enabled should be false or omitted
# Result: StatefulSet with 3 replicas, no autoscaling
```

```yaml
# ❌ INVALID CONFIGURATION - Will fail schema validation
worker:
  mode: queue
  autoscaling:
    enabled: true  # ❌ Cannot enable autoscaling
  persistence:
    enabled: true
    accessMode: ReadWriteOnce  # ❌ With ReadWriteOnce persistence
# Result: Schema validation error
```

### Persistence Use Cases

**When to use persistence:**
- **Main node**: Store n8n data, workflows, and configuration persistently
- **Worker nodes**: Store npm packages and node modules for faster startup
- **Development**: Keep workflows and data across pod restarts
- **Production**: Ensure data persistence and faster npm package loading

**Storage considerations:**
- **ReadWriteOnce**: Use for single-node deployments or when you need StatefulSets
- **ReadWriteMany**: Use for multi-node deployments with autoscaling
- **Storage classes**: Choose based on your cluster's available storage options
- **Size**: Consider your data growth and npm package requirements

> **⚠️ Warning**: Using `ReadWriteMany` access mode with multiple nodes can create a volume bottleneck and significantly decrease performance. Consider using `ReadWriteOnce` with StatefulSets for better performance in high-traffic scenarios, or use external storage solutions (S3, NFS) for shared data.

> **⚠️ Autoscaling Limitations**:
> - **StatefulSets and Autoscaling**: StatefulSets do not work with Horizontal Pod Autoscaler (HPA). If you enable `worker.forceToUseStatefulset: true`, autoscaling will be disabled automatically.
> - **Persistence and Autoscaling**: When using `worker.persistence.enabled: true` with `worker.persistence.accessMode: ReadWriteOnce`, autoscaling cannot be enabled. This is because ReadWriteOnce volumes can only be mounted by one pod at a time, which conflicts with HPA's ability to scale pods dynamically.
> - **Webhook pods only support Deployments and can always use autoscaling.**

## Host Aliases Configuration

The chart supports Kubernetes hostAliases for all node types (main, worker, and webhook). This allows you to add custom hostname-to-IP mappings to the pods' `/etc/hosts` file.

### Host Aliases Configuration

```yaml
main:
  hostAliases:
    - ip: "127.0.0.1"
      hostnames:
        - "foo.local"
        - "bar.local"
    - ip: "10.1.2.3"
      hostnames:
        - "foo.remote"
        - "bar.remote"

worker:
  hostAliases:
    - ip: "192.168.1.100"
      hostnames:
        - "internal-api.local"

webhook:
  hostAliases:
    - ip: "10.0.0.50"
      hostnames:
        - "webhook-service.local"
```

For more information about hostAliases, see the [Kubernetes documentation](https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/#adding-additional-entries-with-hostaliases).

## Main Node Ready status Waiter

Running `main` nodes, `worker` nodes, and `webhooks` nodes at sametime sometimes creates migration error because multiple containers trying to apply same migration to the database. If we enable `wait-for-main` init container, only main node will apply database migrations and after nodes will start after starting to get ready status from the main node.

### Enabling `wait-for-main` for Worker Nodes and Webhook Nodes

If you set `N8N_PROTOCOL` environment variable to your main node, if will read the value and set the corrrect schema for you.

```yaml
worker:
  waitMainNodeReady:
    enabled: true

webhook:
  waitMainNodeReady:
    enabled: true
```

You can also overwrite the automatically defined values with you desired settings.

```yaml
worker:
  waitMainNodeReady:
    enabled: true
    overwriteSchema: "https"
    overwriteUrl: "n8n.n8n.svc.cluster.local:5678"
    healthCheckPath: "/healthz"
    additionalParameters:
      - "--no-check-certificate"

webhook:
  waitMainNodeReady:
    enabled: true
    overwriteSchema: "https"
    overwriteUrl: "n8n.n8n.svc.cluster.local:5678"
    healthCheckPath: "/healthz"
    additionalParameters:
      - "--no-check-certificate"
```

## Log Configuration

n8n supports configuring the log level, output destination, format, and file location via the `log` values.

### Log Format

The `log.format` option controls the output format for all log entries. Use `text` (the default) for human-readable output and `json` for structured log output suitable for ingestion by log aggregation pipelines (e.g. Loki, Elasticsearch, Datadog).

```yaml
log:
  format: json
```

### Log Level

Set the minimum severity level for log output. Valid values are `info`, `warn`, `error`, and `verbose`.

```yaml
log:
  level: warn
```

### File Logging

To write logs to a file instead of (or in addition to) the console, set `log.output` to include `file`. The `log.file.location` must be an **absolute path** inside a writable volume. The default path (`/home/node/.n8n/logs/n8n.log`) lives inside the n8n data volume and works with `readOnlyRootFilesystem: true`.

```yaml
log:
  output:
    - file
  file:
    location: "/home/node/.n8n/logs/n8n.log"
```

You can also combine console and file output:

```yaml
log:
  format: json
  level: info
  output:
    - console
    - file
  file:
    location: "/home/node/.n8n/logs/n8n.log"
```

## Enabling Support for Node.js Core and External/Private NPM Packages

Easily incorporate Node.js core packages, public NPM packages, or private NPM packages from your registry into your n8n Code blocks with this Helm chart. Below, we guide you through enabling and configuring these options.

### Using Node.js Core Packages

To enable Node.js core packages, set the `nodes.builtin.enabled` flag to `true`. This allows access to all built-in Node.js modules.

```yaml
nodes:
  builtin:
    enabled: true
```

If you prefer to enable only specific core modules, list them in `nodes.builtin.modules`. Here's an example:

```yaml
nodes:
  builtin:
    enabled: true
    modules:
      - crypto
      - fs
      - http
      - https
      - querystring
      - url
```

### Installing External NPM Packages

To install packages from the public NPM registry, add them to the `nodes.external.packages` list. You can specify versions or omit them to use the latest available version.

```yaml
nodes:
  external:
    packages:
      - "moment@2.29.4"
      - "lodash@4.17.21"
      - "date-fns"
```

#### Supporting Scoped NPM Packages (e.g., @scoped/package)

Our Helm chart supports installing NPM packages, including scoped packages (those starting with `@`, such as `@stdlib/math`). However, the Node.js Task Runner may encounter issues when processing internal package definitions that include scoped package names. To address this, we've implemented a convenient workaround: enabling the `nodes.external.allowAll` option allows all external package definitions, including scoped packages, to be processed seamlessly.

Here's an example configuration to install both regular and scoped packages:

```yaml
nodes:
  external:
    allowAll: true
    packages:
      - "moment@2.29.4"
      - "lodash@4.17.21"
      - "date-fns"
      - "@stdlib/math@0.3.3"
```

### Installing Community Node Packages

To install packages from the public NPM registry, add them to the `nodes.external.packages` list. Community Node package names must start with `n8n-nodes-`. You can specify versions or omit them to use the latest available version.

```yaml
nodes:
  external:
    packages:
      - "n8n-nodes-python@0.1.4"
      - "n8n-nodes-chatwoot@0.1.40"
```

##### How It Works

By setting `nodes.external.allowAll` to `true`, the chart bypasses the Node.js Task Runner's limitations for scoped packages, ensuring smooth installation of all listed packages. You can include both scoped (e.g., `@stdlib/math`) and non-scoped packages in the `nodes.external.packages` list, with or without specific versions.

#### Persist Community Node Packages

Community node packages are stored at `/home/node/.n8n/nodes` inside the container. The chart routes package storage automatically based on whether `main.persistence` (or `worker.persistence` for queue-mode workers) is already enabled:

- **When `main.persistence.enabled: true`** (default `mountPath: /home/node/.n8n`): community packages are written directly into the main PVC's `nodes/` subdirectory by the init container. No separate PVC is created and `nodes.external.persistence` is ignored for the main pod. Packages persist as long as the main PVC exists.

- **When `main.persistence.enabled: false`** (the default): enable `nodes.external.persistence` to store packages on a dedicated PVC. Without it, an `emptyDir` volume is used and packages are re-downloaded on every pod restart.

```yaml
nodes:
  external:
    packages:
      - "n8n-nodes-evolution-api"
      - "n8n-nodes-chatwoot@0.1.40"
    persistence:
      enabled: true
      size: 1Gi
      accessMode: ReadWriteOnce  # use ReadWriteMany if workers span multiple nodes
```

The same logic applies to queue-mode workers: when `worker.persistence.enabled: true`, the worker PVC stores community packages; otherwise the dedicated PVC (or emptyDir) is used.

> **Note**: When `worker.mode: queue` is set and workers do not have their own persistence, the community packages PVC is shared between the main pod and worker pods. Use `accessMode: ReadWriteMany` with a compatible storage class (NFS, CephFS, etc.) if those pods are scheduled on different nodes.

> **Warning**: When `worker.autoscaling.enabled: true`, you **must** either enable `worker.persistence` (which provides per-pod storage via StatefulSet), set `nodes.external.persistence.accessMode: ReadWriteMany`, or leave persistence disabled — scaling workers across nodes with a `ReadWriteOnce` shared PVC will cause mount failures.

### Using Private NPM Packages

For packages hosted in a private NPM registry, configure access by providing a valid `.npmrc` file. You can either reference an existing Kubernetes secret containing the `.npmrc` content or define custom `.npmrc` content directly in the chart values.

#### Option 1: Using a Secret for `.npmrc`

If your `.npmrc` file is stored in a Kubernetes secret, specify the secret details as shown below:

```yaml
nodes:
  external:
    packages:
      - "my-private-package"

npmRegistry:
  enabled: true
  url: "https://internal.npm.registry.mycompany.com"
  secretName: "npmrc-secret"
  secretKey: "npmrc"
```

#### Option 2: Providing Custom `.npmrc` Content

Alternatively, you can define the `.npmrc` content directly in the chart values. This is useful for registries like GitHub Packages that require authentication tokens:

```yaml
nodes:
  external:
    packages:
      - "@myGithubOrg/my-private-package"

npmRegistry:
  enabled: true
  url: "https://npm.pkg.github.com"
  customNpmrc: |
    @myGithubOrg:registry=https://npm.pkg.github.com
    //npm.pkg.github.com/:_authToken=ghp_MyGithubClassicToken
```

## Service Monitor Examples

The n8n Helm chart supports optional integration with Prometheus via `ServiceMonitor` and `PodMonitor` resources, compatible with the Prometheus Operator (API version `monitoring.coreos.com/v1`). These resources allow Prometheus to scrape metrics from n8n services and worker pods. This section provides examples to help you enable and configure monitoring.

### Prerequisites

* The Prometheus Operator must be installed in your cluster.
* Your Prometheus instance must be configured to discover `ServiceMonitor` and `PodMonitor` resources (e.g., via a matching `release` label).

### Enabling the ServiceMonitor

To enable monitoring, set `serviceMonitor.enabled` to `true` in your `values.yaml` file or via a Helm override. By default, the `ServiceMonitor` is disabled (`false`).

#### Basic Example

Enable the `ServiceMonitor` with default settings:

```yaml
serviceMonitor:
  enabled: true
```

This deploys a `ServiceMonitor` in the same namespace as the chart (e.g., `n8n`), scraping the n8n service's `/metrics` endpoint every 30 seconds with a 10-second timeout. The default label `release: prometheus` is applied, which should match your Prometheus instance's service monitor selector.

#### Custom Namespace and Interval

Deploy the `ServiceMonitor` in a specific namespace (e.g., `monitoring`) with a custom scrape interval:

```yaml
serviceMonitor:
  enabled: true
  namespace: monitoring
  interval: 1m
```

This scrapes metrics every minute from the n8n service in the release namespace (e.g., `n8n`), with the `ServiceMonitor` itself residing in the `monitoring` namespace.

#### Relabeling Metrics

Add custom metric relabeling to drop unwanted labels:

```yaml
serviceMonitor:
  enabled: true
  labels:
    release: my-prometheus
  metricRelabelings:
    - regex: prometheus_replica
      action: labeldrop
```

This deploys a `ServiceMonitor` with a custom `release: my-prometheus` label and drops the `prometheus_replica` label from scraped metrics.

### Enabling the PodMonitor (Worker Mode)

If using a PostgreSQL database (`db.type: postgresdb`) and queue mode (`worker.mode: queue`), a `PodMonitor` is available to scrape metrics from n8n worker pods.

#### Worker Monitoring Example

Enable both `ServiceMonitor` and `PodMonitor` for a full setup:

```yaml
db:
  type: postgresdb

externalPostgresql:
  host: "postgresql-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "n8nuser"
  password: "Pa33w0rd!"
  database: "n8n"

worker:
  mode: queue

externalRedis:
  host: "redis-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com"
  username: "default"
  password: "Pa33w0rd!"

serviceMonitor:
  enabled: true
  interval: 15s
  timeout: 5s
```

This scrapes the main n8n service and worker pods every 15 seconds with a 5-second timeout. The `PodMonitor` targets worker pods with the label `role: worker`.

### Troubleshooting

* Ensure the `release` label matches your Prometheus configuration (see [Prometheus Operator docs](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/platform/troubleshooting.md#troubleshooting-servicemonitor-changes)).
* Verify RBAC permissions for the Prometheus service account (e.g., system:serviceaccount:monitoring:prometheus-k8s) to list/watch Pods, Services, and Endpoints. You can use something similar as the following command.

```bash
kubectl auth can-i list pods --namespace n8n --as=system:serviceaccount:monitoring:prometheus-k8s
kubectl auth can-i list services --namespace n8n --as=system:serviceaccount:monitoring:prometheus-k8s
kubectl auth can-i list endpoints --namespace n8n --as=system:serviceaccount:monitoring:prometheus-k8s

kubectl auth can-i watch pods --namespace n8n --as=system:serviceaccount:monitoring:prometheus-k8s
kubectl auth can-i watch services --namespace n8n --as=system:serviceaccount:monitoring:prometheus-k8s
kubectl auth can-i watch endpoints --namespace n8n --as=system:serviceaccount:monitoring:prometheus-k8s
```

## Enterprise License Configuration

The chart now supports enterprise license configuration. To enable and configure it, update the `values.yaml` file:

```yaml
license:
  enabled: true
  activationKey: "your-activation-key"
```

If you have an existing secret for the activation key with `N8N_LICENSE_ACTIVATION_KEY` secret key, configure it as follows:

```yaml
license:
  enabled: true
  existingActivationKeySecret: "your-existing-secret"
```

## Binary Data Storage Configuration

`binaryData.mode` selects where n8n stores binary data. Leave it unset (`~`) to let n8n choose for the deployment mode (`filesystem` in regular mode, `database` in queue mode). n8n 2.0 removed the in-memory mode, so `default` is no longer a valid value.

```yaml
binaryData:
  # filesystem | database | s3 (unset = n8n default for the deployment mode)
  mode: filesystem
```

### Filesystem

Override the storage path with `binaryData.localStoragePath`. It is only rendered in `filesystem` mode, so make sure the path is covered by a writable volume.

```yaml
binaryData:
  mode: filesystem
  localStoragePath: /home/node/.n8n/binaryData
```

### Database

Binary data lives in the database. `databaseMaxFileSize` (MiB) caps a single file and cannot exceed `1024`, the column limit; storing a larger file fails.

```yaml
binaryData:
  mode: database
  databaseMaxFileSize: 512
```

### S3-compatible external storage

S3 settings are only used when `binaryData.mode` is `s3`:

```yaml
binaryData:
  mode: s3
  s3:
    host: "s3.us-east-1.amazonaws.com"
    bucketName: "your-bucket-name"
    bucketRegion: "us-east-1"
    accessKey: "your-access-key"
    accessSecret: "your-secret-access-key"
```

If you have an existing secret for the s3 access key and access secret with `access-key-id` and `secret-access-key` seret key names respectively, configure it as follows:

```yaml
binaryData:
  mode: s3
  s3:
    host: "s3.us-east-1.amazonaws.com"
    bucketName: "your-bucket-name"
    bucketRegion: "us-east-1"
    existingSecret: "your-existing-secret"
```

## Extra Manifests

The chart supports deploying arbitrary Kubernetes resources alongside n8n using `extraManifests` and `extraTemplateManifests`. Standard chart labels (`helm.sh/chart`, `app.kubernetes.io/*`) are automatically merged into each manifest's `metadata.labels`.

### `extraManifests` — Static Manifests

Accepts a list of Kubernetes resource **objects** or raw **YAML strings**. No Helm templating is evaluated.

#### Object format

```yaml
extraManifests:
  - apiVersion: postgresql.cnpg.io/v1
    kind: Cluster
    metadata:
      name: postgresql
    spec:
      instances: 1
      enablePDB: false
      storage:
        storageClass: csi-disk
        size: 5Gi
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: my-extra-config
    data:
      key: value
```

#### String format (supports multi-document YAML with `---`)

```yaml
extraManifests:
  - |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: my-string-config
    data:
      key: value
```

### `extraTemplateManifests` — Manifests with Helm Templating

Each item must be a YAML **string** (use `|` block scalar). Helm template functions are evaluated, giving access to `.Release`, `.Values`, `.Chart`, etc.

```yaml
extraTemplateManifests:
  - |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: release-info
      namespace: {{ .Release.Namespace }}
    data:
      release: {{ .Release.Name }}
      chart: {{ .Chart.Version }}
```

## Injecting Environment Variables

Three mechanisms are available for injecting environment variables into n8n pods. Each targets a different use case — pick the one that fits your secret/config structure.

### `extraEnvVars` — Static key/value pairs

Use this when you want to set a plain string value directly in your values. Applies to `main`, `worker`, `webhook`, and `webhook.mcp` blocks.

```yaml
main:
  extraEnvVars:
    N8N_LOG_LEVEL: debug
    N8N_DEFAULT_LOCALE: en

worker:
  extraEnvVars:
    N8N_LOG_LEVEL: info
```

### `extraSecretNamesForEnvFrom` — Mount an entire Secret as environment variables

Use this when you have a Kubernetes Secret whose **keys already match the n8n environment variable names** (e.g. `N8N_SMTP_HOST`, `N8N_SMTP_PASS`). Every key in the referenced Secret is projected as an environment variable into the container.

```yaml
main:
  extraSecretNamesForEnvFrom:
    - n8n-smtp-credentials

worker:
  extraSecretNamesForEnvFrom:
    - n8n-smtp-credentials

webhook:
  extraSecretNamesForEnvFrom:
    - n8n-smtp-credentials
  mcp:
    extraSecretNamesForEnvFrom:
      - n8n-smtp-credentials
```

> **Note:** All keys in the referenced Secret are injected. If the Secret contains keys that do not follow the C identifier naming rule (e.g. `metadata-url`) or if you only want to inject specific keys, use `extraEnv` with `valueFrom` instead.

### `extraEnv` with `valueFrom` — Fine-grained env var sourcing

Use this when:

- The Secret or ConfigMap keys **do not match** n8n's expected environment variable names (e.g. the key is `metadata-url` but n8n expects `N8N_SSO_SAML_METADATA_URL`).
- You need to project only **specific keys** from a Secret rather than the entire Secret.
- You need `fieldRef` or `resourceFieldRef` sources.

Entries are passed verbatim as Kubernetes [`EnvVar`](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#environment-variables) objects, so any valid `env` entry is supported.

```yaml
main:
  extraEnv:
    - name: N8N_SSO_SAML_METADATA_URL
      valueFrom:
        secretKeyRef:
          name: n8n-okta-app-saml-config
          key: metadata-url

worker:
  extraEnv:
    - name: N8N_SSO_SAML_METADATA_URL
      valueFrom:
        secretKeyRef:
          name: n8n-okta-app-saml-config
          key: metadata-url

webhook:
  extraEnv:
    - name: N8N_SSO_SAML_METADATA_URL
      valueFrom:
        secretKeyRef:
          name: n8n-okta-app-saml-config
          key: metadata-url
  mcp:
    extraEnv:
      - name: N8N_SSO_SAML_METADATA_URL
        valueFrom:
          secretKeyRef:
            name: n8n-okta-app-saml-config
            key: metadata-url
```

You can also source values from a ConfigMap or from the pod's own fields:

```yaml
main:
  extraEnv:
    - name: MY_CONFIG_VALUE
      valueFrom:
        configMapKeyRef:
          name: my-configmap
          key: my-key
    - name: MY_POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
```

---

## Upgrading

This section outlines major updates and breaking changes for each version of the Helm Chart to help you transition smoothly between releases.

---

###  Version-Specific Upgrade Notes

#### Upgrading to Version 3.0.0

Chart version 3.0.0 removes the bundled `redis`, `postgresql` and `minio` subcharts. n8n is expected to talk to externally provided services, so the chart no longer deploys (or configures) them for you.

##### Breaking Changes

- The `postgresql` value block (and its `enabled`/`auth`/`primary` keys) is removed. With `db.type: postgresdb`, point the chart at an external database via `externalPostgresql.host`, `.username`, `.password` (or `.existingSecret`) and `.database`.
- The `redis` value block (and its `enabled` key) is removed. In queue mode, point the chart at an external Redis via `externalRedis.host`, `.port`, `.username`, `.password` (or `.existingSecret`).
- The `minio` value block is removed. With `binaryData.mode: s3`, point the chart at any S3-compatible store via `binaryData.s3.host`, `.bucketName`, `.bucketRegion`, and either `.accessKey`/`.accessSecret` or `.existingSecret`.

Any values file that still sets `postgresql.enabled`, `redis.enabled` or `minio.enabled` (or other keys under those blocks) now fails schema validation, because the root schema uses `additionalProperties: false`. Delete the `postgresql`, `redis` and `minio` top-level blocks from your values before upgrading.

If you previously relied on the bundled subcharts, provision replacement services first (an external PostgreSQL instance, an external Redis, and an S3-compatible bucket), record their connection details in `externalPostgresql.*`, `externalRedis.*` and `binaryData.s3.*`, then run the upgrade. The chart will no longer create or migrate those databases for you — back up any data stored in a bundled subchart before switching.

#### Upgrading to Version 2.0.0

Chart version 2.0.0 aligns the chart with the breaking changes introduced by n8n [2.0](https://docs.n8n.io/changelog/v20-breaking-changes) and n8n [3.0](https://docs.n8n.io/changelog/v30-breaking-changes).

##### Breaking Changes

- `binaryData.availableModes` is **no longer rendered**. n8n 2.0 dropped the `N8N_AVAILABLE_BINARY_DATA_MODES` environment variable - the field has no env binding in n8n's own config any more - so the value had no effect. The field was removed in 4.0.0 and is now rejected by the values schema; use `binaryData.mode`.
- `binaryData.mode` no longer accepts `default`. In-memory binary data is gone: n8n 2.x defaults to `filesystem` in regular mode and `database` in queue mode, and n8n 3.0 removes the `default` mode outright. The chart default is now unset (`~`), which lets n8n choose per deployment mode. Set `binaryData.mode` explicitly to `filesystem`, `database` or `s3`.
- Switching from the old `default` mode means binary data now lands on disk or in the database. Give the chosen storage enough capacity and, for `filesystem`, make sure the path is on a persistent writable volume, and include it in backups. In-memory binary data itself cannot be migrated and is lost on restart either way.
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` moved out of the hardcoded container environment into the new `<release>-security-configmap` and is configurable through `security.enforceSettingsFilePermissions`.
- `db.sqlite.poolSize` is now actually rendered as `DB_SQLITE_POOL_SIZE`, and the default changed from `0` to `3` (see below). `0` is no longer a valid value on n8n 2.x.

##### New Security Defaults (n8n 2.0)

A new `<release>-security-configmap`, consumed by every n8n container, exposes the instance security settings that n8n 2.0 changed:

|Value|Chart default|Variable|Notes|
|---|---|---|---|
|`security.enforceSettingsFilePermissions`|`true`|`N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS`|Strict `0600` permissions on configuration files, the n8n 2.0 behavior.|
|`security.blockEnvAccessInNode`|`true`|`N8N_BLOCK_ENV_ACCESS_IN_NODE`|Workflows reading `process.env` / `$env` in Code nodes and expressions stop working. Set to `false` only if you accept that every secret in the container becomes readable by anyone who can edit a Code node.|
|`security.gitNodeDisableBareRepos`|`true`|`N8N_GIT_NODE_DISABLE_BARE_REPOS`|Set to `false` only if a workflow reads a bare repository from a mounted volume.|
|`security.restrictFileAccessTo`|unset (`~`)|`N8N_RESTRICT_FILE_ACCESS_TO`|Semicolon-separated directory list for the `ReadWriteFile` / `ReadBinaryFiles` nodes. Unset inherits the n8n default, which is `~/.n8n-files` from 2.0 onwards. Set it to widen or narrow that list; set it to `""` to disable the restriction entirely (insecure).|

##### Node Loading (`NODES_EXCLUDE` / `NODES_INCLUDE`)

`nodes.exclude` and `nodes.include` are now supported (both unset by default). With n8n 2.0 the upstream default for `NODES_EXCLUDE` is `["n8n-nodes-base.executeCommand","n8n-nodes-base.localFileTrigger"]`, so those nodes stop loading unless you opt out:

```yaml
nodes:
  # load every node, including executeCommand and localFileTrigger
  exclude: []
```

##### Encryption Key Rotation (n8n 3.0) — One-Way Migration

n8n 3.0 enables encryption key rotation (`N8N_ENV_FEAT_ENCRYPTION_KEY_ROTATION=true`) by default. The chart deliberately keeps `encryptionKeyRotation.enabled: false` because **this migration cannot be rolled back**: the first instance that starts with rotation enabled rewrites all encrypted data in a new keyed format, and running again with rotation disabled afterwards makes that data permanently unreadable.

To enable it:

1. Back up your database (and confirm the backup restores).
2. Verify every main and worker instance shares the same `encryptionKey` (or `existingEncryptionKeySecret`). Mixed keys during the migration corrupt data.
3. Set `encryptionKeyRotation.enabled: true` and upgrade all instances at once, so no instance runs with rotation disabled after the rewrite.

```yaml
encryptionKeyRotation:
  enabled: true
```

If you skip this, a future n8n minor release will still flip rotation on by itself; the chart value only defers the decision, it does not disable the feature forever.

##### SQLite Pooling (`DB_SQLITE_POOL_SIZE`)

n8n 2.0 removed the legacy (non-pool) SQLite driver, so the pooling driver - WAL mode, one writer plus a pool of readers - is the only one. n8n 2.x requires `DB_SQLITE_POOL_SIZE` to be at least `1` and defaults to `3`. The chart previously documented `poolSize: 0` as "disable pooling" and never rendered the variable at all; it now defaults to `3` and renders it, and the schema rejects `0`:

```yaml
db:
  type: sqlite
  sqlite:
    poolSize: 3
```

##### Compression Node Limits (n8n 3.0)

n8n 3.0 lowered the compression node defaults from 2 GiB / 5000 ZIP entries to 256 MiB / 1000 entries. Workflows unpacking larger archives now fail unless you raise them:

```yaml
nodes:
  compression:
    maxDecompressedSizeBytes: 2147483648  # 2 GiB (pre-3.0 default)
    maxZipEntries: 5000                   # pre-3.0 default
```

##### Operational Configuration Blocks (new)

Chart 2.0.0 adds blocks for operational configuration that n8n 2.x exposes through environment variables but the chart previously had no surface for. `operations` is always rendered (it only adds a ConfigMap with safe defaults); `ssrfProtection` and `durableScheduler` are **disabled by default** (`enabled: false`) — enable them explicitly.

- `operations` — execution lifecycle and request-size limits, rendered into a dedicated operations ConfigMap consumed by every n8n container. Maps to `N8N_EXECUTIONS_TIMEOUT`, `N8N_EXECUTIONS_TIMEOUT_MAX`, the `EXECUTIONS_DATA_*` save/pruning knobs (`EXECUTIONS_DATA_PRUNE`, `_MAX_AGE`, `_PRUNE_MAX_COUNT`, `_HARD_DELETE_BUFFER`), and `N8N_PAYLOAD_SIZE_MAX` / `N8N_FORMDATA_FILE_SIZE_MAX`.
- `ssrfProtection` — application-level SSRF protection for outbound requests from user-controllable nodes (`N8N_SSRF_PROTECTION_ENABLED` plus the allowed/blocked host and IP-range lists). Available from n8n 2.12; it is defence-in-depth and does **not** replace network policy.
- `durableScheduler` — the durable, database-backed scheduler for time-based workflows (`N8N_SCHEDULER_ENABLED`, `N8N_USE_WORKFLOW_PUBLICATION_SERVICE`, `N8N_SCHEDULER_POLL_TRIGGERS_ENABLED`). Preview upstream; keep poll triggers disabled in production until stable and back up the database before upgrades that change its schema.

```yaml
# operations has no enabled flag; tune these values as needed
operations:
  timeoutMax: 7200
ssrfProtection:
  enabled: true
durableScheduler:
  enabled: true
```

##### Email and Instance Owner (new, opt-in)

- `smtp` — outbound email. Without it n8n cannot send invitations, password resets or shared-workflow notifications. Set `smtp.enabled`, `host`, `port`, `sender` and either `password` (stored in a generated `<release>-smtp` Secret) or `existingSecret`.
- `instanceOwner` — bootstrap and pin the instance owner from the environment for GitOps installs where nobody should complete a first-run form. Requires a **bcrypt** hash (`instanceOwner.passwordHash`); a plaintext password breaks login. A generated `<release>-instance-owner` Secret carries the hash, or point at an existing one with `existingSecret`.

```yaml
smtp:
  enabled: true
  host: smtp.example.com
  port: 587
  sender: "n8n <no-reply@example.com>"
  password: change-me
instanceOwner:
  enabled: true
  email: admin@example.com
  firstName: Admin
  lastName: Owner
  passwordHash: "$2b$10$..."   # bcrypt hash, not a plaintext password
```

##### n8n Assistant and Sandbox Service (new, opt-in)

- `aiAssistant` — enables the n8n Assistant and agents (`N8N_ENABLED_MODULES: instance-ai,agents`) plus its model settings (`N8N_INSTANCE_AI_MODEL`, `_MODEL_URL`, `_MCP_SERVERS`). **Preview feature upstream.** It requires a sandbox to execute AI-generated code: either the in-cluster `sandboxService` below, or an external one via `aiAssistant.sandbox.serviceUrl` + `existingApiKeySecret`.
- `aiAssistant.searxng.url` — points the Assistant at an **externally managed** SearXNG instance (`N8N_INSTANCE_AI_SEARXNG_URL`). The chart does not deploy SearXNG; run your own and set this to its base URL (it must include a scheme, `http://` or `https://`).
- `sandboxService` — deploys the n8n Sandbox Service as separate pods: a control-plane API plus an in-cluster runner that executes AI-generated code via Docker-in-Docker. Disabled by default. **Security:** the runner defaults to `isolation: privileged`, which is root-equivalent on its node — set `runner.acknowledgePrivileged: true` to accept this, pin it with `runner.nodeSelector`, prefer a runtime class (e.g. Kata Containers) where possible, and keep an unprivileged Pod Security Admission profile on every other namespace.

```yaml
aiAssistant:
  enabled: true
  searxng:
    url: https://searxng.example.com   # externally managed SearXNG
sandboxService:
  enabled: true
  runner:
    acknowledgePrivileged: true        # required for the default privileged isolation
```

##### Upstream Changes With No Chart Surface

These n8n 2.0/3.0 breaking changes are workflow-level and cannot be configured through the chart; review them in the [2.0](https://docs.n8n.io/changelog/v20-breaking-changes) and [3.0](https://docs.n8n.io/changelog/v30-breaking-changes) changelogs before upgrading: Chat Hub retirement and the removal of importing workflows from a URL, the legacy Function / Function Item nodes, the removed `$getPairedItem` expression variable, and AI Agent v1 no longer being creatable.

#### Upgrading to Version 1.20.0

##### Deprecation Notices

- The `license.autoNenew` field was a typo and is now deprecated in favour of `license.autoRenew`.

##### Action Required

Replace any usage of `license.autoNenew` with `license.autoRenew` in your values:

```yaml
# Before (deprecated)
license:
  autoNenew:
    enabled: false
    offsetInHours: 24

# After
license:
  autoRenew:
    enabled: false
    offsetInHours: 24
```

The deprecated field still works for now (values are forwarded automatically), but it will be removed in a future release.

#### Upgrading to Version 1.13.1

##### Action Required

Pleae do not use 1.13.0 chart. It contains selector labels breaking changes. Please consider to upgrade 1.13.1 or higher hotfix version directly.

#### Upgrading to Version 1.11.x

##### Deprecation Notices

- The top-level field `affinity` is deprecated.

##### Action Required

Please consider using the corresponding fields in the `main`, `worker` and `webhook` blocks instead. The deprecated field will be removed in the next major release.

#### Upgrading to Version 1.7.x

##### Deprecation Notices

- The top-level fields `livenessProbe`, and `readinessProbe` are deprecated.

##### Action Required

Please consider using the corresponding fields in the `main`, `worker` and `webhook` blocks instead. The deprecated fields will be removed in the next major release.
The Worker and Webhook nodes no longer include a default init container to wait for the main node to become ready. If this behavior is required, please enable it explicitly by setting `worker.waitMainNodeReady.enabled` and `webhook.waitMainNodeReady.enabled` to `true`.

#### Upgrading to Version 1.3.1

##### Deprecation Notices

* **Secret Name Change**: The secret `RELEASE_NAME-encryption-key-secret` is deprecated. Starting with this release, the chart now uses `RELEASE_NAME-encryption-key-secret-v2` to manage the `N8N_ENCRYPTION_KEY`. This change ensures compatibility with Helm's resource ownership model and resolves previous upgrade issues.

##### Actions Required

* **Verify the Upgrade**: After successfully upgrading to version 1.3.1, confirm that your `n8n` deployment is using the new secret (`RELEASE_NAME-encryption-key-secret-v2`). The old secret (`RELEASE_NAME-encryption-key-secret`) is preserved in the namespace and will not be automatically deleted.
* **Optional Cleanup**: If the old secret is no longer needed, you may manually remove it from your namespace using the following command:
bash

```bash
kubectl delete secret RELEASE_NAME-encryption-key-secret -n YOUR_NAMESPACE
```

Replace `RELEASE_NAME` and `YOUR_NAMESPACE` with your specific release name and namespace.

#### Upgrading to Version 1.2.x

##### Deprecation Notices

- The top-level fields `extraEnvVars`, `extraSecretNamesForEnvFrom`, `resources`, `volumes` and `volumeMounts` are deprecated.

##### Action Required

Please consider using the corresponding fields in the `main`, `worker` and `webhook` blocks instead. The deprecated fields will be removed in the next major release.

#### Upgrading to Version 1.x.x

##### Breaking Changes

- The `diagnostics.externalTaskRunnersSentryDsn` setting has been relocated to `sentry.externalTaskRunnersDsn`.

##### Action Required

If you previously configured `diagnostics.externalTaskRunnersSentryDsn`, update your configuration to use `sentry.externalTaskRunnersDsn`. Ensure that any associated flags are enabled as needed.

## Requirements

Kubernetes: `>=1.23.0-0`

## Uninstall Helm Chart

```console
helm uninstall [RELEASE_NAME]
```

This removes all the Kubernetes components associated with the chart and deletes the release.

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

## Upgrading Chart

```console
helm upgrade [RELEASE_NAME] oci://ghcr.io/suneetk92/n8n --version 4.1.1
```

### To 4.0.0

Eleven deprecated values were removed. They are now **rejected** by `values.schema.json`, so an
upgrade that still sets any of them fails with a validation error naming the key — it will not
silently drop your setting. Migrate them first.

**Nine root-level values move into the per-component block that already replaced them.** Set them
under `main`, `worker`, `webhook` and/or `webhook.mcp` — each component takes its own value, so
repeat it for every component that needs it:

| Removed | Replacement |
|---|---|
| `extraEnvVars` | `main.extraEnvVars`, `worker.extraEnvVars`, `webhook.extraEnvVars`, `webhook.mcp.extraEnvVars` |
| `extraEnv` | `<component>.extraEnv` |
| `extraSecretNamesForEnvFrom` | `<component>.extraSecretNamesForEnvFrom` |
| `resources` | `<component>.resources` |
| `livenessProbe` | `<component>.livenessProbe` |
| `readinessProbe` | `<component>.readinessProbe` |
| `volumes` | `<component>.volumes` |
| `volumeMounts` | `<component>.volumeMounts` |
| `affinity` | `<component>.affinity` |

```yaml
# before
resources:
  limits: {cpu: 500m, memory: 512Mi}

# after
main:
  resources:
    limits: {cpu: 500m, memory: 512Mi}
worker:
  resources:
    limits: {cpu: 500m, memory: 512Mi}
```

Note that `livenessProbe` and `readinessProbe` were previously *deep-merged* with the component
value, so if you relied on setting part of a probe at the root and the rest per component, the
component block must now carry the whole probe.

**Two others:**

| Removed | Replacement |
|---|---|
| `license.autoNenew.enabled` / `.offsetInHours` | `license.autoRenew.enabled` / `.offsetInHours` (`autoNenew` was a misspelling) |
| `binaryData.availableModes` | `binaryData.mode` — the old key had been ignored since 3.0.0, because n8n 2.0 removed `N8N_AVAILABLE_BINARY_DATA_MODES` |

To find what you need to change before upgrading:

```console
helm get values <release> -n <namespace>
```

### To 3.3.0

**Only affects installs with `sandboxService.enabled: true`.** If you do not run the sandbox, this
upgrade needs no manual steps.

The sandbox API and runner previously carried `app.kubernetes.io/name: n8n`, the same value the main
`n8n` Service selects on, so that Service adopted the sandbox pods as endpoints and served a large
share of requests from the wrong pod. Their selectors now use dedicated `n8n-sandbox-api` and
`n8n-sandbox-runner` names.

`spec.selector` is immutable on a Deployment and a StatefulSet, so **delete the two sandbox
workloads before upgrading**, otherwise Helm fails with a "field is immutable" error:

```console
kubectl delete deployment <release>-sandbox-api -n <namespace>
kubectl delete statefulset <release>-sandbox-runner -n <namespace>
helm upgrade [RELEASE_NAME] oci://ghcr.io/suneetk92/n8n --version 4.1.1
```

Deleting them is safe: sandboxes are ephemeral, the API's state lives on its PVC, and the certificate
Secrets are owned by cert-manager (or by you, under `existingSecret`). After upgrading, confirm the
main Service has exactly one endpoint:

```console
kubectl get endpoints <release> -n <namespace>
```

### To 3.2.0

Two changes can make an upgrade fail that previously succeeded. Neither removes or renames a value.

**`sandboxService` now requires its TLS certificate Secrets to be resolvable.** `tls.mode` defaults
to `existingSecret`, and the chart previously fell back to derived `<release>-sandbox-*-tls` names
that it never creates — so the API and runner pods mounted Secrets that did not exist and sat in
`FailedMount` indefinitely. If you run the sandbox, pick one:

- Supply the four Secrets yourself and set every
  `sandboxService.tls.certificates.*.secretName`, or
- Set `sandboxService.tls.mode: certManager` with `sandboxService.tls.certManager.issuerRef`.

For `certManager`, the issuer must be a **CA-type** issuer (`selfSigned` or `ca`). An ACME issuer
cannot work: two of the four certificates are `client auth` certificates carrying a `commonName`
with no `dnsNames`, which ACME rejects, and ACME never populates the `ca.crt` both sides need to
verify each other. A dedicated private CA is the recommended setup:

```yaml
# Issuer/n8n-sandbox-selfsigned (selfSigned) -> Certificate (isCA: true) -> Issuer (ca)
sandboxService:
  tls:
    mode: certManager
    certManager:
      issuerRef:
        name: n8n-sandbox-ca-issuer
        kind: Issuer
        group: cert-manager.io
```

**`values.schema.json` is stricter.** `securityContext.privileged`, `securityContext.runAsGroup`,
the same two on `waitContainerSecurityContext`, and `strategy.rollingUpdate` are now declared, so a
typo or wrong type in any of them is rejected at install instead of being silently ignored.

Also note that four previously inert values now take effect:
`sandboxService.tls.certManager.duration` / `renewBefore` (cert-manager was silently applying its
own 90d/30d defaults), `db.sqlite.database`, `db.postgresdb.ssl.rejectUnauthorized` and
`npmRegistry.url`. If you set any of them to something other than the chart default, review it
before upgrading — it will now actually be applied.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aiAssistant | object | `{"enabled":false,"existingModelApiKeySecret":"","mcpServers":"","model":"anthropic/claude-opus-4-8","modelApiKey":"","modelApiKeyKey":"api-key","modelUrl":"","modules":["instance-ai"],"sandbox":{"apiKeyKey":"api-key","enabled":false,"existingApiKeySecret":"","provider":"n8n-sandbox","serviceUrl":""},"searxng":{"url":""}}` | n8n Assistant and agents (`instance-ai`, `agents`). Preview feature; available on self-hosted Community, Registered Community and Business, not self-hosted Enterprise. Requires a sandbox; see `sandboxService`. |
| aiAssistant.enabled | bool | `false` | Enable the AI module surface and render its ConfigMap. Does not by itself pick modules; see `modules`. |
| aiAssistant.existingModelApiKeySecret | string | `""` | Existing secret holding the model API key, exposed as `N8N_INSTANCE_AI_MODEL_API_KEY`. When empty, n8n falls back to the provider's own environment variable and to in-UI configuration. |
| aiAssistant.mcpServers | string | `""` | MCP servers the assistant may use (`N8N_INSTANCE_AI_MCP_SERVERS`), as a JSON string. |
| aiAssistant.model | string | `"anthropic/claude-opus-4-8"` | Model in `provider/model` form (`N8N_INSTANCE_AI_MODEL`). Supported providers: `anthropic`, `openai`, `openrouter`. |
| aiAssistant.modelApiKey | string | `""` | Model API key written into the chart-managed Secret as `N8N_INSTANCE_AI_MODEL_API_KEY`. Ignored when `existingModelApiKeySecret` is set. Prefer `existingModelApiKeySecret` so the key stays out of your values file. |
| aiAssistant.modelApiKeyKey | string | `"api-key"` | Key inside `existingModelApiKeySecret` that holds the API key. |
| aiAssistant.modelUrl | string | `""` | OpenAI-compatible endpoint for a local or custom model server (`N8N_INSTANCE_AI_MODEL_URL`). Leave empty to use the provider's hosted API. |
| aiAssistant.modules | list | `["instance-ai"]` | Modules to load via `N8N_ENABLED_MODULES`, for example `["instance-ai", "agents"]`. `agents` can be run without `instance-ai`; keep both for AI-assisted agent building. |
| aiAssistant.sandbox | object | `{"apiKeyKey":"api-key","enabled":false,"existingApiKeySecret":"","provider":"n8n-sandbox","serviceUrl":""}` | Sandbox used to run AI-generated code. Required for n8n Assistant. |
| aiAssistant.sandbox.apiKeyKey | string | `"api-key"` | Key inside `existingApiKeySecret` that holds the API key. |
| aiAssistant.sandbox.enabled | bool | `false` | Point n8n at a sandbox service (`N8N_INSTANCE_AI_SANDBOX_ENABLED`). |
| aiAssistant.sandbox.existingApiKeySecret | string | `""` | Existing secret holding the sandbox API key, exposed as `N8N_SANDBOX_SERVICE_API_KEY`. Must match a value in the sandbox service's `SANDBOX_API_KEYS`. When empty and `sandboxService.enabled` is `true`, the chart reuses that service's generated key. |
| aiAssistant.sandbox.provider | string | `"n8n-sandbox"` | Sandbox provider (`N8N_INSTANCE_AI_SANDBOX_PROVIDER`). The chart supports `n8n-sandbox`; use `external` when the service runs outside this cluster. |
| aiAssistant.sandbox.serviceUrl | string | `""` | Sandbox API URL (`N8N_SANDBOX_SERVICE_URL`). Defaults to the in-cluster `sandboxService` URL when it is enabled; set it explicitly for an external service. |
| aiAssistant.searxng | object | `{"url":""}` | Web search backend for the assistant. |
| aiAssistant.searxng.url | string | `""` | SearXNG base URL (`N8N_INSTANCE_AI_SEARXNG_URL`) of an externally managed SearXNG instance. Must include a scheme (http:// or https://). |
| api.enabled | bool | `true` | Whether to enable the Public API |
| api.path | string | `"api"` | Path segment for the Public API |
| api.swagger | object | `{"enabled":true}` | Whether to enable the Swagger UI for the Public API |
| binaryData | object | `{"databaseMaxFileSize":512,"localStoragePath":"","mode":null,"s3":{"accessKey":"","accessSecret":"","bucketName":"","bucketRegion":"us-east-1","existingSecret":"","host":""}}` | Configuration for binary data storage |
| binaryData.databaseMaxFileSize | int | `512` | Maximum size (in MiB) of a single file n8n stores when `binaryData.mode` is `database`. Cannot exceed `1024`, which is the database column limit; storing a larger file fails. Only rendered when `binaryData.mode` is `database`. |
| binaryData.localStoragePath | string | `""` | Path for binary data storage in `filesystem` mode. If not set, n8n uses `<N8N_USER_FOLDER>/binaryData`. For more information, see https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/use-environment-variables/binary-data/ |
| binaryData.mode | string | `nil` | The binary data mode. `filesystem` stores binary data on disk, `database` in the database, `s3` in an S3-compatible store. Leave unset (`~`) to use the n8n default for the deployment mode: `filesystem` in regular mode, `database` in queue mode. Note that n8n 2.0 removed the in-memory mode, so `default` is no longer accepted. Binary data pruning operates on the active mode only. For more information, see https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/use-environment-variables/binary-data/ |
| binaryData.s3 | object | `{"accessKey":"","accessSecret":"","bucketName":"","bucketRegion":"us-east-1","existingSecret":"","host":""}` | S3-compatible external storage configurations. Only used when `binaryData.mode` is `s3`. For more information, see https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/use-environment-variables/external-data-storage/ |
| binaryData.s3.accessKey | string | `""` | Access key in S3-compatible external storage |
| binaryData.s3.accessSecret | string | `""` | Access secret in S3-compatible external storage. |
| binaryData.s3.bucketName | string | `""` | Name of the n8n bucket in S3-compatible external storage. |
| binaryData.s3.bucketRegion | string | `"us-east-1"` | Region of the n8n bucket in S3-compatible external storage. For example, us-east-1 |
| binaryData.s3.existingSecret | string | `""` | This is for setting up the s3 file storage existing secret. Must contain access-key-id and secret-access-key keys. |
| binaryData.s3.host | string | `""` | Host of the n8n bucket in S3-compatible external storage. For example, s3.us-east-1.amazonaws.com |
| db | object | `{"logging":{"enabled":false,"maxQueryExecutionTime":0,"options":"error"},"postgresdb":{"connectionTimeout":20000,"idleConnectionTimeout":30000,"poolSize":2,"schema":"public","ssl":{"base64EncodedCertFile":"","base64EncodedCertificateAuthorityFile":"","base64EncodedPrivateKeyFile":"","enabled":false,"existingCertFileSecret":{"key":"cert.crt","name":""},"existingCertificateAuthorityFileSecret":{"key":"ca.crt","name":""},"existingPrivateKeyFileSecret":{"key":"cert.key","name":""},"rejectUnauthorized":true}},"sqlite":{"database":"database.sqlite","poolSize":3,"vacuum":false},"tablePrefix":"","type":"sqlite"}` | n8n database configurations |
| db.logging.enabled | bool | `false` | Whether database logging is enabled. |
| db.logging.maxQueryExecutionTime | int | `0` | Only queries that exceed this time (ms) will be logged. Set `0` to disable. |
| db.logging.options | string | `"error"` | Database logging level. Requires `maxQueryExecutionTime` to be higher than `0`. Valid values 'query' | 'error' | 'schema' | 'warn' | 'info' | 'log' | 'all' |
| db.postgresdb.connectionTimeout | int | `20000` | Postgres connection timeout (ms). |
| db.postgresdb.idleConnectionTimeout | int | `30000` | Amount of time before an idle connection is eligible for eviction for being idle. |
| db.postgresdb.poolSize | int | `2` | Control how many parallel open Postgres connections n8n should have. Increasing it may help with resource utilization, but too many connections may degrade performance. |
| db.postgresdb.schema | string | `"public"` | The PostgreSQL schema. |
| db.postgresdb.ssl | object | `{"base64EncodedCertFile":"","base64EncodedCertificateAuthorityFile":"","base64EncodedPrivateKeyFile":"","enabled":false,"existingCertFileSecret":{"key":"cert.crt","name":""},"existingCertificateAuthorityFileSecret":{"key":"ca.crt","name":""},"existingPrivateKeyFileSecret":{"key":"cert.key","name":""},"rejectUnauthorized":true}` | The PostgreSQL connection SSL settings. Find more information from here: https://docs.n8n.io/hosting/configuration/supported-databases-settings/#postgresdb |
| db.postgresdb.ssl.base64EncodedCertFile | string | `""` | The PostgreSQL base64 encoded version of SSL certificate file content. |
| db.postgresdb.ssl.base64EncodedCertificateAuthorityFile | string | `""` | The PostgreSQL base64 encoded version of SSL certificate authority file content. |
| db.postgresdb.ssl.base64EncodedPrivateKeyFile | string | `""` | The PostgreSQL base64 encoded version of SSL private key file content. |
| db.postgresdb.ssl.enabled | bool | `false` | Whether to enable SSL. |
| db.postgresdb.ssl.existingCertFileSecret | object | `{"key":"cert.crt","name":""}` | The PostgreSQL existing certificate file secret. |
| db.postgresdb.ssl.existingCertFileSecret.key | string | `"cert.crt"` | The key of the certificate file in the existing secret. |
| db.postgresdb.ssl.existingCertFileSecret.name | string | `""` | The name of the existing secret. |
| db.postgresdb.ssl.existingCertificateAuthorityFileSecret | object | `{"key":"ca.crt","name":""}` | The PostgreSQL existing certificate authority file secret. |
| db.postgresdb.ssl.existingCertificateAuthorityFileSecret.key | string | `"ca.crt"` | The key of the certificate authority file in the existing secret. |
| db.postgresdb.ssl.existingCertificateAuthorityFileSecret.name | string | `""` | The name of the existing secret. |
| db.postgresdb.ssl.existingPrivateKeyFileSecret | object | `{"key":"cert.key","name":""}` | The PostgreSQL existing SSL private key file secret. |
| db.postgresdb.ssl.existingPrivateKeyFileSecret.key | string | `"cert.key"` | The key of the SSL private key file in the existing secret. |
| db.postgresdb.ssl.existingPrivateKeyFileSecret.name | string | `""` | The name of the existing secret. |
| db.postgresdb.ssl.rejectUnauthorized | bool | `true` | If n8n should reject unauthorized SSL connections (true) or not (false). |
| db.sqlite.database | string | `"database.sqlite"` | SQLite database file name |
| db.sqlite.poolSize | int | `3` | SQLite database pool size (`DB_SQLITE_POOL_SIZE`). n8n 2.0 removed the legacy driver, so this pooling driver (WAL mode, one writer plus a pool of readers) is the only one. Must be at least `1`; n8n defaults to `3`. |
| db.sqlite.vacuum | bool | `false` | Runs VACUUM operation on startup to rebuild the database. Reduces file size and optimizes indexes. This is a long running blocking operation and increases start-up time. |
| db.tablePrefix | string | `""` | Prefix to use for table names. |
| db.type | string | `"sqlite"` | Type of database to use. Valid values 'sqlite' | 'postgresdb' |
| defaultLocale | string | `"en"` | A locale identifier, compatible with the Accept-Language header. n8n doesn't support regional identifiers, such as de-AT. |
| diagnostics.backendConfig | string | `"1zPn7YoGC3ZXE9zLeTKLuQCB4F6;https://telemetry.n8n.io"` | Diagnostics config for backend. |
| diagnostics.enabled | bool | `false` | Whether diagnostics are enabled. |
| diagnostics.frontendConfig | string | `"1zPn9bgWPzlQc0p8Gj1uiK6DOTn;https://telemetry.n8n.io"` | Diagnostics config for frontend. |
| diagnostics.postHog.apiHost | string | `"https://ph.n8n.io"` | API host for PostHog. |
| diagnostics.postHog.apiKey | string | `"phc_4URIAm1uYfJO7j8kWSe0J8lc8IqnstRLS7Jx8NcakHo"` | API key for PostHog. |
| dnsConfig | object | `{}` | For more information checkout: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-dns-config |
| dnsPolicy | string | `""` | For more information checkout: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy |
| durableScheduler | object | `{"allowSkip":false,"durableCursors":false,"enabled":false,"pollTriggers":false}` | Durable, database-backed scheduler for time-based workflows. Available from n8n 2.36 (Preview from 2.32). Requires `operations`-independent Postgres or SQLite; runs on main instances. |
| durableScheduler.allowSkip | bool | `false` | Show a per-node "Skip Durable Scheduler" option to keep individual triggers on the in-memory scheduler (`N8N_ENV_FEAT_SKIP_DURABLE_SCHEDULER`). Temporary upstream escape hatch. |
| durableScheduler.durableCursors | bool | `false` | Store each poll's cursor transactionally so a crash mid-poll cannot drop or duplicate data (`N8N_POLLER_DURABLE_CURSORS_ENABLED`). Requires `enabled` and `pollTriggers`. |
| durableScheduler.enabled | bool | `false` | Take over Schedule Trigger nodes (`N8N_SCHEDULER_ENABLED`). Setting this to `true` also enables the workflow publication service, which n8n requires for the scheduler to take effect - enabling one without the other is a silent no-op. |
| durableScheduler.pollTriggers | bool | `false` | Also take over poll triggers such as Google Sheets Trigger (`N8N_SCHEDULER_POLL_TRIGGERS_ENABLED`). Upstream warns this is not yet fully stable; keep it off in production. Requires `enabled`. |
| encryptionKey | string | `""` | If you install n8n first time, you can keep this empty and it will be auto generated and never change again. If you already have a encryption key generated before, please use it here. |
| encryptionKeyRotation | object | `{"enabled":false}` | Encryption key rotation (`N8N_ENV_FEAT_ENCRYPTION_KEY_ROTATION`). n8n 3.0 enables this by default.   WARNING: this is a one-way migration. The first instance to start with it enabled rewrites all encrypted data in a new format.   Once rewritten, running with rotation disabled makes that data permanently unreadable and there is no way back.   Every main and worker instance must share the same `encryptionKey` at all times, including during the migration.   Back up the database before enabling this. The chart leaves it `false` so that upgrading the chart cannot silently start an   irreversible migration; set it to `true` deliberately once the backup exists. |
| encryptionKeyRotation.enabled | bool | `false` | Enable encryption key rotation. One-way; see the warning above. |
| existingEncryptionKeySecret | string | `""` | The name of an existing secret with encryption key. The secret must contain a key with the name N8N_ENCRYPTION_KEY. |
| externalPostgresql | object | `{"database":"n8n","existingSecret":"","existingSecretPasswordKey":"","host":"","password":"","port":5432,"username":"postgres"}` | External PostgreSQL parameters |
| externalPostgresql.database | string | `"n8n"` | The name of the external PostgreSQL database. For more information: https://docs.n8n.io/hosting/configuration/supported-databases-settings/#required-permissions |
| externalPostgresql.existingSecret | string | `""` | The name of an existing secret with PostgreSQL (must contain key `postgres-password`) and credentials. When it's set, the `externalPostgresql.password` parameter is ignored |
| externalPostgresql.existingSecretPasswordKey | string | `""` | The key in `externalPostgresql.existingSecret` that stores the PostgreSQL password. |
| externalPostgresql.host | string | `""` | External PostgreSQL server host |
| externalPostgresql.password | string | `""` | External PostgreSQL password |
| externalPostgresql.port | int | `5432` | External PostgreSQL server port |
| externalPostgresql.username | string | `"postgres"` | External PostgreSQL username |
| externalRedis | object | `{"clusterNodes":[],"database":0,"dualStack":false,"existingPasswordKey":"","existingSecret":"","existingUsernameKey":"","host":"","password":"","port":6379,"tls":{"enabled":false},"username":""}` | External Redis parameters |
| externalRedis.clusterNodes | list | `[]` | List of Redis Cluster nodes. Setting this variable will create a Redis Cluster client instead of a Redis client, and n8n will ignore `externalRedis.host` and `externalRedis.port`. |
| externalRedis.database | int | `0` | Redis database for Bull queue. |
| externalRedis.dualStack | bool | `false` | Enable dual-stack support (IPv4 and IPv6) on Redis connections. |
| externalRedis.existingPasswordKey | string | `""` | The key in `externalRedis.existingSecret` that stores the Redis password. |
| externalRedis.existingSecret | string | `""` | The name of an existing secret with Redis (must contain key `redis-password`) and Sentinel credentials. When it's set, the `externalRedis.password` parameter is ignored |
| externalRedis.existingUsernameKey | string | `""` | The key in `externalRedis.existingSecret` that stores the Redis username. |
| externalRedis.host | string | `""` | External Redis server host |
| externalRedis.password | string | `""` | External Redis password |
| externalRedis.port | int | `6379` | External Redis server port |
| externalRedis.tls | object | `{"enabled":false}` | Placeholder for future Redis TLS certificates |
| externalRedis.tls.enabled | bool | `false` | Enable TLS on Redis connections. |
| externalRedis.username | string | `""` | External Redis username |
| extraManifests | list | `[]` | List of extra Kubernetes manifests (objects or YAML strings) to deploy alongside n8n. Chart labels are automatically merged into each manifest's metadata. |
| extraTemplateManifests | list | `[]` | List of extra Kubernetes manifests as Helm template strings to deploy alongside n8n. Chart labels are automatically merged into each manifest's metadata. |
| fullnameOverride | string | `""` |  |
| gracefulShutdownTimeout | int | `30` | graceful shutdown timeout in seconds |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"n8nio/n8n","tag":""}` | This sets the container image more information can be found here: https://kubernetes.io/docs/concepts/containers/images/ |
| image.pullPolicy | string | `"IfNotPresent"` | This sets the pull policy for images. |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | This is for the secretes for pulling an image from a private repository more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"n8n.local","paths":[{"path":"/","pathType":"Prefix"}]}],"tls":[]}` | This block is for setting up the ingress for more information can be found here: https://kubernetes.io/docs/concepts/services-networking/ingress/ |
| instanceOwner | object | `{"email":"","enabled":false,"existingSecret":"","firstName":"","lastName":"","passwordHash":"","passwordHashKey":"password-hash"}` | Bootstrap and pin the instance owner from the environment, for GitOps installations where nobody should have to complete a first-run form. |
| instanceOwner.email | string | `""` | Owner email address (`N8N_INSTANCE_OWNER_EMAIL`). Must not already belong to another user on the instance. |
| instanceOwner.enabled | bool | `false` | Manage the instance owner from environment variables (`N8N_INSTANCE_OWNER_MANAGED_BY_ENV`). While `true` n8n overwrites the owner details on every startup, locks those fields in the UI and rejects API writes. |
| instanceOwner.existingSecret | string | `""` | Existing secret holding a bcrypt hash of the owner password, exposed as `N8N_INSTANCE_OWNER_PASSWORD_HASH`. The value must be a bcrypt hash; a plaintext password breaks login. |
| instanceOwner.firstName | string | `""` | Owner first name (`N8N_INSTANCE_OWNER_FIRST_NAME`). |
| instanceOwner.lastName | string | `""` | Owner last name (`N8N_INSTANCE_OWNER_LAST_NAME`). |
| instanceOwner.passwordHash | string | `""` | Bcrypt hash of the owner password, written into the chart-managed Secret as `N8N_INSTANCE_OWNER_PASSWORD_HASH`. Ignored when `existingSecret` is set. Generate one with `npx bcrypt '<password>'`; a plaintext value here breaks login and commits a credential. |
| instanceOwner.passwordHashKey | string | `"password-hash"` | Key inside `existingSecret` that holds the bcrypt hash. |
| license | object | `{"activationKey":"","autoRenew":{"enabled":true,"offsetInHours":72},"enabled":false,"existingActivationKeySecret":"","serverUrl":"https://license.n8n.io/v1","tenantId":1}` | n8n enterprise license configurations |
| license.activationKey | string | `""` | Activation key to initialize license. Not applicable if the n8n instance was already activated. For more information please refer to the following link: https://docs.n8n.io/enterprise-key/ |
| license.autoRenew | object | `{"enabled":true,"offsetInHours":72}` | The auto new license configuration |
| license.autoRenew.enabled | bool | `true` | Enables (true) or disables (false) autorenewal for licenses. If disabled, you need to manually renew the license every 10 days by navigating to Settings > Usage and plan, and pressing F5. Failure to renew the license will disable Enterprise features. |
| license.autoRenew.offsetInHours | int | `72` | Time in hours before expiry a license should automatically renew. |
| license.enabled | bool | `false` | Whether to enable the enterprise license |
| license.existingActivationKeySecret | string | `""` | The name of an existing secret with license activation key. The secret must contain a key with the name N8N_LICENSE_ACTIVATION_KEY. |
| license.serverUrl | string | `"https://license.n8n.io/v1"` | Server URL to retrieve license. |
| license.tenantId | int | `1` | Tenant ID associated with the license. Only set this variable if explicitly instructed by n8n. |
| log | object | `{"file":{"location":"/home/node/.n8n/logs/n8n.log","maxcount":"100","maxsize":16},"format":"text","level":"info","output":["console"],"scopes":[]}` | n8n log configurations |
| log.file.location | string | `"/home/node/.n8n/logs/n8n.log"` | Absolute path for the log file. Must be inside a writable volume (e.g. the n8n data volume at `/home/node/.n8n`). Only for `file` log output. |
| log.file.maxcount | string | `"100"` | Max number of log files to keep, or max number of days to keep logs for. Once the limit is reached, the oldest log files will be rotated out. If using days, append a `d` suffix. Only for `file` log output. |
| log.file.maxsize | int | `16` | The maximum size (in MB) for each log file. By default, n8n uses 16 MB. |
| log.format | string | `"text"` | Log output format. `text` prints human-readable messages; `json` prints one JSON object per line (useful for log aggregation pipelines). |
| log.level | string | `"info"` | The log output level. The available options are (from lowest to highest level) are error, warn, info, and debug. The default value is info. You can learn more about these options [here](https://docs.n8n.io/hosting/logging-monitoring/logging/#log-levels). |
| log.output | list | `["console"]` | Where to output logs to. Options are: `console` or `file` or both. |
| log.scopes | list | `[]` | Scopes to filter logs by. Nothing is filtered by default. Supported log scopes: concurrency, external-secrets, license, multi-main-setup, pubsub, redis, scaling, waiting-executions |
| main | object | `{"affinity":{},"count":1,"editorBaseUrl":"","extraContainers":[],"extraEnv":[],"extraEnvVars":{},"extraSecretNamesForEnvFrom":[],"forceToUseStatefulset":false,"hostAliases":[],"initContainers":[],"livenessProbe":{"httpGet":{"path":"/healthz","port":"http"}},"pdb":{"enabled":true,"maxUnavailable":1,"minAvailable":null,"unhealthyPodEvictionPolicy":"AlwaysAllow"},"persistence":{"accessMode":"ReadWriteOnce","annotations":{"helm.sh/resource-policy":"keep"},"enabled":false,"existingClaim":"","labels":{},"mountPath":"/home/node/.n8n","size":"8Gi","storageClass":"","subPath":"","volumeName":""},"readinessProbe":{"httpGet":{"path":"/healthz/readiness","port":"http"}},"resources":{},"runtimeClassName":"","volumeMounts":[],"volumes":[]}` | Main node configurations |
| main.affinity | object | `{}` | Main node affinity. For more information checkout: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity |
| main.count | int | `1` | Number of main nodes. Only enterprise license users can have one leader main node and multiple follower main nodes.    Setting this above 1 enables multi-main (`N8N_MULTI_MAIN_SETUP_ENABLED`): all main instances must share the same    database, encryption key and Redis, and n8n needs a queue backend (`worker.mode: queue`) plus an Enterprise licence    upstream for the extra replicas to take over scheduling. With a Community licence they cannot schedule executions. |
| main.editorBaseUrl | string | `""` | Editor based URL. If it's not defined and ingress definition exists, ingress host will be used. |
| main.extraContainers | list | `[]` | Additional containers for the main pod |
| main.extraEnv | list | `[]` | Extra environment variables that support `valueFrom` (e.g., secretKeyRef, configMapKeyRef). Entries are passed through verbatim and rendered after `extraEnvVars`. |
| main.extraEnvVars | object | `{}` | Extra environment variables |
| main.extraSecretNamesForEnvFrom | list | `[]` | Extra secrets for environment variables |
| main.forceToUseStatefulset | bool | `false` | Force to use statefulset for the main pod. If true, the main pod will be created as a statefulset. |
| main.hostAliases | list | `[]` | Host aliases for the main pod. For more information checkout: https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/#adding-additional-entries-with-hostaliases |
| main.initContainers | list | `[]` | Additional init containers for the main pod |
| main.livenessProbe | object | `{"httpGet":{"path":"/healthz","port":"http"}}` | This is to setup the liveness probe for the main pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| main.pdb | object | `{"enabled":true,"maxUnavailable":1,"minAvailable":null,"unhealthyPodEvictionPolicy":"AlwaysAllow"}` | Whether to enable the PodDisruptionBudget for the main pod. |
| main.pdb.enabled | bool | `true` | Whether to enable the PodDisruptionBudget |
| main.pdb.maxUnavailable | int | `1` | Maximum number of unavailable replicas |
| main.pdb.minAvailable | string | `nil` | Minimum number of available replicas |
| main.pdb.unhealthyPodEvictionPolicy | string | `"AlwaysAllow"` | Unhealty main pod eviction policy |
| main.persistence | object | `{"accessMode":"ReadWriteOnce","annotations":{"helm.sh/resource-policy":"keep"},"enabled":false,"existingClaim":"","labels":{},"mountPath":"/home/node/.n8n","size":"8Gi","storageClass":"","subPath":"","volumeName":""}` | Persistence configuration for the main pod |
| main.persistence.accessMode | string | `"ReadWriteOnce"` | Access mode for persistence |
| main.persistence.annotations | object | `{"helm.sh/resource-policy":"keep"}` | Annotations for persistence |
| main.persistence.enabled | bool | `false` | Whether to enable persistence |
| main.persistence.existingClaim | string | `""` | Existing claim to use for persistence |
| main.persistence.labels | object | `{}` | Labels for persistence |
| main.persistence.mountPath | string | `"/home/node/.n8n"` | Mount path for persistence |
| main.persistence.size | string | `"8Gi"` | Size for persistence |
| main.persistence.storageClass | string | `""` | Storage class for persistence |
| main.persistence.subPath | string | `""` | Sub path for persistence |
| main.persistence.volumeName | string | `""` | Name of the volume to use for persistence |
| main.readinessProbe | object | `{"httpGet":{"path":"/healthz/readiness","port":"http"}}` | This is to setup the readiness probe for the main pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| main.resources | object | `{}` | This block is for setting up the resource management for the main pod more information can be found here: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| main.runtimeClassName | string | `""` | Runtime class name for the main pod. For more information checkout: https://kubernetes.io/docs/concepts/containers/runtime-class/ |
| main.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| main.volumes | list | `[]` | Additional volumes on the output Deployment definition. |
| nameOverride | string | `""` | This is to override the chart name. |
| nodeSelector | object | `{}` | For more information checkout: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector |
| nodes | object | `{"builtin":{"enabled":false,"modules":[]},"compression":{"maxDecompressedSizeBytes":null,"maxZipEntries":null},"exclude":null,"external":{"allowAll":false,"packages":[],"persistence":{"accessMode":"ReadWriteOnce","annotations":{},"enabled":false,"existingClaim":"","size":"1Gi","storageClass":""},"reinstallMissingPackages":false},"include":null,"initContainer":{"image":{"pullPolicy":"IfNotPresent","repository":"node","tag":"20-alpine"},"resources":{}},"python":{"builtin":{"modules":[]},"enabled":false,"external":{"allowAll":false,"packages":[]},"persistence":{"accessMode":"ReadWriteOnce","annotations":{},"enabled":false,"existingClaim":"","size":"1Gi","storageClass":""}}}` | Node configurations for built-in and external npm packages |
| nodes.builtin | object | `{"enabled":false,"modules":[]}` | Enable built-in node functions (e.g., HTTP Request, Code Node, etc.) |
| nodes.builtin.enabled | bool | `false` | Enable built-in modules for the Code node |
| nodes.builtin.modules | list | `[]` | List of built-in Node.js modules to allow in the Code node (e.g., crypto, fs). Use '*' to allow all. |
| nodes.compression | object | `{"maxDecompressedSizeBytes":null,"maxZipEntries":null}` | Compression node limits. n8n 3.0 lowered the upstream defaults from 2 GiB / 5000 entries to 256 MiB / 1000 entries; raise them here if workflows unpack larger archives. |
| nodes.compression.maxDecompressedSizeBytes | string | `nil` | Maximum total decompressed output size in bytes (`N8N_COMPRESSION_NODE_MAX_DECOMPRESSED_SIZE_BYTES`). Unset uses the n8n default (268435456, i.e. 256 MiB). |
| nodes.compression.maxZipEntries | string | `nil` | Maximum number of entries allowed in a ZIP archive (`N8N_COMPRESSION_NODE_MAX_ZIP_ENTRIES`). Unset uses the n8n default (1000). |
| nodes.exclude | string | `nil` | Nodes that should not be loaded, rendered as `NODES_EXCLUDE`. Leave unset (`~`) to use the n8n default, which excludes `n8n-nodes-base.executeCommand` and `n8n-nodes-base.localFileTrigger` from n8n 2.0 onwards. Set to `[]` to load every node, or list node types to exclude more of them. |
| nodes.external | object | `{"allowAll":false,"packages":[],"persistence":{"accessMode":"ReadWriteOnce","annotations":{},"enabled":false,"existingClaim":"","size":"1Gi","storageClass":""},"reinstallMissingPackages":false}` | External npm packages to install and allow in the Code node |
| nodes.external.allowAll | bool | `false` | Allow all external npm packages |
| nodes.external.packages | list | `[]` | List of npm package names and versions (e.g., "package-name@1.0.0") |
| nodes.external.persistence | object | `{"accessMode":"ReadWriteOnce","annotations":{},"enabled":false,"existingClaim":"","size":"1Gi","storageClass":""}` | Persistence for community node packages installed by the init container. Optional PVC so packages survive pod restarts without re-downloading. |
| nodes.external.persistence.accessMode | string | `"ReadWriteOnce"` | Access mode. Use ReadWriteMany when worker pods may be scheduled on different nodes. |
| nodes.external.persistence.annotations | object | `{}` | Additional annotations for the PVC. |
| nodes.external.persistence.enabled | bool | `false` | Enable persistence. When false, packages are installed into an emptyDir and lost on pod restart. |
| nodes.external.persistence.existingClaim | string | `""` | Use an existing PVC instead of creating one. When set, no PVC is created by this chart. |
| nodes.external.persistence.size | string | `"1Gi"` | Size of the PVC. |
| nodes.external.persistence.storageClass | string | `""` | Storage class for the PVC. Empty string uses the cluster default. |
| nodes.external.reinstallMissingPackages | bool | `false` | Whether to reinstall missing packages. For more information, see https://docs.n8n.io/integrations/community-nodes/troubleshooting/#error-missing-packages |
| nodes.include | string | `nil` | Nodes that should be loaded, rendered as `NODES_INCLUDE`. Leave unset (`~`) to load everything that isn't excluded. |
| nodes.initContainer | object | `{"image":{"pullPolicy":"IfNotPresent","repository":"node","tag":"20-alpine"},"resources":{}}` | Image for the init container to install npm packages |
| nodes.initContainer.image | object | `{"pullPolicy":"IfNotPresent","repository":"node","tag":"20-alpine"}` | Image for the init container to install npm packages |
| nodes.initContainer.image.pullPolicy | string | `"IfNotPresent"` | Pull policy for the init container to install npm packages |
| nodes.initContainer.image.repository | string | `"node"` | Repository for the init container to install npm packages |
| nodes.initContainer.image.tag | string | `"20-alpine"` | Tag for the init container to install npm packages |
| nodes.initContainer.resources | object | `{}` | Resources for the init container |
| nodes.python | object | `{"builtin":{"modules":[]},"enabled":false,"external":{"allowAll":false,"packages":[]},"persistence":{"accessMode":"ReadWriteOnce","annotations":{},"enabled":false,"existingClaim":"","size":"1Gi","storageClass":""}}` | Python Code node configuration. Requires n8n 1.111.0+ and taskRunners.mode: external. |
| nodes.python.builtin | object | `{"modules":[]}` | Built-in Python module access for the Code node. |
| nodes.python.builtin.modules | list | `[]` | Python standard library modules allowed in Code nodes. Use ['*'] to allow all. |
| nodes.python.enabled | bool | `false` | Enable Python code execution in the Code node via external task runners. |
| nodes.python.external | object | `{"allowAll":false,"packages":[]}` | External Python package access for the Code node. |
| nodes.python.external.allowAll | bool | `false` | Allow all external Python packages in Code nodes. When true, sets N8N_RUNNERS_EXTERNAL_ALLOW=* regardless of packages list. |
| nodes.python.external.packages | list | `[]` | Python packages to install via uv before starting the runner (e.g. ["pandas", "numpy"]). Each listed package is also automatically allowed as an external package in Code nodes. |
| nodes.python.persistence | object | `{"accessMode":"ReadWriteOnce","annotations":{},"enabled":false,"existingClaim":"","size":"1Gi","storageClass":""}` | Persistence for Python packages installed by uv. Optional PVC so packages survive pod restarts without re-downloading. |
| nodes.python.persistence.accessMode | string | `"ReadWriteOnce"` | Access mode. Use ReadWriteMany when worker pods may be scheduled on different nodes. |
| nodes.python.persistence.annotations | object | `{}` | Additional annotations for the PVC. |
| nodes.python.persistence.enabled | bool | `false` | Enable persistence. When false, packages are installed into an emptyDir and lost on pod restart. |
| nodes.python.persistence.existingClaim | string | `""` | Use an existing PVC instead of creating one. When set, no PVC is created by this chart. |
| nodes.python.persistence.size | string | `"1Gi"` | Size of the PVC. |
| nodes.python.persistence.storageClass | string | `""` | Storage class for the PVC. Empty string uses the cluster default. |
| npmRegistry | object | `{"customNpmrc":"","enabled":false,"secretKey":"npmrc","secretName":"","url":""}` | Configuration for private npm registry |
| npmRegistry.customNpmrc | string | `""` | Custom .npmrc content (optional, overrides secret if provided) |
| npmRegistry.enabled | bool | `false` | Enable private npm registry |
| npmRegistry.secretKey | string | `"npmrc"` | Key in the secret for the .npmrc content or auth token |
| npmRegistry.secretName | string | `""` | Name of the Kubernetes secret containing npm registry credentials |
| npmRegistry.url | string | `""` | URL of the private npm registry (e.g., https://registry.npmjs.org/) |
| operations | object | `{"formDataFileSizeMax":200,"maxDisplaySize":104857600,"payloadSizeMax":16,"pruneData":false,"pruneDataHardDeleteBuffer":1,"pruneDataMaxAge":336,"pruneDataMaxCount":10000,"saveDataManualExecutions":true,"saveDataOnError":"all","saveDataOnProgress":false,"saveDataOnSuccess":"all","timeout":-1,"timeoutMax":3600}` | Execution lifecycle and request-size limits, rendered into the operations ConfigMap consumed by every n8n container. |
| operations.formDataFileSizeMax | int | `200` | Maximum uploaded file size in MB for form submissions (`N8N_FORMDATA_FILE_SIZE_MAX`). |
| operations.maxDisplaySize | int | `104857600` | Maximum size in bytes of execution data loaded when displaying an execution (`EXECUTIONS_DATA_MAX_DISPLAY_SIZE`). Larger executions are shown as "too large to display". `0` disables the limit. |
| operations.payloadSizeMax | int | `16` | Maximum request payload size in MB for webhooks and the REST API (`N8N_PAYLOAD_SIZE_MAX`). |
| operations.pruneData | bool | `false` | Delete old execution data on a rolling basis (`EXECUTIONS_DATA_PRUNE`). Off by upstream default; leaving it `false` lets the database grow without bound. |
| operations.pruneDataHardDeleteBuffer | int | `1` | Age in hours after which finished execution data is hard-deleted (`EXECUTIONS_DATA_HARD_DELETE_BUFFER`). |
| operations.pruneDataMaxAge | int | `336` | Execution age in hours before deletion (`EXECUTIONS_DATA_MAX_AGE`). Only used when `pruneData` is `true`. |
| operations.pruneDataMaxCount | int | `10000` | Maximum number of executions to keep (`EXECUTIONS_DATA_PRUNE_MAX_COUNT`). `0` means no limit. Only used when `pruneData` is `true`. |
| operations.saveDataManualExecutions | bool | `true` | Save data for manually triggered executions (`EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS`). |
| operations.saveDataOnError | string | `"all"` | Save execution data on error (`EXECUTIONS_DATA_SAVE_ON_ERROR`). |
| operations.saveDataOnProgress | bool | `false` | Save progress for every executed node (`EXECUTIONS_DATA_SAVE_ON_PROGRESS`). Increases write volume substantially; only enable while debugging. |
| operations.saveDataOnSuccess | string | `"all"` | Save execution data on success (`EXECUTIONS_DATA_SAVE_ON_SUCCESS`). Setting this to `none` is the single most effective way to slow database growth, but it removes the ability to inspect or retry successful runs. |
| operations.timeout | int | `-1` | Default workflow timeout in seconds (`EXECUTIONS_TIMEOUT`). `-1` disables it. Users can override per workflow up to `timeoutMax`. |
| operations.timeoutMax | int | `3600` | Maximum timeout in seconds a user may set on a single workflow (`EXECUTIONS_TIMEOUT_MAX`). |
| podAnnotations | object | `{}` | This is for setting Kubernetes Annotations to a Pod. For more information checkout: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| podLabels | object | `{}` | This is for setting Kubernetes Labels to a Pod. For more information checkout: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ |
| podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch","seccompProfile":{"type":"RuntimeDefault"}}` | This is for setting Security Context to a Pod. For more information checkout: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| pypiRegistry | object | `{"customUvConfig":"","enabled":false,"secretKey":"uv.toml","secretName":"","url":""}` | Configuration for private Python package (PyPI) registry. Used by the runner sidecar when nodes.python.external.packages is set. |
| pypiRegistry.customUvConfig | string | `""` | Inline uv.toml content. When set and secretName is empty, the chart creates a Secret from this content (mirrors customNpmrc behaviour). Mutually exclusive with url. |
| pypiRegistry.enabled | bool | `false` | Enable private PyPI registry support for the runner sidecar. |
| pypiRegistry.secretKey | string | `"uv.toml"` | Key within the secret that holds the uv.toml content. |
| pypiRegistry.secretName | string | `""` | Name of an existing Kubernetes secret whose data contains a uv.toml config file. When set, the file is mounted into the runner sidecar and UV_CONFIG_FILE is set. |
| pypiRegistry.url | string | `""` | URL of the private PyPI index (e.g. https://my.jfrog.io/artifactory/api/pypi/pypi/simple/). Used when no config file is provided; sets UV_DEFAULT_INDEX in the sidecar. For authenticated registries embed credentials inline or use customUvConfig/secretName instead. |
| revisionHistoryLimit | string | `nil` | The number of old ReplicaSets to retain for rollback. More information can be found here: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#clean-up-policy |
| sandboxService | object | `{"api":{"affinity":{},"defaultMaxSandboxes":50,"maxFileBytes":10485760,"nodeSelector":{},"persistence":{"accessModes":["ReadWriteOnce"],"enabled":true,"size":"1Gi","storageClassName":""},"resources":{},"runnerHeartbeatGrace":"45s","store":"sqlite","tolerations":[]},"auth":{"apiKeys":"","existingSecret":"","keys":{"apiKeys":"api-keys","runnerApiKey":"runner-api-key","runnerApiKeys":"runner-api-keys","runnerRegistrationToken":"runner-registration-token"},"runnerApiKey":"","runnerApiKeys":"","runnerRegistrationToken":""},"enabled":false,"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/n8n-io/n8n-sandbox-service-api","runnerRepository":"ghcr.io/n8n-io/n8n-sandbox-service-runner-dind","sandboxRepository":"ghcr.io/n8n-io/n8n-sandbox-service-sandbox","tag":"","version":"1.3.4"},"replicas":1,"runner":{"acknowledgePrivileged":false,"affinity":{},"capacityTotal":1000,"controlGrpcPort":9091,"defaultCpuPercent":100,"defaultMemoryMb":512,"defaultPidsMax":256,"httpBaseUrl":"","httpPort":8080,"isolation":"privileged","nodeSelector":{},"replicas":1,"resources":{},"runtimeClassName":"","tolerations":[]},"tls":{"certManager":{"duration":"2160h","issuerRef":{"group":"cert-manager.io","kind":"Issuer","name":""},"renewBefore":"360h"},"certificates":{"apiControlClient":{"mountPath":"/tls/api-control-client","secretName":""},"apiRegistrationServer":{"mountPath":"/tls/api-registration","secretName":""},"runnerControlServer":{"mountPath":"/tls/runner-control","secretName":""},"runnerRegistrationClient":{"mountPath":"/tls/runner-registration","secretName":""}},"mode":"existingSecret"}}` | The n8n Sandbox Service: a control-plane API plus an in-cluster runner that executes AI-generated code. Deployed only when `sandboxService.enabled`. Treat the runner as root-equivalent on its node. |
| sandboxService.api.defaultMaxSandboxes | int | `50` | Default per-tenant sandbox quota (`SANDBOX_API_DEFAULT_MAX_SANDBOXES`). `0` means unlimited. |
| sandboxService.api.maxFileBytes | int | `10485760` | Maximum file upload size in bytes accepted by the API (`SANDBOX_API_MAX_FILE_BYTES`). |
| sandboxService.api.persistence | object | `{"accessModes":["ReadWriteOnce"],"enabled":true,"size":"1Gi","storageClassName":""}` | Persist the SQLite store so sandbox state survives API pod restarts. Ignored when `store` is `postgres`. |
| sandboxService.api.runnerHeartbeatGrace | string | `"45s"` | How long after the last heartbeat a runner still counts as eligible for placement (`SANDBOX_API_RUNNER_HEARTBEAT_GRACE`). |
| sandboxService.api.store | string | `"sqlite"` | Store backend: `sqlite` for a single API pod, `postgres` when running more than one replica. |
| sandboxService.auth | object | `{"apiKeys":"","existingSecret":"","keys":{"apiKeys":"api-keys","runnerApiKey":"runner-api-key","runnerApiKeys":"runner-api-keys","runnerRegistrationToken":"runner-registration-token"},"runnerApiKey":"","runnerApiKeys":"","runnerRegistrationToken":""}` | Authentication material. The API key handed to n8n must be one of `apiKeys`. |
| sandboxService.auth.apiKeys | string | `""` | Comma-separated admin API keys accepted by the API (`SANDBOX_API_KEYS`). Required unless `existingSecret` is set. Generate a long random value; do not commit a real key. |
| sandboxService.auth.existingSecret | string | `""` | Existing secret supplying the sandbox credentials instead of generated ones. Expected keys are configurable below. |
| sandboxService.auth.keys | object | `{"apiKeys":"api-keys","runnerApiKey":"runner-api-key","runnerApiKeys":"runner-api-keys","runnerRegistrationToken":"runner-registration-token"}` | Key names inside the auth secret. |
| sandboxService.auth.keys.apiKeys | string | `"api-keys"` | Key holding `SANDBOX_API_KEYS`. |
| sandboxService.auth.keys.runnerApiKey | string | `"runner-api-key"` | Key holding `SANDBOX_API_RUNNER_API_KEY`. |
| sandboxService.auth.keys.runnerApiKeys | string | `"runner-api-keys"` | Key holding `SANDBOX_RUNNER_API_KEYS`. |
| sandboxService.auth.keys.runnerRegistrationToken | string | `"runner-registration-token"` | Key holding `SANDBOX_API_RUNNER_REGISTRATION_TOKEN`. |
| sandboxService.auth.runnerApiKey | string | `""` | Key the API uses when calling the runner (`SANDBOX_API_RUNNER_API_KEY`). Required unless `existingSecret` is set. |
| sandboxService.auth.runnerApiKeys | string | `""` | Comma-separated keys the runner accepts from the API (`SANDBOX_RUNNER_API_KEYS`). Must include `runnerApiKey`. Required unless `existingSecret` is set. |
| sandboxService.auth.runnerRegistrationToken | string | `""` | Shared secret runners use to register with the API (`SANDBOX_API_RUNNER_REGISTRATION_TOKEN`). Must match the runner. Required unless `existingSecret` is set. |
| sandboxService.enabled | bool | `false` | Deploy the sandbox API and runner pods. |
| sandboxService.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| sandboxService.image.repository | string | `"ghcr.io/n8n-io/n8n-sandbox-service-api"` | Sandbox service API image repository. |
| sandboxService.image.runnerRepository | string | `"ghcr.io/n8n-io/n8n-sandbox-service-runner-dind"` | Sandbox runner image repository (Docker-in-Docker build). |
| sandboxService.image.sandboxRepository | string | `"ghcr.io/n8n-io/n8n-sandbox-service-sandbox"` | Sandbox image used for the per-execution sandbox containers created by the runner. |
| sandboxService.image.tag | string | `""` | Image tag. Defaults to the pinned version below when empty. |
| sandboxService.image.version | string | `"1.3.4"` | Overrides the pinned service version used as the default image tag. The API, runner and sandbox images are released together and must match. |
| sandboxService.replicas | int | `1` | Number of API replicas. Keep `1` unless `api.store` is `postgres`; the default SQLite store cannot be shared between replicas. |
| sandboxService.runner.acknowledgePrivileged | bool | `false` | Explicit acceptance of the privileged DinD security trade-off. Required when `isolation` is `privileged`. The namespace also needs Pod Security Admission level `privileged`. |
| sandboxService.runner.capacityTotal | int | `1000` | Reported capacity for placement (`SANDBOX_RUNNER_CAPACITY_TOTAL`). `0` means unlimited. |
| sandboxService.runner.controlGrpcPort | int | `9091` | Port for the control gRPC listener. |
| sandboxService.runner.defaultMemoryMb | int | `512` | Sandbox resource defaults applied by the runner. |
| sandboxService.runner.httpBaseUrl | string | `""` | Base URL the API uses to reach this runner (`SANDBOX_RUNNER_HTTP_BASE_URL`). Defaults to the in-cluster headless service, which keeps the host stable enough for per-pod certificates only when `replicas` is 1. |
| sandboxService.runner.httpPort | int | `8080` | Port the runner serves HTTPS on; must match its certificate SANs via `httpBaseUrl`. |
| sandboxService.runner.isolation | string | `"privileged"` | Isolation mode for the runner. `privileged` runs Docker-in-Docker with `privileged: true`; an escape reaches the node, so it must be acknowledged explicitly. |
| sandboxService.runner.replicas | int | `1` | Number of runner pods. Each registers itself with the API and sandboxes are placed on the least-loaded one. |
| sandboxService.runner.runtimeClassName | string | `""` | Runtime class for the runner pod, for example a Kata Containers class so `privileged: true` applies inside a guest VM. |
| sandboxService.tls | object | `{"certManager":{"duration":"2160h","issuerRef":{"group":"cert-manager.io","kind":"Issuer","name":""},"renewBefore":"360h"},"certificates":{"apiControlClient":{"mountPath":"/tls/api-control-client","secretName":""},"apiRegistrationServer":{"mountPath":"/tls/api-registration","secretName":""},"runnerControlServer":{"mountPath":"/tls/runner-control","secretName":""},"runnerRegistrationClient":{"mountPath":"/tls/runner-registration","secretName":""}},"mode":"existingSecret"}` | Mutual TLS between the API and the runner. Both peers require certificates; the stack does not run without them. |
| sandboxService.tls.certManager | object | `{"duration":"2160h","issuerRef":{"group":"cert-manager.io","kind":"Issuer","name":""},"renewBefore":"360h"}` | cert-manager issuer used when `mode` is `certManager`. |
| sandboxService.tls.certManager.duration | string | `"2160h"` | Certificate lifetime (`duration`) and renewal lead time (`renewBefore`), in Go duration format. |
| sandboxService.tls.certManager.issuerRef | object | `{"group":"cert-manager.io","kind":"Issuer","name":""}` | Issuer or ClusterIssuer name. Required when `mode` is `certManager`. |
| sandboxService.tls.certManager.issuerRef.group | string | `"cert-manager.io"` | API group of the issuer reference. |
| sandboxService.tls.certManager.issuerRef.kind | string | `"Issuer"` | Kind of the issuer reference. |
| sandboxService.tls.certificates | object | `{"apiControlClient":{"mountPath":"/tls/api-control-client","secretName":""},"apiRegistrationServer":{"mountPath":"/tls/api-registration","secretName":""},"runnerControlServer":{"mountPath":"/tls/runner-control","secretName":""},"runnerRegistrationClient":{"mountPath":"/tls/runner-registration","secretName":""}}` | The four certificates the stack needs. Each is a kubernetes.io/tls Secret containing `tls.crt`, `tls.key` and `ca.crt`. |
| sandboxService.tls.certificates.apiControlClient | object | `{"mountPath":"/tls/api-control-client","secretName":""}` | Client certificate the API uses against the runner's control listener. |
| sandboxService.tls.certificates.apiRegistrationServer | object | `{"mountPath":"/tls/api-registration","secretName":""}` | Server certificate presented by the API's registration gRPC listener. DNS names are generated from the API service name. |
| sandboxService.tls.certificates.runnerControlServer | object | `{"mountPath":"/tls/runner-control","secretName":""}` | Server certificate for the runner's control gRPC and HTTPS listeners. Its SANs must match the runner host in `httpBaseUrl`. |
| sandboxService.tls.certificates.runnerRegistrationClient | object | `{"mountPath":"/tls/runner-registration","secretName":""}` | Client certificate the runner uses when registering with the API. |
| sandboxService.tls.mode | string | `"existingSecret"` | How certificate Secrets are supplied: `existingSecret` (you provide them) or `certManager` (cert-manager issues them). |
| security | object | `{"blockEnvAccessInNode":true,"enforceSettingsFilePermissions":true,"gitNodeDisableBareRepos":true,"restrictFileAccessTo":null}` | Instance security defaults introduced by n8n 2.0, rendered into a ConfigMap consumed by every n8n container. |
| security.blockEnvAccessInNode | bool | `true` | Block environment variable access from within nodes (`N8N_BLOCK_ENV_ACCESS_IN_NODE`). n8n 2.0 defaults this to `true`; set to `false` only when workflows rely on reading `$env`, which exposes every secret in the container to anyone who can edit a Code node. |
| security.enforceSettingsFilePermissions | bool | `true` | Enforce `0600` permissions on n8n configuration files (`N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS`). Strict enforcement is the default from n8n 2.0 onwards; set to `false` only if a mounted file legitimately needs wider permissions. |
| security.gitNodeDisableBareRepos | bool | `true` | Forbid bare Git repositories in the Git node (`N8N_GIT_NODE_DISABLE_BARE_REPOS`). n8n 2.0 defaults this to `true`; set to `false` only when a workflow needs to read a bare repository from a shared volume. |
| security.restrictFileAccessTo | string | `nil` | Directories the `ReadWriteFile` and `ReadBinaryFiles` nodes may access (`N8N_RESTRICT_FILE_ACCESS_TO`), as a semicolon-separated list. Leave unset (`~`) to inherit the n8n default, which is `~/.n8n-files` from n8n 2.0 onwards. Set it explicitly to widen or narrow the allowed paths; set it to `""` to disable the restriction entirely (insecure - the whole filesystem becomes reachable from file nodes). |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | This is for setting Security Context to a Container. For more information checkout: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| sentry.backendDsn | string | `""` | Sentry DSN for backend. |
| sentry.enabled | bool | `false` | Whether sentry is enabled. |
| sentry.externalTaskRunnersDsn | string | `""` | Sentry DSN for external task runners. |
| sentry.frontendDsn | string | `""` | Sentry DSN for frontend. |
| service | object | `{"annotations":{},"enabled":true,"labels":{},"name":"http","port":5678,"type":"ClusterIP"}` | This is for setting up a service more information can be found here: https://kubernetes.io/docs/concepts/services-networking/service/ |
| service.annotations | object | `{}` | Additional service annotations |
| service.enabled | bool | `true` | Whether to enable the service |
| service.labels | object | `{}` | Additional service labels |
| service.name | string | `"http"` | Default Service name |
| service.port | int | `5678` | This sets the ports more information can be found here: https://kubernetes.io/docs/concepts/services-networking/service/#field-spec-ports |
| service.type | string | `"ClusterIP"` | This sets the service type more information can be found here: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | This section builds out the service account more information can be found here: https://kubernetes.io/docs/concepts/security/service-accounts/ |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| serviceMonitor | object | `{"enabled":false,"include":{"apiEndpoints":false,"apiMethodLabel":false,"apiPathLabel":false,"apiStatusCodeLabel":false,"cacheMetrics":false,"credentialTypeLabel":false,"defaultMetrics":true,"messageEventBusMetrics":false,"nodeTypeLabel":false,"queueMetrics":false,"workflowIdLabel":false},"interval":"30s","labels":{"release":"prometheus"},"metricRelabelings":[],"metricsPrefix":"n8n_","namespace":"","targetLabels":[],"timeout":"10s"}` | The service monitor configuration. Please refer to the following link for more information: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api-reference/api.md |
| serviceMonitor.enabled | bool | `false` | When set true then use a ServiceMonitor to configure scraping |
| serviceMonitor.include | object | `{"apiEndpoints":false,"apiMethodLabel":false,"apiPathLabel":false,"apiStatusCodeLabel":false,"cacheMetrics":false,"credentialTypeLabel":false,"defaultMetrics":true,"messageEventBusMetrics":false,"nodeTypeLabel":false,"queueMetrics":false,"workflowIdLabel":false}` | Whether to include metrics |
| serviceMonitor.include.apiEndpoints | bool | `false` | Whether to include api endpoints |
| serviceMonitor.include.apiMethodLabel | bool | `false` | Whether to include api method label |
| serviceMonitor.include.apiPathLabel | bool | `false` | Whether to include api path label |
| serviceMonitor.include.apiStatusCodeLabel | bool | `false` | Whether to include api status code label |
| serviceMonitor.include.cacheMetrics | bool | `false` | Whether to include cache metrics |
| serviceMonitor.include.credentialTypeLabel | bool | `false` | Whether to include credential type label |
| serviceMonitor.include.defaultMetrics | bool | `true` | Whether to include default metrics |
| serviceMonitor.include.messageEventBusMetrics | bool | `false` | Whether to include message event bus metrics |
| serviceMonitor.include.nodeTypeLabel | bool | `false` | Whether to include node type label |
| serviceMonitor.include.queueMetrics | bool | `false` | Whether to include queue metrics |
| serviceMonitor.include.workflowIdLabel | bool | `false` | Whether to include workflow id label |
| serviceMonitor.interval | string | `"30s"` | Set how frequently Prometheus should scrape |
| serviceMonitor.labels | object | `{"release":"prometheus"}` | Set labels for the ServiceMonitor, use this to define your scrape label for Prometheus Operator |
| serviceMonitor.labels.release | string | `"prometheus"` | default `kube prometheus stack` helm chart serviceMonitor selector label Mostly it's your prometheus helm release name. Please find more information from here: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/platform/troubleshooting.md#troubleshooting-servicemonitor-changes |
| serviceMonitor.metricRelabelings | list | `[]` | Set of rules to relabel your exist metric labels |
| serviceMonitor.metricsPrefix | string | `"n8n_"` | The prefix for the metrics |
| serviceMonitor.namespace | string | `""` | Set the namespace the ServiceMonitor should be deployed. If empty, the ServiceMonitor will be deployed in the same namespace as the n8n chart. |
| serviceMonitor.targetLabels | list | `[]` | Set of labels to transfer on the Kubernetes Service onto the target. |
| serviceMonitor.timeout | string | `"10s"` | Set timeout for scrape |
| smtp | object | `{"enabled":false,"existingSecret":"","host":"","password":"","passwordKey":"password","port":465,"sender":"","ssl":true,"startTls":true,"user":""}` | Outbound email via SMTP. Without this, n8n cannot send invitations, password resets or shared-workflow notifications. |
| smtp.enabled | bool | `false` | Enable SMTP (`N8N_EMAIL_MODE`). Set to `smtp`; leave `false` to disable outbound email entirely. |
| smtp.existingSecret | string | `""` | Existing secret holding the SMTP password. The chart reads the key named in `passwordKey` and exposes it as `N8N_SMTP_PASS`. Takes precedence over `password`. |
| smtp.host | string | `""` | SMTP host (`N8N_SMTP_HOST`). |
| smtp.password | string | `""` | SMTP password written into the chart-managed Secret. Ignored when `existingSecret` is set. Prefer `existingSecret` so the value stays out of your values file. |
| smtp.passwordKey | string | `"password"` | Key inside `existingSecret` that holds the password. |
| smtp.port | int | `465` | SMTP port (`N8N_SMTP_PORT`). `465` is implicit TLS, `587` is STARTTLS. |
| smtp.sender | string | `""` | Sender address (`N8N_SMTP_SENDER`). |
| smtp.ssl | bool | `true` | Use implicit TLS (`N8N_SMTP_SSL`). Keep `true` for port 465, set `false` with `startTls: true` for 587. |
| smtp.startTls | bool | `true` | Upgrade to TLS with STARTTLS (`N8N_SMTP_STARTTLS`). |
| smtp.user | string | `""` | Username for SMTP auth (`N8N_SMTP_USER`). |
| ssrfProtection | object | `{"allowedHostnames":[],"allowedIpRanges":[],"blockedHostnames":[],"blockedIpRanges":[],"dnsCacheMaxSize":1048576,"enabled":false}` | SSRF protection for outbound requests from user-controllable nodes. Available from n8n 2.12; not license-gated. This is application-level defence-in-depth and does not replace network policy. |
| ssrfProtection.allowedHostnames | list | `[]` | Hostname patterns allowed to bypass the blocklist (`N8N_SSRF_ALLOWED_HOSTNAMES`), supports wildcards such as `*.n8n.internal`. Takes precedence over the IP allowlist. |
| ssrfProtection.allowedIpRanges | list | `[]` | CIDR ranges allowed to bypass the blocklist (`N8N_SSRF_ALLOWED_IP_RANGES`). Takes precedence over `blockedIpRanges`. |
| ssrfProtection.blockedHostnames | list | `[]` | Hostnames that are always blocked (`N8N_SSRF_BLOCKED_HOSTNAMES`). |
| ssrfProtection.blockedIpRanges | list | `[]` | Additional CIDR ranges to block on top of the upstream defaults (`N8N_SSRF_BLOCKED_IP_RANGES`). Include the literal string `default` to keep the upstream list alongside your own. |
| ssrfProtection.dnsCacheMaxSize | int | `1048576` | Maximum DNS cache entries (`N8N_SSRF_DNS_CACHE_MAX_SIZE`). |
| ssrfProtection.enabled | bool | `false` | Enable SSRF validation of outbound HTTP requests (`N8N_SSRF_PROTECTION_ENABLED`). Enabling it blocks RFC1918, loopback and link-local ranges by default, so internal services stop being reachable until allowlisted below. |
| strategy | object | `{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"}` | This will set the deployment strategy more information can be found here: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| taskRunners | object | `{"broker":{"address":"127.0.0.1","port":5679},"external":{"autoShutdownTimeout":15,"image":{"pullPolicy":"IfNotPresent","repository":"n8nio/runners","tag":""},"mainNodeAuthToken":"","nodeOptions":["--max-semi-space-size=16","--max-old-space-size=300"],"port":5680,"pythonSitePackagesDir":"/opt/runners/task-runner-python/.venv/lib/python3.13/site-packages","resources":{"limits":{"cpu":"2000m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"32Mi"}},"workerNodeAuthToken":""},"maxConcurrency":5,"mode":"internal","taskHeartbeatInterval":30,"taskTimeout":60}` | Task runners mode. Please follow the documentation for more information: https://docs.n8n.io/hosting/configuration/task-runners/ |
| taskRunners.broker | object | `{"address":"127.0.0.1","port":5679}` | The address for the broker of the external task runner |
| taskRunners.broker.address | string | `"127.0.0.1"` | The address for the broker of the external task runner |
| taskRunners.broker.port | int | `5679` | The port for the broker of the external task runner |
| taskRunners.external | object | `{"autoShutdownTimeout":15,"image":{"pullPolicy":"IfNotPresent","repository":"n8nio/runners","tag":""},"mainNodeAuthToken":"","nodeOptions":["--max-semi-space-size=16","--max-old-space-size=300"],"port":5680,"pythonSitePackagesDir":"/opt/runners/task-runner-python/.venv/lib/python3.13/site-packages","resources":{"limits":{"cpu":"2000m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"32Mi"}},"workerNodeAuthToken":""}` | The configuration for the external task runner |
| taskRunners.external.autoShutdownTimeout | int | `15` | The auto shutdown timeout for the external task runner in seconds |
| taskRunners.external.image | object | `{"pullPolicy":"IfNotPresent","repository":"n8nio/runners","tag":""}` | The image for the external task runner sidecar. Tag must match the n8n appVersion. |
| taskRunners.external.image.pullPolicy | string | `"IfNotPresent"` | This sets the pull policy for images. |
| taskRunners.external.image.repository | string | `"n8nio/runners"` | The repository for the external task runner image |
| taskRunners.external.image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| taskRunners.external.mainNodeAuthToken | string | `""` | The auth token for the main node |
| taskRunners.external.nodeOptions | list | `["--max-semi-space-size=16","--max-old-space-size=300"]` | The node options for the external task runner |
| taskRunners.external.port | int | `5680` | The port for the external task runner |
| taskRunners.external.pythonSitePackagesDir | string | `"/opt/runners/task-runner-python/.venv/lib/python3.13/site-packages"` | Path to the Python venv's site-packages directory inside the `n8nio/runners` image. Used to mount a `.pth` file that exposes packages installed by `nodes.python.external.packages` to the Python runner, which always runs with `-I` (isolated mode) and therefore ignores `PYTHONPATH`. Update this if the image's bundled Python minor version changes. |
| taskRunners.external.resources | object | `{"limits":{"cpu":"2000m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"32Mi"}}` | The resources for the external task runner |
| taskRunners.external.resources.limits | object | `{"cpu":"2000m","memory":"512Mi"}` | The limits for the external task runner |
| taskRunners.external.resources.limits.cpu | string | `"2000m"` | The CPU limit for the external task runner |
| taskRunners.external.resources.limits.memory | string | `"512Mi"` | The memory limit for the external task runner |
| taskRunners.external.resources.requests | object | `{"cpu":"100m","memory":"32Mi"}` | The resources requests for the external task runner |
| taskRunners.external.resources.requests.cpu | string | `"100m"` | The CPU request for the external task runner |
| taskRunners.external.resources.requests.memory | string | `"32Mi"` | The memory request for the external task runner |
| taskRunners.external.workerNodeAuthToken | string | `""` | The auth token for the worker node |
| taskRunners.maxConcurrency | int | `5` | The maximum concurrency for the task |
| taskRunners.mode | string | `"internal"` | Use `internal` to use internal task runner, or use `external` to have external sidecar task runner. For more information please follow the documentation: https://docs.n8n.io/hosting/configuration/task-runners/#task-runner-modes |
| taskRunners.taskHeartbeatInterval | int | `30` | The heartbeat interval for the task in seconds |
| taskRunners.taskTimeout | int | `60` | The timeout for the task in seconds |
| timezone | string | `"Europe/Berlin"` | For instance, the Schedule node uses it to know at what time the workflow should start. Find you timezone from here: https://momentjs.com/timezone/ |
| tolerations | list | `[]` | For more information checkout: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| versionNotifications.enabled | bool | `false` | Whether to request notifications about new n8n versions |
| versionNotifications.endpoint | string | `"https://api.n8n.io/api/versions/"` | Endpoint to retrieve n8n version information from |
| versionNotifications.infoUrl | string | `"https://docs.n8n.io/hosting/installation/updating/"` | URL for versions panel to page instructing user on how to update n8n instance |
| waitContainer | object | `{"image":{"pullPolicy":"IfNotPresent","repository":"busybox","tag":"1.38"}}` | Image for the `wait-for-main` init containers that block worker, webhook and MCP webhook pods    until the main node is ready. The default tag floats within the busybox 1.36 line, so patch    updates are picked up without a chart change. |
| waitContainer.image.pullPolicy | string | `"IfNotPresent"` | Pull policy for the wait-for-main init container. |
| waitContainer.image.repository | string | `"busybox"` | Repository for the wait-for-main init container. |
| waitContainer.image.tag | string | `"1.38"` | Tag for the wait-for-main init container. |
| waitContainerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Security Context for the wait-for-main busybox init containers. |
| webhook | object | `{"affinity":{},"allNodes":false,"autoscaling":{"behavior":{},"enabled":false,"maxReplicas":10,"metrics":[{"resource":{"name":"cpu","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"}],"minReplicas":2},"count":2,"extraContainers":[],"extraEnv":[],"extraEnvVars":{},"extraSecretNamesForEnvFrom":[],"hostAliases":[],"initContainers":[],"livenessProbe":{"httpGet":{"path":"/healthz","port":"http"}},"mcp":{"affinity":{},"enabled":true,"extraContainers":[],"extraEnv":[],"extraEnvVars":{},"extraSecretNamesForEnvFrom":[],"hostAliases":[],"initContainers":[],"livenessProbe":{"httpGet":{"path":"/healthz","port":"http"}},"readinessProbe":{"httpGet":{"path":"/healthz/readiness","port":"http"}},"resources":{},"startupProbe":{"exec":{"command":["/bin/sh","-c","ps aux | grep '[n]8n'"]},"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":5},"volumeMounts":[],"volumes":[]},"mode":"regular","pdb":{"enabled":true,"maxUnavailable":1,"minAvailable":null,"unhealthyPodEvictionPolicy":"AlwaysAllow"},"readinessProbe":{"httpGet":{"path":"/healthz/readiness","port":"http"}},"resources":{},"runtimeClassName":"","startupProbe":{"exec":{"command":["/bin/sh","-c","ps aux | grep '[n]8n'"]},"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":5},"url":"","volumeMounts":[],"volumes":[],"waitMainNodeReady":{"additionalParameters":[],"enabled":false,"healthCheckPath":"/healthz","overwriteSchema":"","overwriteUrl":""}}` | Webhook node configurations |
| webhook.affinity | object | `{}` | Webhook node affinity. For more information checkout: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity |
| webhook.allNodes | bool | `false` | If true, all k8s nodes will deploy exatly one webhook pod |
| webhook.autoscaling | object | `{"behavior":{},"enabled":false,"maxReplicas":10,"metrics":[{"resource":{"name":"cpu","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"}],"minReplicas":2}` | If true, the number of webhooks will be automatically scaled based on default metrics. On default, it will scale based on CPU. Scale by requests can be done by setting a custom metric. For more information can be found here: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/ |
| webhook.autoscaling.behavior | object | `{}` | The behavior of the autoscaler. |
| webhook.autoscaling.enabled | bool | `false` | Whether autoscaling is enabled. |
| webhook.autoscaling.maxReplicas | int | `10` | The maximum number of replicas. |
| webhook.autoscaling.metrics | list | `[{"resource":{"name":"cpu","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"}]` | The metrics to use for autoscaling. |
| webhook.autoscaling.minReplicas | int | `2` | The minimum number of replicas. |
| webhook.count | int | `2` | Static number of webhooks. If allNodes or autoscaling is enabled, this value will be ignored. |
| webhook.extraContainers | list | `[]` | Additional containers for the webhook pod |
| webhook.extraEnv | list | `[]` | Extra environment variables that support `valueFrom` (e.g., secretKeyRef, configMapKeyRef). Entries are passed through verbatim and rendered after `extraEnvVars`. |
| webhook.extraEnvVars | object | `{}` | Extra environment variables |
| webhook.extraSecretNamesForEnvFrom | list | `[]` | Extra secrets for environment variables |
| webhook.hostAliases | list | `[]` | Host aliases for the webhook pod. For more information checkout: https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/#adding-additional-entries-with-hostaliases |
| webhook.initContainers | list | `[]` | Additional init containers for the webhook pod |
| webhook.livenessProbe | object | `{"httpGet":{"path":"/healthz","port":"http"}}` | This is to setup the liveness probe for the webhook pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| webhook.mcp | object | `{"affinity":{},"enabled":true,"extraContainers":[],"extraEnv":[],"extraEnvVars":{},"extraSecretNamesForEnvFrom":[],"hostAliases":[],"initContainers":[],"livenessProbe":{"httpGet":{"path":"/healthz","port":"http"}},"readinessProbe":{"httpGet":{"path":"/healthz/readiness","port":"http"}},"resources":{},"startupProbe":{"exec":{"command":["/bin/sh","-c","ps aux | grep '[n]8n'"]},"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":5},"volumeMounts":[],"volumes":[]}` | MCP webhook configuration. This is only used when the webhook mode is set to `queue` and the database type is set to `postgresdb`. |
| webhook.mcp.affinity | object | `{}` | Webhook node affinity for the mcp webhook pod. For more information checkout: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity |
| webhook.mcp.enabled | bool | `true` | Whether to enable MCP webhook |
| webhook.mcp.extraContainers | list | `[]` | Additional containers for the mcp webhook pod |
| webhook.mcp.extraEnv | list | `[]` | Extra environment variables for the mcp webhook pod that support `valueFrom` (e.g., secretKeyRef, configMapKeyRef). Entries are passed through verbatim and rendered after `extraEnvVars`. |
| webhook.mcp.extraEnvVars | object | `{}` | Extra environment variables for the mcp webhook pod |
| webhook.mcp.extraSecretNamesForEnvFrom | list | `[]` | Extra secrets for environment variables for the mcp webhook pod |
| webhook.mcp.hostAliases | list | `[]` | Host aliases for the mcp webhook pod. For more information checkout: https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/#adding-additional-entries-with-hostaliases |
| webhook.mcp.initContainers | list | `[]` | Additional init containers for the mcp webhook pod |
| webhook.mcp.livenessProbe | object | `{"httpGet":{"path":"/healthz","port":"http"}}` | This is to setup the liveness probe for the mcp webhook pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| webhook.mcp.readinessProbe | object | `{"httpGet":{"path":"/healthz/readiness","port":"http"}}` | This is to setup the readiness probe for the mcp webhook pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| webhook.mcp.resources | object | `{}` | This block is for setting up the resource management for the mcp webhook pod more information can be found here: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| webhook.mcp.startupProbe | object | `{"exec":{"command":["/bin/sh","-c","ps aux | grep '[n]8n'"]},"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":5}` | This is to setup the startup probe for the mcp webhook pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| webhook.mcp.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition for the mcp webhook pod |
| webhook.mcp.volumes | list | `[]` | Additional volumes on the output Deployment definition for the mcp webhook pod |
| webhook.mode | string | `"regular"` | Use `regular` to use main node as webhook node, or use `queue` to have webhook nodes |
| webhook.pdb | object | `{"enabled":true,"maxUnavailable":1,"minAvailable":null,"unhealthyPodEvictionPolicy":"AlwaysAllow"}` | Whether to enable the PodDisruptionBudget for the webhook pod |
| webhook.pdb.enabled | bool | `true` | Whether to enable the PodDisruptionBudget |
| webhook.pdb.maxUnavailable | int | `1` | Maximum number of unavailable replicas |
| webhook.pdb.minAvailable | string | `nil` | Minimum number of available replicas |
| webhook.pdb.unhealthyPodEvictionPolicy | string | `"AlwaysAllow"` | Unhealty webhook pod eviction policy |
| webhook.readinessProbe | object | `{"httpGet":{"path":"/healthz/readiness","port":"http"}}` | This is to setup the readiness probe for the webhook pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| webhook.resources | object | `{}` | This block is for setting up the resource management for the webhook pod more information can be found here: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| webhook.runtimeClassName | string | `""` | Runtime class name for the webhook pod. For more information checkout: https://kubernetes.io/docs/concepts/containers/runtime-class/ |
| webhook.startupProbe | object | `{"exec":{"command":["/bin/sh","-c","ps aux | grep '[n]8n'"]},"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":5}` | This is to setup the startup probe for the webhook pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| webhook.url | string | `""` | Webhook url together with http or https schema |
| webhook.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| webhook.volumes | list | `[]` | Additional volumes on the output Deployment definition. |
| webhook.waitMainNodeReady | object | `{"additionalParameters":[],"enabled":false,"healthCheckPath":"/healthz","overwriteSchema":"","overwriteUrl":""}` | This is to setup the wait for the webhook node to be ready. |
| webhook.waitMainNodeReady.enabled | bool | `false` | Whether to enable the wait for the webhook node to be ready. |
| webhook.waitMainNodeReady.healthCheckPath | string | `"/healthz"` | The health check path to use for request to the main node. |
| webhook.waitMainNodeReady.overwriteSchema | string | `""` | The schema to use for request to the main node. On default, it will use identify the schema from the main N8N_PROTOCOL environment variable or use http. |
| webhook.waitMainNodeReady.overwriteUrl | string | `""` | The URL to use for request to the main node. On default, it will use service name and port. |
| worker | object | `{"affinity":{},"allNodes":false,"autoscaling":{"behavior":{},"enabled":false,"maxReplicas":10,"metrics":[{"resource":{"name":"memory","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"},{"resource":{"name":"cpu","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"}],"minReplicas":2},"concurrency":10,"count":2,"extraContainers":[],"extraEnv":[],"extraEnvVars":{},"extraSecretNamesForEnvFrom":[],"forceToUseStatefulset":false,"hostAliases":[],"initContainers":[],"livenessProbe":{"httpGet":{"path":"/healthz","port":"http"}},"mode":"regular","pdb":{"enabled":true,"maxUnavailable":1,"minAvailable":null,"unhealthyPodEvictionPolicy":"AlwaysAllow"},"persistence":{"accessMode":"ReadWriteOnce","annotations":{"helm.sh/resource-policy":"keep"},"enabled":false,"existingClaim":"","labels":{},"mountPath":"/home/node/.n8n","size":"8Gi","storageClass":"","subPath":"","volumeName":""},"readinessProbe":{"httpGet":{"path":"/healthz/readiness","port":"http"}},"resources":{},"runtimeClassName":"","startupProbe":{"exec":{"command":["/bin/sh","-c","ps aux | grep '[n]8n'"]},"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":5},"volumeMounts":[],"volumes":[],"waitMainNodeReady":{"additionalParameters":[],"enabled":false,"healthCheckPath":"/healthz","overwriteSchema":"","overwriteUrl":""}}` | Worker node configurations |
| worker.affinity | object | `{}` | Worker node affinity. For more information checkout: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity |
| worker.allNodes | bool | `false` | If true, all k8s nodes will deploy exatly one worker pod |
| worker.autoscaling | object | `{"behavior":{},"enabled":false,"maxReplicas":10,"metrics":[{"resource":{"name":"memory","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"},{"resource":{"name":"cpu","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"}],"minReplicas":2}` | If true, the number of workers will be automatically scaled based on default metrics. On default, it will scale based on CPU and memory. For more information can be found here: https://kubernetes.io/docs/concepts/workloads/autoscaling/ |
| worker.autoscaling.behavior | object | `{}` | The behavior of the autoscaler. |
| worker.autoscaling.enabled | bool | `false` | Whether autoscaling is enabled. |
| worker.autoscaling.maxReplicas | int | `10` | The maximum number of replicas. |
| worker.autoscaling.metrics | list | `[{"resource":{"name":"memory","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"},{"resource":{"name":"cpu","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"}]` | The metrics to use for autoscaling. |
| worker.autoscaling.minReplicas | int | `2` | The minimum number of replicas. |
| worker.concurrency | int | `10` | number of concurrency for each worker |
| worker.count | int | `2` | Static number of workers. If allNodes or autoscaling is enabled, this value will be ignored. |
| worker.extraContainers | list | `[]` | Additional containers for the worker pod |
| worker.extraEnv | list | `[]` | Extra environment variables that support `valueFrom` (e.g., secretKeyRef, configMapKeyRef). Entries are passed through verbatim and rendered after `extraEnvVars`. |
| worker.extraEnvVars | object | `{}` | Extra environment variables |
| worker.extraSecretNamesForEnvFrom | list | `[]` | Extra secrets for environment variables |
| worker.forceToUseStatefulset | bool | `false` | Force to use statefulset for the worker pod. If true, the worker pod will be created as a statefulset. |
| worker.hostAliases | list | `[]` | Host aliases for the worker pod. For more information checkout: https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/#adding-additional-entries-with-hostaliases |
| worker.initContainers | list | `[]` | Additional init containers for the worker pod |
| worker.livenessProbe | object | `{"httpGet":{"path":"/healthz","port":"http"}}` | This is to setup the liveness probe for the worker pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| worker.mode | string | `"regular"` | Use `regular` to use main node as executer, or use `queue` to have worker nodes |
| worker.pdb | object | `{"enabled":true,"maxUnavailable":1,"minAvailable":null,"unhealthyPodEvictionPolicy":"AlwaysAllow"}` | Whether to enable the PodDisruptionBudget for the worker pod |
| worker.pdb.enabled | bool | `true` | Whether to enable the PodDisruptionBudget |
| worker.pdb.maxUnavailable | int | `1` | Maximum number of unavailable replicas |
| worker.pdb.minAvailable | string | `nil` | Minimum number of available replicas |
| worker.pdb.unhealthyPodEvictionPolicy | string | `"AlwaysAllow"` | Unhealty worker pod eviction policy |
| worker.persistence | object | `{"accessMode":"ReadWriteOnce","annotations":{"helm.sh/resource-policy":"keep"},"enabled":false,"existingClaim":"","labels":{},"mountPath":"/home/node/.n8n","size":"8Gi","storageClass":"","subPath":"","volumeName":""}` | Persistence configuration for the worker pod |
| worker.persistence.accessMode | string | `"ReadWriteOnce"` | Access mode for persistence |
| worker.persistence.annotations | object | `{"helm.sh/resource-policy":"keep"}` | Annotations for persistence |
| worker.persistence.enabled | bool | `false` | Whether to enable persistence |
| worker.persistence.existingClaim | string | `""` | Existing claim to use for persistence |
| worker.persistence.labels | object | `{}` | Labels for persistence |
| worker.persistence.mountPath | string | `"/home/node/.n8n"` | Mount path for persistence |
| worker.persistence.size | string | `"8Gi"` | Size for persistence |
| worker.persistence.storageClass | string | `""` | Storage class for persistence |
| worker.persistence.subPath | string | `""` | Sub path for persistence |
| worker.persistence.volumeName | string | `""` | Name of the volume to use for persistence |
| worker.readinessProbe | object | `{"httpGet":{"path":"/healthz/readiness","port":"http"}}` | This is to setup the readiness probe for the worker pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| worker.resources | object | `{}` | This block is for setting up the resource management for the worker pod more information can be found here: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| worker.runtimeClassName | string | `""` | Runtime class name for the worker pod. For more information checkout: https://kubernetes.io/docs/concepts/containers/runtime-class/ |
| worker.startupProbe | object | `{"exec":{"command":["/bin/sh","-c","ps aux | grep '[n]8n'"]},"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":5}` | This is to setup the startup probe for the worker pod more information can be found here: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| worker.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| worker.volumes | list | `[]` | Additional volumes on the output Deployment definition. |
| worker.waitMainNodeReady | object | `{"additionalParameters":[],"enabled":false,"healthCheckPath":"/healthz","overwriteSchema":"","overwriteUrl":""}` | This is to setup the wait for the main node to be ready. |
| worker.waitMainNodeReady.enabled | bool | `false` | Whether to enable the wait for the main node to be ready. |
| worker.waitMainNodeReady.healthCheckPath | string | `"/healthz"` | The health check path to use for request to the main node. |
| worker.waitMainNodeReady.overwriteSchema | string | `""` | The schema to use for request to the main node. On default, it will use identify the schema from the main N8N_PROTOCOL environment variable or use http. |
| worker.waitMainNodeReady.overwriteUrl | string | `""` | The URL to use for request to the main node. On default, it will use service name and port. |
| workflowHistory | object | `{"enabled":true,"pruneTime":336}` | The workflow history configuration |
| workflowHistory.enabled | bool | `true` | Whether to save workflow history versions |
| workflowHistory.pruneTime | int | `336` | Time (in hours) to keep workflow history versions for. To disable it, use -1 as a value |

**Homepage:** <https://n8n.io>

## Source Code

* <https://github.com/suneetk92/n8n-helm-chart>
* <https://github.com/n8n-io/n8n>

## Chart Development

Please install unittest helm plugin with `helm plugin install https://github.com/helm-unittest/helm-unittest.git` command and use following command to run helm unit tests.

```console
helm unittest --strict --file 'unittests/**/*.yaml' charts/n8n
```

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| suneetk92 |  | <https://github.com/suneetk92> |
