{{/*
Expand the name of the chart.
*/}}
{{- define "clearlydefined.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "clearlydefined.fullname" -}}
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
{{- define "clearlydefined.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "clearlydefined.labels" -}}
helm.sh/chart: {{ include "clearlydefined.chart" . }}
{{ include "clearlydefined.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "clearlydefined.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clearlydefined.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "clearlydefined.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "clearlydefined.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Service component labels
*/}}
{{- define "clearlydefined.service.labels" -}}
helm.sh/chart: {{ include "clearlydefined.chart" . }}
{{ include "clearlydefined.service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: service
{{- end }}

{{- define "clearlydefined.service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clearlydefined.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: service
{{- end }}

{{/*
Crawler component labels
*/}}
{{- define "clearlydefined.crawler.labels" -}}
helm.sh/chart: {{ include "clearlydefined.chart" . }}
{{ include "clearlydefined.crawler.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: crawler
{{- end }}

{{- define "clearlydefined.crawler.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clearlydefined.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: crawler
{{- end }}

{{/*
MongoDB component labels
*/}}
{{- define "clearlydefined.mongodb.labels" -}}
helm.sh/chart: {{ include "clearlydefined.chart" . }}
{{ include "clearlydefined.mongodb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: mongodb
{{- end }}

{{- define "clearlydefined.mongodb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clearlydefined.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: mongodb
{{- end }}

{{/*
Redis component labels
*/}}
{{- define "clearlydefined.redis.labels" -}}
helm.sh/chart: {{ include "clearlydefined.chart" . }}
{{ include "clearlydefined.redis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: redis
{{- end }}

{{- define "clearlydefined.redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clearlydefined.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: redis
{{- end }}
