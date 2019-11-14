{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "sydent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sydent.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sydent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
abstract: |
  Converts a dictionary into an INI formatted file.
values: |
  sec1:
    key1: value1
    key2: value2
    key3:
      - value3a
      - value3b
      - value3b
usage: |
  {{ include "toIni" .Values.test }}
return: |
  [sec1]
  key1 = value1
  key2 = value2
  key3 = value3a,value3b,value3c
*/}}
{{- define "sydent.toIni" -}}
{{- range $section, $details := . }}
[{{ $section }}]
{{- range $dkey, $dvalue := $details }}
{{ $dkey }} = {{ if eq (kindOf $dvalue) "slice" }}{{ include "joinListWithComma" $dvalue }}{{ else }}{{ $dvalue }}{{- end -}}
{{- end }}
{{- end }}
{{- end }}
