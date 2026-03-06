{{/*
Expand the name of the chart.
*/}}
{{- define "tyk-oss.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tyk-oss.fullname" -}}
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
{{- define "tyk-oss.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tyk-oss.labels" -}}
helm.sh/chart: {{ include "tyk-oss.chart" . }}
{{ include "tyk-oss.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tyk-oss.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tyk-oss.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tyk-oss.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "tyk-oss.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "tyk-oss.gw_proto" -}}
{{- if index .Values "global" "tls" "gateway" -}}
https
{{- else -}}
http
{{- end -}}
{{- end -}}

{{- define "tyk-oss.gwServicePort" -}}
{{ .Values.global.servicePorts.gateway }}
{{- end -}}

{{- define "tyk-oss.gwControlServiceName" -}}
{{- if index .Values "tyk-gateway" "gateway" "control" "enabled" -}}
    {{ printf "gateway-control-svc-%v" (include "tyk-gateway.fullname" (index .Subcharts "tyk-gateway"))  }}
{{- else -}}
    {{ printf "gateway-svc-%v" (include "tyk-gateway.fullname" (index .Subcharts "tyk-gateway"))  }}
{{- end -}}
{{- end -}}

{{- define "tyk-oss.gwControlPort" -}}
{{- if index .Values "tyk-gateway" "gateway" "control" "enabled" -}}
    {{ index .Values "tyk-gateway" "gateway" "control" "port"  }}
{{- else -}}
    {{ .Values.global.servicePorts.gateway }}
{{- end -}}
{{- end -}}

{{- define "tyk-oss.gwControlURL" -}}
    {{ printf "%v://%v.%v.svc:%v" (include "tyk-oss.gw_proto" . ) (include "tyk-oss.gwControlServiceName" . )  .Release.Namespace (include "tyk-oss.gwControlPort" . ) }}
{{- end -}}

{{/*
Resolve analytics Redis by overlaying global.redis.analytics onto global.redis.
*/}}
{{- define "tyk-oss.analytics_redis" -}}
{{- $redis := default dict .Values.global.redis -}}
{{- $analytics := default dict (index $redis "analytics") -}}
{{- $merged := mergeOverwrite (deepCopy $redis) $analytics -}}
{{- toYaml $merged -}}
{{- end -}}

{{/*
Override tyk-pump Redis helpers so analytics Redis values can be shared with gateway.
*/}}
{{- define "tyk-pump.redis_url" -}}
{{- $redis := include "tyk-oss.analytics_redis" . | fromYaml -}}
{{- if $redis.addrs -}}
{{ join "," $redis.addrs }}
{{- else -}}
redis.{{ .Release.Namespace }}.svc:6379
{{- end -}}
{{- end -}}

{{- define "tyk-pump.redis_secret_name" -}}
{{- $redis := include "tyk-oss.analytics_redis" . | fromYaml -}}
{{- if $redis.passSecret -}}
{{- if $redis.passSecret.name -}}
{{ $redis.passSecret.name }}
{{- else -}}
secrets-{{ include "tyk-pump.fullname" . }}
{{- end -}}
{{- else -}}
secrets-{{ include "tyk-pump.fullname" . }}
{{- end -}}
{{- end -}}

{{- define "tyk-pump.redis_secret_key" -}}
{{- $redis := include "tyk-oss.analytics_redis" . | fromYaml -}}
{{- if $redis.passSecret -}}
{{- if $redis.passSecret.keyName -}}
{{ $redis.passSecret.keyName }}
{{- else -}}
redisPass
{{- end -}}
{{- else -}}
redisPass
{{- end -}}
{{- end -}}

{{- define "tyk-pump.redis_sentinel_secret_name" -}}
{{- $redis := include "tyk-oss.analytics_redis" . | fromYaml -}}
{{- if and $redis.enableSentinel $redis.passSecret -}}
{{- if $redis.passSecret.name -}}
{{ $redis.passSecret.name }}
{{- else -}}
secrets-{{ include "tyk-pump.fullname" . }}
{{- end -}}
{{- else -}}
secrets-{{ include "tyk-pump.fullname" . }}
{{- end -}}
{{- end -}}

{{- define "tyk-pump.redis_sentinel_secret_key" -}}
{{- $redis := include "tyk-oss.analytics_redis" . | fromYaml -}}
{{- if and $redis.enableSentinel $redis.passSecret -}}
{{- if $redis.passSecret.sentinelKeyName -}}
{{ $redis.passSecret.sentinelKeyName }}
{{- else -}}
redisSentinelPass
{{- end -}}
{{- else -}}
redisSentinelPass
{{- end -}}
{{- end -}}
