{{/*
Expand the name of the chart.
*/}}
{{- define "awsecho.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "awsecho.fullname" -}}
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
{{- define "awsecho.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "awsecho.labels" -}}
helm.sh/chart: {{ include "awsecho.chart" . }}
{{ include "awsecho.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "awsecho.selectorLabels" -}}
app.kubernetes.io/name: {{ include "awsecho.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "awsecho.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "awsecho.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
  lookup k8s storageclass [awsecho] resource exsit.
*/}}
{{- define "gen.storageclass" -}}
{{- $storageclass := lookup "storage.k8s.io/v1" "StorageClass" .Release.Namespace "awsecho" -}}
{{- if $storageclass -}}
{{/*
   Reusing existing storageclass
*/}}
{{- else -}}
{{/*
    Generate new storageclass
*/}}
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: awsecho
provisioner: efs.csi.aws.com
reclaimPolicy: Delete
allowVolumeExpansion: true
parameters:
  provisioningMode: efs-ap
  fileSystemId: {{ .Values.efsId }}
  directoryPerms: "700"
  gidRangeStart: "1000"
  gidRangeEnd: "2000"
  basePath: "/awsecho"
{{- end -}}
{{- end -}}


{{/*
Create PersistentVolumeClaim to use
*/}}
{{- define "gen.static.pvc" -}}
{{- if .Values.podStaticPvc.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "awsecho.fullname" . }}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.podStaticPvc.capacity }}
  storageClassName: awsecho
{{- else }}
{{/*
   don't create static pvc & pv
*/}}
{{- end }}
{{- end }}

{{/*
AWS ALB Public subnets id array
*/}}
{{- define "aws.albsubnets" -}}
{{- range .Values.ingress.albsubnets }}{{ print .id  }},{{- end }}
{{- end }}

{{/*
AWS Load Balancer Controller, Ingress annotations.
*/}}
{{- define "alb.annotations" -}}
kubernetes.io/ingress.class: alb
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip       ## ip mode, pod could connect with ALB directly
alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
alb.ingress.kubernetes.io/subnets: {{ include "aws.albsubnets" . | trimSuffix "," }}
alb.ingress.kubernetes.io/certificate-arn: {{ .Values.ingress.albcert }}
alb.ingress.kubernetes.io/group.name: {{ .Values.ingress.albgroup }}     ## Multi-Ingress could share One AWS Application LoadBalancer which in a Group
{{- end }}
