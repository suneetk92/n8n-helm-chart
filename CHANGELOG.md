# Changelog

All notable changes to the n8n chart are documented here. The chart follows
[semantic versioning](https://semver.org/); breaking changes bump the major version and are
accompanied by upgrade steps in the chart README's "Upgrading" section.

## Unreleased

### Fixed

- `sandboxService.enabled: true` with default TLS settings is now rejected at install time instead of
  producing pods that hang forever. `tls.mode` defaults to `existingSecret`, but nothing required the
  four `tls.certificates.*.secretName` values, so the chart fell back to derived
  `<release>-sandbox-*-tls` names that it never creates and the API and runner pods sat in
  `FailedMount` indefinitely (`secret "…-sandbox-runner-registration-tls" not found`). The API and
  runner authenticate each other with mTLS and there is no plaintext mode, so all four Secrets must
  exist: either pre-create them and set the names, or use `tls.mode: certManager` with an
  `issuerRef`.
- Four documented values that reached no rendered output are now honoured:
  `sandboxService.tls.certManager.duration` / `renewBefore` (never emitted on any of the four
  Certificates, so cert-manager silently applied its own 90d/30d defaults instead of the documented
  values), `db.sqlite.database` (no `DB_SQLITE_DATABASE`), `db.postgresdb.ssl.rejectUnauthorized`
  (no `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED`, so SSL verification could not be relaxed), and
  `npmRegistry.url`, which is now turned into a minimal `.npmrc` when `customNpmrc` and
  `secretName` are unset rather than doing nothing.
- `waitContainerSecurityContext` is now nil-guarded in the four templates that use it. It is the only
  optional root value that was dereferenced unguarded, so setting it to `null` emitted
  `securityContext: null` and silently discarded the hardening defaults.

### Changed

- `values.schema.json` now declares five keys that ship as defaults in `values.yaml` but were
  previously accepted only because their parent allowed additional properties, so they received no
  validation: `securityContext.privileged`, `securityContext.runAsGroup`,
  `waitContainerSecurityContext.privileged`, `waitContainerSecurityContext.runAsGroup` and
  `strategy.rollingUpdate` (whose `maxSurge`/`maxUnavailable` accept a count or a percentage).
  Typos and wrong types in these are now rejected at install rather than silently ignored.

## 3.1.0

### Fixed

- `smtp` and `instanceOwner` are now actually wired up. Both Secrets were created but never
  referenced by any container, so `N8N_SMTP_PASS` and `N8N_INSTANCE_OWNER_PASSWORD_HASH` never
  reached n8n — SMTP auth failed (no invites or password resets) and the instance owner was pinned
  by `N8N_INSTANCE_OWNER_MANAGED_BY_ENV` without the hash it needs. `existingSecret`,
  `passwordKey` and `passwordHashKey` were consequently inert and now work.
- `license.enabled: true` without an activation key no longer breaks the pod. Every pod template
  added an `envFrom.secretRef` for the activation-key Secret, which is only created when
  `license.activationKey` is set, so the pod failed with `CreateContainerConfigError`. The
  reference is now rendered only when `activationKey` or `existingActivationKeySecret` is set.
- `aiAssistant.enabled: true` without a model key no longer breaks the pod, and
  `aiAssistant.existingModelApiKeySecret` now works. The guard was
  `or modelApiKey (not existingModelApiKeySecret)`, which was true when *neither* was set (pointing
  at a Secret the chart never creates) and false when *only* the existing-secret was set.
- `main.count: 1` combined with `persistence.accessMode: ReadWriteMany` now creates its PVC. The
  Deployment renders for `count == 1` or `ReadWriteMany` but the PVC condition tested accessMode
  per count, leaving that intersection with a Deployment referencing a claim that never existed and
  a permanently unschedulable pod.
- The worker headless Service is now created whenever the worker StatefulSet needs it. It was
  nested inside the webhook Service's `webhook.mode == queue` block, so a queue-mode worker with a
  regular-mode webhook produced a StatefulSet whose `serviceName` pointed at a missing Service,
  costing the pods stable DNS. Its labels also said `component: main`; they now say `worker`.
- `N8N_EDITOR_BASE_URL` is now set on the multi-main StatefulSet path. Only `deployment.yaml` set
  it, so `main.editorBaseUrl` (and the ingress-host fallback) was a silent no-op for multi-main
  installs, breaking OAuth callbacks and links in outbound email.
- Worker containers now get the `npm-home` volume mount and `NPM_CONFIG_CACHE`, matching the main
  container. Without a writable npm cache, runtime package installation
  (`nodes.external.reinstallMissingPackages`) failed against the read-only root filesystem.
- The external task runner now honours the chart's module allow-lists. The `n8nio/runners` image
  ships its own `/etc/n8n-task-runners.json`, whose `env-overrides` block hard-codes
  `NODE_FUNCTION_ALLOW_EXTERNAL=moment`, `NODE_FUNCTION_ALLOW_BUILTIN=crypto` and blank
  `N8N_RUNNERS_STDLIB_ALLOW` / `N8N_RUNNERS_EXTERNAL_ALLOW`. Those overrides silently won over the
  container environment variables the chart sets, so `nodes.external.packages`, `nodes.builtin` and
  `nodes.python.*` had no effect whenever `taskRunners.mode: external`. The chart now generates a
  replacement config file from those same values and mounts it over the image's default.
- JavaScript Code nodes can now resolve packages installed by `nodes.external.packages`. The runner
  subprocess resolves `require()` relative to its own install path, which never reaches the
  persistence volume, so `NODE_PATH` is now set to `<persistence.mountPath>/node_modules`.
- Python Code nodes can now import packages installed by `nodes.python.external.packages`. The
  launcher always starts the Python runner with `-I` (isolated mode), which makes Python ignore
  `PYTHONPATH`; the chart now mounts a `.pth` file into the runner venv's `site-packages` instead.

### Added

- `taskRunners.external.pythonSitePackagesDir` — path to the Python venv's `site-packages` directory
  inside the `n8nio/runners` image, used to place the `.pth` file above. Bump this if the image's
  bundled Python minor version changes.

## 3.0.0

### Removed

- The bundled `redis`, `postgresql` and `minio` subcharts are no longer shipped. Provide external
  services instead: an external PostgreSQL for `db.type: postgresdb`, an external Redis for queue
  mode, and an S3-compatible object store (`binaryData.s3.*`) for the `s3` binary data mode.
- `N8N_AVAILABLE_BINARY_DATA_MODES` is no longer rendered. n8n 2.0 dropped the variable, so
  `binaryData.availableModes` had no effect; it is now accepted for one release and emits a NOTES
  warning.
- `default` (in-memory) is no longer a valid `binaryData.mode`. Valid values are `filesystem`,
  `database` and `s3`; the chart default is now unset so n8n picks `filesystem` in regular mode and
  `database` in queue mode.

### Changed

- New `<release>-security-configmap`, consumed by every n8n container, carries the instance security
  settings that n8n 2.0 changed its defaults for: `security.enforceSettingsFilePermissions`,
  `security.blockEnvAccessInNode`, `security.gitNodeDisableBareRepos` and
  `security.restrictFileAccessTo`.
  See the [n8n 2.0 breaking changes](https://docs.n8n.io/changelog/v20-breaking-changes).
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` moved out of the hardcoded container environment into the
  security ConfigMap and is now configurable.
- `db.sqlite.poolSize` is now rendered as `DB_SQLITE_POOL_SIZE` and defaults to `3`. n8n 2.0 removed
  the legacy non-pool SQLite driver and rejects `0`, which the chart previously shipped as the
  default.

### Added

- `nodes.exclude` and `nodes.include` (`NODES_EXCLUDE` / `NODES_INCLUDE`). n8n 2.0 excludes
  `n8n-nodes-base.executeCommand` and `n8n-nodes-base.localFileTrigger` by default; set
  `nodes.exclude: []` to load every node.
- `nodes.compression.maxDecompressedSizeBytes` and `nodes.compression.maxZipEntries`, needed to
  restore the pre-3.0 limits after n8n 3.0 lowered them to 256 MiB / 1000 ZIP entries.
  See the [n8n 3.0 breaking changes](https://docs.n8n.io/changelog/v30-breaking-changes).
- `encryptionKeyRotation.enabled` (`N8N_ENV_FEAT_ENCRYPTION_KEY_ROTATION`). The chart keeps it
  `false` because the migration is one-way and irreversible; see the Upgrading section in the README
  before enabling it.
- `binaryData.databaseMaxFileSize` (`N8N_BINARY_DATA_DATABASE_MAX_FILE_SIZE`) for the `database`
  binary data mode.
- `operations` block (always rendered): execution lifecycle and request-size limits in a dedicated
  operations ConfigMap — `N8N_EXECUTIONS_TIMEOUT`, `N8N_EXECUTIONS_TIMEOUT_MAX`, the
  `EXECUTIONS_DATA_*` save/pruning knobs, and `N8N_PAYLOAD_SIZE_MAX` / `N8N_FORMDATA_FILE_SIZE_MAX`.
- `ssrfProtection` block (disabled by default): application-level SSRF protection for outbound
  requests from user-controllable nodes (`N8N_SSRF_PROTECTION_ENABLED` plus allowed/blocked host and
  IP-range lists). Defence-in-depth only; does not replace network policy.
- `durableScheduler` block (disabled by default): the durable, database-backed scheduler for
  time-based workflows (`N8N_SCHEDULER_ENABLED`, `N8N_USE_WORKFLOW_PUBLICATION_SERVICE`,
  `N8N_SCHEDULER_POLL_TRIGGERS_ENABLED`). Preview upstream.
- `smtp` block (disabled by default): outbound email configuration. The password is stored in a
  generated `<release>-smtp` Secret unless `existingSecret` is set.
- `instanceOwner` block (disabled by default): bootstrap and pin the instance owner from the
  environment using a bcrypt hash, for GitOps installs. Requires `passwordHash`; a plaintext
  password breaks login.
- `aiAssistant` block (disabled by default): n8n Assistant and agents
  (`N8N_ENABLED_MODULES: instance-ai,agents`) plus model settings. Preview upstream.
  `aiAssistant.searxng.url` points the Assistant at an externally managed SearXNG instance
  (`N8N_INSTANCE_AI_SEARXNG_URL`); the chart does not deploy SearXNG.
- `sandboxService` block (disabled by default): deploys the n8n Sandbox Service as separate pods — a
  control-plane API plus an in-cluster runner that executes AI-generated code via Docker-in-Docker.
  The runner defaults to `isolation: privileged`; set `runner.acknowledgePrivileged: true` to accept
  it.
