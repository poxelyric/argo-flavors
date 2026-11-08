{{/*
This template acts as a helper to check wether a dictionary has a value in a given path. This is
implemented to support dynamic paths from a string variable.
*/}}
{{- define "serviceset.digByPath" -}}
{{- $path := index . 0 -}}
{{- $default := index . 1 -}}
{{- $dict := index . 2 -}}
{{- tpl (print "{{ dig \"" (splitList "." $path | join `" "`) "\" " (quote $default) " . }}") $dict -}}
{{- end -}}

{{/*
This template is used to modify the given app values by unsetting the mutually exclusive fields that are not present in the patch.
It takes in the given app, the patch app, and the list of mutually exclusive fields.
It iterates over the mutually exclusive fields and checks if they are present in the given app but not in the patch app. If so, it unsets the field in the given app.
The function does not return anything, it modifies the given app in place.
*/}}
{{- define "serviceset.modifyApp" -}}
{{- $givenApp := index . 0 -}}
{{- $patchApp := index . 1 -}}
{{- $mutuallyExclusiveFields := index . 2 -}}
{{- range $fields := $mutuallyExclusiveFields -}}
{{- $found := false -}}
{{- /* Iterate over each field and unset it if it's present in the given app but not in the patch app. If reached the last field and no field was found in the patch app, don't unset it */ -}}
{{- range $i, $path := $fields -}}
  {{- if and (eq "can't find path" (include "serviceset.digByPath" (list $path "can't find path" $patchApp))) (or $found (ne $i (sub (len $fields) 1))) -}}
    {{- if ne "can't find path" (include "serviceset.digByPath" (list $path "can't find path" $givenApp)) -}}
      {{- $lst := splitList "." $path -}}
      {{- tpl (print "{{- $_ := unset ." (initial $lst | join ".") " " (last $lst | quote) " -}}") $givenApp -}}
    {{- end -}}
  {{- else -}}
    {{ $found = true }}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}