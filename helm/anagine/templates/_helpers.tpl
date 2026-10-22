{{/* Chart name and version for labels. */}}
{{- define "anagine.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Service account used by the Anagine API. */}}
{{- define "anagine.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default .Chart.Name .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end }}

{{/* Labels shared by every resource. */}}
{{- define "anagine.labels" -}}
helm.sh/chart: {{ include "anagine.chart" . }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
