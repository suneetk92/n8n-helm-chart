{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "n8n.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "n8n.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "n8n.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Main name
*/}}
{{- define "n8n.main.name" -}}
{{- printf "%s-main" (include "n8n.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create n8n main full name
*/}}
{{- define "n8n.main.fullname" -}}
{{- printf "%s-main" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels for extra manifests (no component-specific label)
*/}}
{{- define "n8n.extraManifests.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
app.kubernetes.io/name: {{ include "n8n.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Main labels
*/}}
{{- define "n8n.main.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
{{ include "n8n.main.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: main
app.kubernetes.io/part-of: n8n
{{- end }}

{{/*
Main selector labels
Selector fields are immutable after kubernetes resource creation. Do not edit this function.
*/}}
{{- define "n8n.main.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "n8n.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "n8n.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the chart-managed Secret holding the external Redis credentials.
Used as the default when externalRedis.existingSecret is unset. Not a subchart reference;
the bundled redis subchart was removed in 3.0.0.
*/}}
{{- define "n8n.redis.fullname" -}}
{{- printf "%s-redis" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name of the chart-managed Secret holding the external PostgreSQL credentials.
Used as the default when externalPostgresql.existingSecret is unset. Not a subchart reference;
the bundled postgresql subchart was removed in 3.0.0.
*/}}
{{- define "n8n.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create PostgreSQL database username
*/}}
{{- define "n8n.postgresql.username" -}}
{{- printf "%s" .Values.externalPostgresql.username | default "postgres" }}
{{- end }}

{{/*
Worker name
*/}}
{{- define "n8n.worker.name" -}}
{{- printf "%s-worker" (include "n8n.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create n8n worker full name
*/}}
{{- define "n8n.worker.fullname" -}}
{{- printf "%s-worker" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
n8n worker labels
*/}}
{{- define "n8n.worker.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
{{ include "n8n.worker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: n8n
{{- end }}

{{/*
Worker selector labels
Selector fields are immutable after kubernetes resource creation. Do not edit this function.
*/}}
{{- define "n8n.worker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n.worker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: worker
{{- end }}

{{/*
Webhook name
*/}}
{{- define "n8n.webhook.name" -}}
{{- printf "%s-webhook" (include "n8n.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create n8n webhook full name
*/}}
{{- define "n8n.webhook.fullname" -}}
{{- printf "%s-webhook" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
n8n webhook labels
*/}}
{{- define "n8n.webhook.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
{{ include "n8n.webhook.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: n8n
{{- end }}

{{/*
Webhook selector labels
Selector fields are immutable after kubernetes resource creation. Do not edit this function.
*/}}
{{- define "n8n.webhook.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n.webhook.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: webhook
{{- end }}

{{/*
MCP webhook name
*/}}
{{- define "n8n.mcp-webhook.name" -}}
{{- printf "%s-mcp-webhook" (include "n8n.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create n8n MCP webhook full name
*/}}
{{- define "n8n.mcp-webhook.fullname" -}}
{{- printf "%s-mcp-webhook" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
n8n MCP webhook labels
*/}}
{{- define "n8n.mcp-webhook.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
{{ include "n8n.mcp-webhook.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: n8n
{{- end }}

{{/*
n8n MCP webhook selector labels
Selector fields are immutable after kubernetes resource creation. Do not edit this function.
*/}}
{{- define "n8n.mcp-webhook.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n.mcp-webhook.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: mcp
{{- end }}

{{/*
Generate random hex similar to `openssl rand -hex 16` command.
Usage: {{ include "n8n.generateRandomHex" 32 }}
*/}}
{{- define "n8n.generateRandomHex" -}}
{{- $length := . -}}
{{- $chars := list "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f" -}}
{{- $result := "" -}}
{{- range $i := until $length -}}
  {{- $result = print $result (index $chars (randInt 0 16)) -}}
{{- end -}}
{{- $result -}}
{{- end -}}

{{/*
Task runners name
*/}}
{{- define "n8n.taskRunners.name" -}}
{{- printf "%s-task-runners" (include "n8n.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create n8n task runners full name
*/}}
{{- define "n8n.taskRunners.fullname" -}}
{{- printf "%s-task-runners" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
n8n task runners labels
*/}}
{{- define "n8n.taskRunners.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
{{ include "n8n.taskRunners.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: n8n
{{- end }}

{{/*
Task runners selector labels
Selector fields are immutable after kubernetes resource creation. Do not edit this function.
*/}}
{{- define "n8n.taskRunners.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n.taskRunners.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: task-runners
{{- end }}

{{/*
Extract package names from a list of strings
*/}}
{{- define "n8n.packageNames" -}}
{{- $packageNames := list -}}
{{- range . -}}
  {{- $matches := regexFindAll "^@?[^@]+" . 1 -}}
  {{- if and $matches (not (hasPrefix "n8n-nodes-" (index $matches 0))) -}}
    {{- $packageNames = append $packageNames (index $matches 0) -}}
  {{- end -}}
{{- end -}}
{{- join "," $packageNames -}}
{{- end -}}

{{/*
Return a non-empty string if the package is a community package.
*/}}
{{- define "n8n.isCommunityPackage" -}}
{{- $pkg := regexReplaceAll "@[^/@]+$" . "" -}}
{{- $name := $pkg -}}
{{- if hasPrefix "@" $pkg -}}
  {{- $name = (splitList "/" $pkg | last) -}}
{{- end -}}
{{- if hasPrefix "n8n-nodes-" $name -}}true{{- end -}}
{{- end -}}

{{/*
Filter community packages (starting with n8n-nodes-, also if scoped)
*/}}
{{- define "n8n.communityPackages" -}}
{{- $community := list -}}
{{- range .Values.nodes.external.packages -}}
{{- if include "n8n.isCommunityPackage" . -}}
{{- $community = append $community . -}}
{{- end -}}
{{- end -}}
{{- join " " $community -}}
{{- end -}}

{{/*
Filter non-community packages (as a space-separated string)
*/}}
{{- define "n8n.nonCommunityPackages" -}}
{{- $nonCommunity := list -}}
{{- range .Values.nodes.external.packages -}}
{{- if not (include "n8n.isCommunityPackage" .) -}}
{{- $nonCommunity = append $nonCommunity . -}}
{{- end -}}
{{- end -}}
{{- join " " $nonCommunity -}}
{{- end -}}

{{/*
Convert n8n log level to npm log level
*/}}
{{- define "n8n.npmLogLevel" -}}
{{- $level := . | lower -}}
{{- if eq $level "debug" }}verbose
{{- else }}{{ $level }}
{{- end -}}
{{- end -}}

{{/*
n8n main persistence name
*/}}
{{- define "n8n-main.persistence.name" -}}
{{- printf "%s-persistence" (include "n8n.main.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
n8n main persistence full name
*/}}
{{- define "n8n-main.persistence.fullname" -}}
{{- printf "%s-persistence" (include "n8n.main.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
n8n main persistence labels
*/}}
{{- define "n8n-main.persistence.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
{{ include "n8n-main.persistence.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: n8n
{{- end }}

{{/*
n8n main persistence selector labels
Selector fields are immutable after kubernetes resource creation. Do not edit this function.
*/}}
{{- define "n8n-main.persistence.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n-main.persistence.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: persistence
{{- end }}

{{/*
n8n worker persistence name
*/}}
{{- define "n8n-worker.persistence.name" -}}
{{- printf "%s-persistence" (include "n8n.worker.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
n8n worker persistence full name
*/}}
{{- define "n8n-worker.persistence.fullname" -}}
{{- printf "%s-persistence" (include "n8n.worker.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
n8n worker persistence labels
*/}}
{{- define "n8n-worker.persistence.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
{{ include "n8n-worker.persistence.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: n8n
{{- end }}

{{/*
n8n worker persistence selector labels
Selector fields are immutable after kubernetes resource creation. Do not edit this function.
*/}}
{{- define "n8n-worker.persistence.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n-worker.persistence.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: persistence
{{- end }}

{{/*
n8n python packages PVC name
*/}}
{{- define "n8n-python.packages.name" -}}
{{- printf "%s-python-packages" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
n8n python packages PVC full name (respects existingClaim)
*/}}
{{- define "n8n-python.packages.fullname" -}}
{{- default (include "n8n-python.packages.name" .) .Values.nodes.python.persistence.existingClaim -}}
{{- end -}}

{{/*
n8n community packages PVC name
*/}}
{{- define "n8n-community.packages.name" -}}
{{- printf "%s-community-packages" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
n8n community packages PVC full name (respects existingClaim)
*/}}
{{- define "n8n-community.packages.fullname" -}}
{{- default (include "n8n-community.packages.name" .) .Values.nodes.external.persistence.existingClaim -}}
{{- end -}}

{{/*
Returns "true" when main.persistence already covers /home/node/.n8n/nodes,
making a separate community-node-modules volume redundant.
Only true when persistence is enabled, mountPath is the default, and no subPath
is redirecting the mount to a subdirectory of the PVC.
*/}}
{{- define "n8n.main.coversCommunityNodes" -}}
{{- if and .Values.main.persistence.enabled (not .Values.main.persistence.subPath) (eq .Values.main.persistence.mountPath "/home/node/.n8n") -}}
true
{{- end -}}
{{- end -}}

{{/*
Same check as n8n.main.coversCommunityNodes but for the worker persistence volume.
*/}}
{{- define "n8n.worker.coversCommunityNodes" -}}
{{- if and .Values.worker.persistence.enabled (not .Values.worker.persistence.subPath) (eq .Values.worker.persistence.mountPath "/home/node/.n8n") -}}
true
{{- end -}}
{{- end -}}

{{/*
n8n task runner uv install shell command string (unquoted)
*/}}
{{- define "n8n.taskRunners.uvInstallCommand" -}}
UV_CACHE_DIR=/tmp/.uv-cache UV_LINK_MODE=copy uv pip install --target /home/node/.python-packages {{ .Values.nodes.python.external.packages | join " " }} && export PYTHONPATH=/home/node/.python-packages && exec /usr/local/bin/task-runner-launcher javascript{{ ternary " python" "" .Values.nodes.python.enabled }}
{{- end -}}

{{/*
Credential environment variables shared by every n8n container (main, worker, webhook,
MCP webhook). These deliver secret values that cannot travel through the plain ConfigMaps:
the SMTP password and the instance owner's bcrypt password hash. The non-secret halves of
both features live in the email ConfigMap.

Emitted as a list fragment, so include it where env entries are expected:
  {{- include "n8n.credentialEnv" . | nindent 12 }}
*/}}
{{- define "n8n.credentialEnv" -}}
{{- if and .Values.smtp.enabled (or .Values.smtp.password .Values.smtp.existingSecret) }}
- name: N8N_SMTP_PASS
  valueFrom:
    secretKeyRef:
      name: {{ default (printf "%s-smtp" (include "n8n.fullname" .)) .Values.smtp.existingSecret }}
      key: {{ ternary .Values.smtp.passwordKey "password" (ne .Values.smtp.existingSecret "") }}
{{- end }}
{{- if .Values.instanceOwner.enabled }}
- name: N8N_INSTANCE_OWNER_PASSWORD_HASH
  valueFrom:
    secretKeyRef:
      name: {{ default (printf "%s-instance-owner" (include "n8n.fullname" .)) .Values.instanceOwner.existingSecret }}
      key: {{ ternary .Values.instanceOwner.passwordHashKey "password-hash" (ne .Values.instanceOwner.existingSecret "") }}
{{- end }}
{{- end -}}

{{/*
n8n task runners launcher config name
*/}}
{{- define "n8n.taskRunners.launcherConfigName" -}}
{{- printf "%s-launcher-config" (include "n8n.taskRunners.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
n8n task runners launcher config file (/etc/n8n-task-runners.json).

The task-runner-launcher image ships its own default of this file, whose
env-overrides hard-code NODE_FUNCTION_ALLOW_EXTERNAL=moment,
NODE_FUNCTION_ALLOW_BUILTIN=crypto and blank N8N_RUNNERS_STDLIB_ALLOW /
N8N_RUNNERS_EXTERNAL_ALLOW. Those overrides win over whatever this chart sets
as plain container env vars (NODE_FUNCTION_ALLOW_EXTERNAL etc. below), which
is why setting only the container env var has no effect. This chart mounts a
replacement file, generated from the same values that already drive the
container env vars, so both stay consistent.
*/}}
{{- define "n8n.taskRunners.launcherConfigJSON" -}}
{{- $jsOverrides := dict "N8N_RUNNERS_HEALTH_CHECK_SERVER_HOST" "0.0.0.0" -}}
{{- if .Values.nodes.builtin.enabled -}}
  {{- $_ := set $jsOverrides "NODE_FUNCTION_ALLOW_BUILTIN" (ternary (join "," .Values.nodes.builtin.modules) "*" (gt (len .Values.nodes.builtin.modules) 0)) -}}
{{- end -}}
{{- if .Values.nodes.external.allowAll -}}
  {{- $_ := set $jsOverrides "NODE_FUNCTION_ALLOW_EXTERNAL" "*" -}}
{{- else if .Values.nodes.external.packages -}}
  {{- $_ := set $jsOverrides "NODE_FUNCTION_ALLOW_EXTERNAL" (include "n8n.packageNames" .Values.nodes.external.packages) -}}
{{- end -}}
{{- $pyOverrides := dict "N8N_RUNNERS_STDLIB_ALLOW" (join "," .Values.nodes.python.builtin.modules) -}}
{{- if .Values.nodes.python.external.allowAll -}}
  {{- $_ := set $pyOverrides "N8N_RUNNERS_EXTERNAL_ALLOW" "*" -}}
{{- else -}}
  {{- $_ := set $pyOverrides "N8N_RUNNERS_EXTERNAL_ALLOW" (join "," .Values.nodes.python.external.packages) -}}
{{- end -}}
{{- $config := dict "task-runners" (list
  (dict
    "runner-type" "javascript"
    "workdir" "/home/runner"
    "command" "/usr/local/bin/node"
    "args" (list "--disallow-code-generation-from-strings" "--disable-proto=delete" "/opt/runners/task-runner-javascript/dist/start.js")
    "health-check-server-port" "5681"
    "allowed-env" (list "PATH" "GENERIC_TIMEZONE" "NODE_OPTIONS" "NODE_PATH" "N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT" "N8N_RUNNERS_TASK_TIMEOUT" "N8N_RUNNERS_MAX_CONCURRENCY" "N8N_SENTRY_DSN" "N8N_VERSION" "ENVIRONMENT" "DEPLOYMENT_NAME" "HOME")
    "env-overrides" $jsOverrides
  )
  (dict
    "runner-type" "python"
    "workdir" "/home/runner"
    "command" "/opt/runners/task-runner-python/.venv/bin/python"
    "args" (list "-I" "-B" "-X" "disable_remote_debug" "-m" "src.main")
    "health-check-server-port" "5682"
    "allowed-env" (list "PATH" "N8N_RUNNERS_LAUNCHER_LOG_LEVEL" "N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT" "N8N_RUNNERS_TASK_TIMEOUT" "N8N_RUNNERS_MAX_CONCURRENCY" "N8N_SENTRY_DSN" "N8N_VERSION" "ENVIRONMENT" "DEPLOYMENT_NAME")
    "env-overrides" $pyOverrides
  )
) -}}
{{- $config | toPrettyJson -}}
{{- end -}}

{{/*
n8n npm install script logic
*/}}
{{- define "n8n.npmInstallScript" -}}
export PACKAGES="{{ join " " .Values.nodes.external.packages }}"
export COMMUNITY_PACKAGES="{{ include "n8n.communityPackages" . }}"
export NON_COMMUNITY_PACKAGES="{{ include "n8n.nonCommunityPackages" . }}"
echo "$PACKAGES" | sha256sum > /npmdata/packages.hash.new
if [ ! -f /npmdata/packages.hash ] || ! cmp /npmdata/packages.hash /npmdata/packages.hash.new; then
  if [ -n "$NON_COMMUNITY_PACKAGES" ]; then
    npm install --loglevel {{ include "n8n.npmLogLevel" .Values.log.level }} --no-save --ignore-scripts $NON_COMMUNITY_PACKAGES --prefix /npmdata
  fi
  if [ -n "$COMMUNITY_PACKAGES" ]; then
    npm install --loglevel {{ include "n8n.npmLogLevel" .Values.log.level }} --no-save --ignore-scripts $COMMUNITY_PACKAGES --prefix /nodesdata/nodes
  fi
  mv /npmdata/packages.hash.new /npmdata/packages.hash
else
  rm /npmdata/packages.hash.new
fi
{{- end -}}

{{/*
Check Certificate Authority file defined for the Postgresql SSL connection
*/}}
{{- define "n8n.postgres.ssl.hasCA" -}}
{{- $result := false -}}
{{- if and (eq .Values.db.type "postgresdb") .Values.db.postgresdb.ssl.enabled (or .Values.db.postgresdb.ssl.base64EncodedCertificateAuthorityFile .Values.db.postgresdb.ssl.existingCertificateAuthorityFileSecret.name) -}}
  {{- $result = true -}}
{{- end -}}
{{- $result -}}
{{- end -}}

{{/*
Check Certificate file defined for the Postgresql SSL connection
*/}}
{{- define "n8n.postgres.ssl.hasCert" -}}
{{- $result := false -}}
{{- if and (eq .Values.db.type "postgresdb") .Values.db.postgresdb.ssl.enabled (or .Values.db.postgresdb.ssl.base64EncodedCertFile .Values.db.postgresdb.ssl.existingCertFileSecret.name) -}}
  {{- $result = true -}}
{{- end -}}
{{- $result -}}
{{- end -}}

{{/*
Check Private Key file defined for the Postgresql SSL connection
*/}}
{{- define "n8n.postgres.ssl.hasKey" -}}
{{- $result := false -}}
{{- if and (eq .Values.db.type "postgresdb") .Values.db.postgresdb.ssl.enabled (or .Values.db.postgresdb.ssl.base64EncodedPrivateKeyFile .Values.db.postgresdb.ssl.existingPrivateKeyFileSecret.name) -}}
  {{- $result = true -}}
{{- end -}}
{{- $result -}}
{{- end -}}

{{/*
Check postgres ssl certificate file content exist or not
*/}}
{{- define "n8n.postgres.ssl.hasFileInternal" -}}
{{- $internalResult := false -}}
{{- if or (eq (include "n8n.postgres.ssl.hasCA" .) "true") (eq (include "n8n.postgres.ssl.hasCert" .) "true") (eq (include "n8n.postgres.ssl.hasKey" .) "true") -}}
  {{- $internalResult = true -}}
{{- end -}}
{{- $internalResult -}}
{{- end -}}


{{/*
Sandbox service API name
*/}}
{{- define "n8n.sandbox-api.name" -}}
{{- printf "%s-sandbox-api" (include "n8n.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Sandbox service API full name
*/}}
{{- define "n8n.sandbox-api.fullname" -}}
{{- printf "%s-sandbox-api" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Sandbox service API labels
*/}}
{{- define "n8n.sandbox-api.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
{{ include "n8n.sandbox-api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: n8n
{{- end }}

{{/*
Sandbox service API selector labels
Selector fields are immutable after kubernetes resource creation. Do not edit this function.
*/}}
{{- define "n8n.sandbox-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n.sandbox-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: sandbox-api
{{- end }}

{{/*
Sandbox service runner name
*/}}
{{- define "n8n.sandbox-runner.name" -}}
{{- printf "%s-sandbox-runner" (include "n8n.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Sandbox service runner full name
*/}}
{{- define "n8n.sandbox-runner.fullname" -}}
{{- printf "%s-sandbox-runner" (include "n8n.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Sandbox service runner labels
*/}}
{{- define "n8n.sandbox-runner.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
{{ include "n8n.sandbox-runner.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: n8n
{{- end }}

{{/*
Sandbox service runner selector labels
Selector fields are immutable after kubernetes resource creation. Do not edit this function.
*/}}
{{- define "n8n.sandbox-runner.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n.sandbox-runner.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: sandbox-runner
{{- end }}

{{/*
Sandbox auth Secret name: user-supplied, or the chart-managed one.
*/}}
{{- define "n8n.sandbox.authSecretName" -}}
{{- default (printf "%s-sandbox-auth" (include "n8n.fullname" .)) .Values.sandboxService.auth.existingSecret -}}
{{- end }}

{{/*
Resolve one sandbox auth value.
Usage: include "n8n.sandbox.authValue" (dict "root" $ "key" "api-keys" "value" .Values.sandboxService.auth.apiKeys)
When an existing Secret is supplied the chart cannot read it at render time, so nothing is rendered into the
chart-managed Secret and pods consume the user's Secret directly. Otherwise a configured value wins over a
generated one, and a previously generated value is reused so repeated upgrades do not rotate credentials.
*/}}
{{- define "n8n.sandbox.authValue" -}}
{{- $root := .root -}}
{{- if $root.Values.sandboxService.auth.existingSecret -}}
{{- else if .value -}}
{{- .value -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" $root.Release.Namespace (include "n8n.sandbox.authSecretName" $root) -}}
{{- $current := "" -}}
{{- if and $existing $existing.data (index $existing.data .key) -}}
{{- $current = index $existing.data .key | b64dec -}}
{{- end -}}
{{- default (include "n8n.generateRandomHex" 32) $current -}}
{{- end -}}
{{- end }}

{{/*
Name of the Secret that carries the sandbox service API key consumed by n8n.
An explicit `aiAssistant.sandbox.existingApiKeySecret` wins; otherwise the sandbox service's own auth Secret is
reused, so an in-cluster deployment needs no extra wiring.
*/}}
{{- define "n8n.sandbox.apiKeyName" -}}
{{- if .Values.aiAssistant.sandbox.existingApiKeySecret -}}
{{- .Values.aiAssistant.sandbox.existingApiKeySecret -}}
{{- else -}}
{{- include "n8n.sandbox.authSecretName" . -}}
{{- end -}}
{{- end }}

{{/*
Key inside `n8n.sandbox.apiKeyName` that holds the sandbox service API key.
*/}}
{{- define "n8n.sandbox.apiKeyKeyName" -}}
{{- if .Values.aiAssistant.sandbox.existingApiKeySecret -}}
{{- .Values.aiAssistant.sandbox.apiKeyKey -}}
{{- else -}}
{{- .Values.sandboxService.auth.keys.apiKeys -}}
{{- end -}}
{{- end }}

{{/*
Sandbox API base URL as seen by n8n. An explicit value always wins so an external service can be pointed at
without disabling the in-cluster one.
*/}}
{{- define "n8n.sandbox.serviceUrl" -}}
{{- if .Values.aiAssistant.sandbox.serviceUrl -}}
{{- .Values.aiAssistant.sandbox.serviceUrl -}}
{{- else -}}
{{- printf "http://%s.%s.svc.cluster.local:8080" (include "n8n.sandbox-api.fullname" .) .Release.Namespace -}}
{{- end -}}
{{- end }}

{{/*
Sandbox certificate Secret name for one of the four certificates.
Usage: include "n8n.sandbox.certSecretName" (dict "root" $ "cert" .Values.sandboxService.tls.certificates.apiRegistrationServer "suffix" "registration-tls")
*/}}
{{- define "n8n.sandbox.certSecretName" -}}
{{- if .cert.secretName -}}
{{- .cert.secretName -}}
{{- else -}}
{{- printf "%s-%s" (include "n8n.fullname" .root) .suffix | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{/*
Fail fast on sandbox service misconfiguration. Rendered at the top of every sandbox template so a broken
configuration is reported instead of producing pods that crash-loop.
*/}}
{{- define "n8n.sandbox.validate" -}}
{{- if .Values.sandboxService.enabled -}}
{{- if and (eq .Values.sandboxService.runner.isolation "privileged") (not .Values.sandboxService.runner.acknowledgePrivileged) -}}
{{- fail "sandboxService.runner.isolation is \"privileged\", which grants root-equivalent access to its node. Set sandboxService.runner.acknowledgePrivileged=true to accept this, and make sure the namespace allows privileged pods (Pod Security Admission level \"privileged\")." -}}
{{- end -}}
{{- if eq .Values.sandboxService.tls.mode "certManager" -}}
{{- if not .Values.sandboxService.tls.certManager.issuerRef.name -}}
{{- fail "sandboxService.tls.certManager.issuerRef.name is required when sandboxService.tls.mode is \"certManager\"." -}}
{{- end -}}
{{- else if eq .Values.sandboxService.tls.mode "existingSecret" -}}
{{/*
The API and the runner authenticate each other with mTLS; there is no plaintext mode, so all four
certificate Secrets are mounted unconditionally. In this mode the chart does not create them, and an
unset secretName falls back to a derived `<release>-sandbox-*-tls` name that nothing ever creates,
leaving the pod stuck on FailedMount indefinitely. Refuse to install instead.
*/}}
{{- range $name := (list "apiRegistrationServer" "apiControlClient" "runnerRegistrationClient" "runnerControlServer") -}}
{{- if not (get $.Values.sandboxService.tls.certificates $name).secretName -}}
{{- fail (printf "sandboxService.tls.certificates.%s.secretName is required when sandboxService.tls.mode is \"existingSecret\". The sandbox API and runner authenticate each other with mTLS, so all four certificate Secrets must already exist; leaving this unset makes the pod mount a Secret the chart never creates and hang in FailedMount. Either pre-create the four Secrets and set their names, or use sandboxService.tls.mode=certManager with sandboxService.tls.certManager.issuerRef set." $name) -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- fail "sandboxService.tls.mode must be either \"existingSecret\" or \"certManager\"." -}}
{{- end -}}
{{/*
The API presents auth.runnerApiKey to the runner, which only accepts keys listed in
auth.runnerApiKeys. When both are set explicitly they must agree, or every container creation fails
with "rpc error: code = Unauthenticated desc = invalid api key". When runnerApiKeys is left unset the
chart derives it from runnerApiKey, so there is nothing to check.
*/}}
{{- if and .Values.sandboxService.auth.runnerApiKey .Values.sandboxService.auth.runnerApiKeys -}}
{{- $accepted := splitList "," .Values.sandboxService.auth.runnerApiKeys -}}
{{- $trimmed := list -}}
{{- range $accepted -}}
{{- $trimmed = append $trimmed (trim .) -}}
{{- end -}}
{{- if not (has (trim $.Values.sandboxService.auth.runnerApiKey) $trimmed) -}}
{{- fail "sandboxService.auth.runnerApiKey must appear in sandboxService.auth.runnerApiKeys. The API presents runnerApiKey to the runner and the runner only accepts keys listed in runnerApiKeys, so a mismatch makes every sandbox creation fail with \"invalid api key\". Leave runnerApiKeys unset to have the chart derive it from runnerApiKey." -}}
{{- end -}}
{{- end -}}
{{- if and (not .Values.sandboxService.auth.existingSecret) (eq .Values.sandboxService.api.store "postgres") -}}
{{- range $k, $v := dict "apiKeys" .Values.sandboxService.auth.apiKeys "runnerRegistrationToken" .Values.sandboxService.auth.runnerRegistrationToken "runnerApiKey" .Values.sandboxService.auth.runnerApiKey "runnerApiKeys" .Values.sandboxService.auth.runnerApiKeys -}}
{{- if and $v (contains "changeme" $v) -}}
{{- fail (printf "sandboxService.auth.%s looks like a placeholder. Generate a real secret; do not commit it." $k) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if gt (int .Values.sandboxService.replicas) 1 -}}
{{- if eq .Values.sandboxService.api.store "sqlite" -}}
{{- fail "sandboxService.replicas must be 1 while sandboxService.api.store is \"sqlite\"; the SQLite store cannot be shared between API pods. Set sandboxService.api.store to \"postgres\" to scale the API." -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if and .Values.aiAssistant.sandbox.enabled (not .Values.sandboxService.enabled) -}}
{{- if or (not .Values.aiAssistant.sandbox.serviceUrl) (not .Values.aiAssistant.sandbox.existingApiKeySecret) -}}
{{- fail "aiAssistant.sandbox.enabled points at a sandbox service outside this cluster; set aiAssistant.sandbox.serviceUrl and aiAssistant.sandbox.existingApiKeySecret." -}}
{{- end -}}
{{- end -}}
{{- if and .Values.aiAssistant.searxng.url (not (hasPrefix "http" .Values.aiAssistant.searxng.url)) -}}
{{- fail "aiAssistant.searxng.url must include a scheme (http:// or https://)." -}}
{{- end -}}
{{- end }}

{{/*
Whether n8n containers should consume the AI ConfigMap.
*/}}
{{- define "n8n.ai.enabled" -}}
{{- if .Values.aiAssistant.enabled -}}true{{- end -}}
{{- end }}

