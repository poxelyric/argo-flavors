{{- define "clusterset.clusterName" -}}
{{`{{ .path.filename | trimSuffix ".yml" | trimSuffix ".yaml" }}`}}
{{- end -}}

{{- define "clusterset.valueFiles" -}}
{{- $basePathLen := len (splitList "/" .Values.definitionsRepo.basePath) | int -}}
{{`
{{- $segments := .path.segments -}}
{{- range $i := untilStep `}}{{$basePathLen}}{{` (len $segments | add 1 | int) 1 }}
- $definitions/`}}{{`{{ join "/" (slice $segments 0 $i) }}/`}}{{- .Values.appFile.prefix }}{{ .Values.appFile.name }}{{`
{{- end }}
`}}
{{- end -}}