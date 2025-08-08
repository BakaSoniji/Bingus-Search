{{- define "bingus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Truncated at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If it is too long, use a hash of the chart name.
*/}}
{{- define "bingus.fullname" -}}
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
{{- define "bingus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bingus.labels" -}}
helm.sh/chart: {{ include "bingus.chart" . }}
{{ include "bingus.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bingus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bingus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "bingus.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "bingus.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Encoder service labels
*/}}
{{- define "bingus.encoder.labels" -}}
{{ include "bingus.labels" . }}
app.kubernetes.io/component: encoder
{{- end }}

{{/*
API service labels
*/}}
{{- define "bingus.api.labels" -}}
{{ include "bingus.labels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
Bot service labels
*/}}
{{- define "bingus.bot.labels" -}}
{{ include "bingus.labels" . }}
app.kubernetes.io/component: bot
{{- end }}

{{/*
Create image name
*/}}
{{- define "bingus.image" -}}
{{- $registry := .Values.global.registry | default "" -}}
{{- $repository := .repository -}}
{{- $tag := .tag | default $.Chart.AppVersion -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end }}
