{{- define "clusterset.clusterName" -}}
{{`{{ .path.fileame | trimSuffix ".yml" | trimSuffix ".yaml" }}`}}
{{- end -}}

{{- define "clusterset.valueFiles" -}}
{{`
{{- $segments := .path.segments -}}
{{- range $i,$_ := $segments }}
- $definitions/`}}{{- .Values.definitionsRepo.basePath -}}{{`/{{ join "/" (slice $segments 0 (add $i 1)) }}/`}}{{- .Values.appFile.prefix }}{{ .Values.appFile.name }}{{`
{{- end }}
- $definitions/{{ .path.path }}/`}}{{- .Values.appFile.prefix }}{{ .Values.appFile.name }}{{`
`}}
{{- end -}}