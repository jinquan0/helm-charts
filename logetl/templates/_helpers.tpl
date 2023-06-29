{{/*
Expand the name of the chart.
*/}}
{{- define "logetl.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "logetl.fullname" -}}
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
{{- define "logetl.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "logetl.labels" -}}
helm.sh/chart: {{ include "logetl.chart" . }}
{{ include "logetl.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "logetl.selectorLabels" -}}
app.kubernetes.io/name: {{ include "logetl.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "logetl.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "logetl.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
logstash configuration file: /usr/share/logstash/pipeline/logstash.yml
*/}}
{{- define "logstash.yml" -}}
http.host: "0.0.0.0"
path.config: /usr/share/logstash/pipeline
{{- end }}

{{/*
logstash multi-pipelines definition file: /usr/share/logstash/pipeline/pipelines.yml
*/}}
{{- define "pipelines.yml" -}}
- pipeline.id: stream-input
  path.config: "/usr/share/logstash/pipeline/stream-input.conf"
- pipeline.id: stream-filter
  # from external filter.conf file through 'helm --set-file myfilter=*.conf'
  path.config: "/usr/share/logstash/pipeline/stream-filter.conf"
- pipeline.id: stream-output
  path.config: "/usr/share/logstash/pipeline/stream-output.conf"
{{- end }}


{{/*
logstash ETL-Input configuration file.
*/}}
{{- define "stream-input.conf" -}}
{{- if .Values.etl.StreamInput.codecjson.enabled }}
input {
  kafka {
    bootstrap_servers => "172.24.20.220:9092,172.24.20.221:9092,172.24.20.222:9092"
    topics => ["{{ .Values.etl.Kafka.Topic }}"]  ## must modify
    codec => json
    consumer_threads => 1
    group_id => "{{ .Values.etl.Kafka.ConsumerGroup }}"  ## must modify
  }
}
{{- else }}
input {
  kafka {
    bootstrap_servers => "172.24.20.220:9092,172.24.20.221:9092,172.24.20.222:9092"
    topics => ["{{ .Values.etl.Kafka.Topic }}"]  ## must modify
    consumer_threads => 1
    group_id => "{{ .Values.etl.Kafka.ConsumerGroup }}"  ## must modify
  }
}
{{- end }}
{{- end }}


{{/*
logstash ETL-Output configuration file.
*/}}
{{- define "stream-output.conf" -}}
{{- if .Values.etl.StreamOutput.debugconsole.enabled }}
output {
  stdout { }
}
{{- end }}
{{- if .Values.etl.StreamOutput.elasticsearch.enabled }}
output {
  elasticsearch {
    hosts=>["172.24.20.217:9200","172.24.20.218:9200","172.24.20.219:9200"]
    #index=>"{{ .Values.etl.StreamOutput.elasticsearch.Index }}"        # must modity
    ilm_rollover_alias => "{{ .Values.etl.StreamOutput.elasticsearch.IlmRolloverAlias }}"
    #ilm_pattern => "{now/d}-000001"
    ilm_pattern => {{ .Values.etl.StreamOutput.elasticsearch.IlmPattern }}
    ilm_policy => "{{ .Values.etl.StreamOutput.elasticsearch.IlmPolicy }}"
    user => ["{{ .Values.etl.StreamOutput.elasticsearch.User }}"]      # must modify
    password => ["{{ .Values.etl.StreamOutput.elasticsearch.Pass }}"]  # must modify
  }
}
{{- end }}
{{- end }}


{{/*
  Create Ceph PersistentVolumeClaim 
*/}}
{{- define "create.ceph.pvc" -}}
{{- if .Values.PodCephPvc.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Values.etl.Name }}
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: {{ .Values.PodCephPvc.Capacity }}
  storageClassName: {{ .Values.PodCephPvc.StorageClass }}
{{- else }}
{{/*
   don't create pvc & pv
*/}}
{{- end }}
{{- end }}
