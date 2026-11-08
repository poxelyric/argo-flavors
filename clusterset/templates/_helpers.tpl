{{- define "clusterset.clusterName" -}}
{{`{{ .path.filename | trimSuffix ".yml" | trimSuffix ".yaml" }}`}}
{{- end -}}

{{- define "clusterset.values" -}}
{{- $basePathLen := len (splitList "/" .Values.definitionsRepo.basePath) | int -}}
{{`
{{- $flavorSegments := slice .path.segments `}}{{ $basePathLen }}{{` (sub (len .path.segments) 1) }}
flavor: {{ $flavorSegments | join "-" }}
clusterName: `}}{{ include "clusterset.clusterName" . }}{{`
env: `}}{{ .Values.env }}{{`
`}}
{{- end -}}

{{- define "clusterset.valueFiles" -}}
{{- $basePathLen := len (splitList "/" .Values.definitionsRepo.basePath) | int -}}
{{`
{{- range $i := untilStep `}}{{$basePathLen}}{{` (len .path.segments | add 1 | int) 1 }}
- $definitions/`}}{{`{{ join "/" (slice $.path.segments 0 $i) }}/`}}{{- .Values.appsFile.prefix }}{{ .Values.appsFile.name }}{{`
{{- end }}
- $definitions/{{ .path.path }}/{{ .path.filename }}
`}}
{{- end -}}

{{- define "clusterset.namespace" -}}
{{- if .Values.applicationset.namespaceOverride -}}
{{- .Values.applicationset.namespaceOverride -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}