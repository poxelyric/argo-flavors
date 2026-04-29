{{- define "clusterset.clusterName" -}}
{{`{{ .path.filename | trimSuffix ".yml" | trimSuffix ".yaml" }}`}}
{{- end -}}

{{- define "clusterset.valueFiles" -}}
{{- $basePathLen := len (splitList "/" .Values.definitionsRepo.basePath) -}}
{{`
{{- $segments := .path.segments -}}
{{- range $i,$_ := $segments }}
- $definitions/`}}{{`/{{ join "/" (slice $segments 0 (add $i `}}{{$basePathLen}}{{` )) }}/`}}{{- .Values.appFile.prefix }}{{ .Values.appFile.name }}{{`
{{- end }}
- $definitions/{{ .path.path }}/`}}{{- .Values.appFile.prefix }}{{ .Values.appFile.name }}{{`
`}}
{{- end -}}