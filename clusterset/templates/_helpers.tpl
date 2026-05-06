{{- define "clusterset.clusterName" -}}
{{`{{ .path.filename | trimSuffix ".yml" | trimSuffix ".yaml" }}`}}
{{- end -}}

{{- define "clusterset.values" -}}
{{- $basePathLen := len (splitList "/" .Values.definitionsRepo.basePath) | int -}}
{{`
{{- $segments := .path.segments }}
{{- $flavorSegments := slice $segments `}}{{ $basePathLen }}{{` (sub (len $segments) 1) }}
flavor: {{ $flavorSegments | join "-" }}
clusterName: `}}{{ include "clusterset.clusterName" . }}{{`
`}}
{{- end -}}

{{- define "clusterset.valueFiles" -}}
{{- $basePathLen := len (splitList "/" .Values.definitionsRepo.basePath) | int -}}
{{`
{{- $segments := .path.segments -}}
{{- range $i := untilStep `}}{{$basePathLen}}{{` (len $segments | add 1 | int) 1 }}
- $definitions/`}}{{`{{ join "/" (slice $segments 0 $i) }}/`}}{{- .Values.appsFile.prefix }}{{ .Values.appsFile.name }}{{`
{{- end }}
- $definitions/{{ .path.path }}/{{ .path.filename }}
`}}
{{- end -}}