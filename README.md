# n8n Helm Chart

A production-grade Kubernetes Helm chart for [n8n](https://n8n.io) — the fair-code workflow
automation platform with native AI capabilities.

The chart is published as an OCI artifact to GitHub Container Registry.

## Usage

[Helm](https://helm.sh) must be installed to use the chart. Refer to Helm's
[documentation](https://helm.sh/docs/) to get started.

OCI charts need no `helm repo add` — install straight from the registry:

```console
helm install my-n8n oci://ghcr.io/suneetk92/n8n --version 3.1.0
```

To inspect the default values before installing:

```console
helm show values oci://ghcr.io/suneetk92/n8n --version 3.1.0
```

Available versions are listed on the
[package page](https://github.com/suneetk92?tab=packages&repo_name=n8n-helm-chart).

Full configuration reference, examples and upgrade notes live in
[`charts/n8n/README.md`](charts/n8n/README.md). Release history is in
[`CHANGELOG.md`](CHANGELOG.md).

### External dependencies

As of chart 3.0.0 the bundled `redis`, `postgresql` and `minio` subcharts are no longer shipped —
provide these yourself:

| Requirement | Needed for |
|---|---|
| PostgreSQL | `db.type: postgresdb` (required for queue mode) |
| Redis | queue mode (`worker.mode: queue` / `webhook.mode: queue`) |
| S3-compatible object store | `binaryData.mode: s3` |

## Development

Chart architecture, operating modes and non-obvious patterns are documented in
[`charts/n8n/CLAUDE.md`](charts/n8n/CLAUDE.md). Repo-level conventions and commands are in
[`CLAUDE.md`](CLAUDE.md).

```console
# Unit tests
helm unittest --strict --file 'unittests/**/*.yaml' charts/n8n

# Lint
helm lint charts/n8n
kube-linter lint charts/n8n --config .kube-linter.yaml

# Regenerate charts/n8n/README.md after changing values.yaml or README.md.gotmpl
helm-docs --chart-search-root=charts --template-files=README.md.gotmpl
```

## License

[MIT License](LICENSE).

This chart began as a fork of
[community-charts/helm-charts](https://github.com/community-charts/helm-charts); the original
copyright is retained in [`LICENSE`](LICENSE).
