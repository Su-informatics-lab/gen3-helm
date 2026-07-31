# anagine

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: dev](https://img.shields.io/badge/AppVersion-dev-informational?style=flat-square)

Helm chart for the ARDAC Anagine application

## Prerequisites

- Access to the `quay.io/sulab` image repositories configured in `values.yaml`.
- External Secrets Operator and the `gen3-secret-store` SecretStore in `default`.
- An AWS Secrets Manager object named `ardac2prd-default-anagine-creds` with an `OPENAI_API_KEY` property.
- The `gp2` StorageClass, or a persistence override for Ollama.

## Secret setup

The chart never renders a Kubernetes Secret or accepts an API key as a value. Create the AWS secret outside this repository, then apply the example ExternalSecret and wait for synchronization:

```console
kubectl --context ardac2prd apply -f helm/anagine/examples/ardac2prd-external-secret.yaml
kubectl --context ardac2prd -n default wait \
  --for=condition=Ready externalsecret/anagine-secret --timeout=2m
```

Do not commit the API key or pass it through Helm values.

## Installation

Install Anagine into `default` so revproxy can resolve the `anagine-dev` Service directly and the ExternalSecret can use the existing namespaced SecretStore:

```console
helm upgrade --install anagine ./helm/anagine --namespace default
```

The chart is namespace-agnostic, but the ARDAC defaults and ExternalSecret example target `default`. No cross-namespace ExternalName Service is required.

## Revproxy GitOps configuration

The Gen3 values must retain this route:

```yaml
revproxy:
  extraServices:
    - name: anagine
      path: /anagine
      serviceName: anagine-dev
```

This configuration is already present in `ardac2prd/portal.ardac.org/values.yaml` in the [gen3-gitops repository](https://github.com/Su-informatics-lab/gen3-gitops/blob/main/ardac2prd/portal.ardac.org/values.yaml). Portal navigation and GitOps changes are managed in that repository, not by this chart.

## Ollama persistence

The default deployment uses one Ollama replica and a 20 GiB `gp2` ReadWriteOnce PVC. An init container starts a temporary Ollama server against that volume and pulls `config.anagineOllamaModel` before the main server starts. Keep `ollama.replicaCount` at one with this storage mode.

Set `ollama.persistence.enabled=false` for ephemeral storage, or set `ollama.persistence.existingClaim` to use a separately managed PVC.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| api | object | `{"affinity":{},"command":["sh","-lc","node src/server/server.js"],"env":{"ollamaHost":"http://ollama:11434","port":"3000","pyKernelUrl":"http://py-kernel:8000","reportForceFormat":"pdf","reportsDir":"/tmp/reports","rserveHost":"rserve","rservePort":"6311"},"image":{"pullPolicy":"Always","repository":"quay.io/sulab/anagine-api","tag":"latest"},"imagePullSecrets":[],"nodeSelector":{},"podAnnotations":{},"podLabels":{},"podSecurityContext":{},"replicaCount":2,"resources":{},"securityContext":{},"service":{"annotations":{},"port":80,"targetPort":3000,"type":"ClusterIP"},"tolerations":[]}` | Anagine API configuration. |
| api.affinity | object | `{}` | Affinity rules. |
| api.command | list | `["sh","-lc","node src/server/server.js"]` | Command used to start the Anagine API. |
| api.env.ollamaHost | string | `"http://ollama:11434"` | Ollama API URL. |
| api.env.port | string | `"3000"` | Port on which the Anagine API listens. |
| api.env.pyKernelUrl | string | `"http://py-kernel:8000"` | Python kernel URL. |
| api.env.reportForceFormat | string | `"pdf"` | Forced report output format. |
| api.env.reportsDir | string | `"/tmp/reports"` | Directory used for generated reports. |
| api.env.rserveHost | string | `"rserve"` | Rserve Service hostname. |
| api.env.rservePort | string | `"6311"` | Rserve Service port. |
| api.image.pullPolicy | string | `"Always"` | Anagine API image pull policy. |
| api.image.repository | string | `"quay.io/sulab/anagine-api"` | Anagine API image repository. |
| api.image.tag | string | `"latest"` | Anagine API image tag. |
| api.imagePullSecrets | list | `[]` | Image pull secrets. |
| api.nodeSelector | object | `{}` | Node selector. |
| api.podAnnotations | object | `{}` | Pod annotations. |
| api.podLabels | object | `{}` | Additional pod labels. |
| api.podSecurityContext | object | `{}` | Pod security context. |
| api.replicaCount | int | `2` | Number of Anagine API replicas. |
| api.resources | object | `{}` | Resource requests and limits. |
| api.securityContext | object | `{}` | Container security context. |
| api.service.annotations | object | `{}` | Service annotations. |
| api.service.port | int | `80` | Service port. |
| api.service.targetPort | int | `3000` | Container target port. |
| api.service.type | string | `"ClusterIP"` | Kubernetes Service type. |
| api.tolerations | list | `[]` | Tolerations. |
| config | object | `{"anagineArboristHost":"http://revproxy-service.default.svc.cluster.local/authz","anagineGuppyHost":"http://revproxy-service.default.svc.cluster.local/guppy","anagineOllamaModel":"llama3.2:1b","composeProjectName":"anagine","openaiBaseUrl":"https://18.189.29.178/v1","openaiInsecureTls":"true","openaiModel":"gpt-oss:20b"}` | Non-sensitive configuration rendered into anagine-config. |
| config.anagineArboristHost | string | `"http://revproxy-service.default.svc.cluster.local/authz"` | Arborist endpoint used by Anagine. |
| config.anagineGuppyHost | string | `"http://revproxy-service.default.svc.cluster.local/guppy"` | Guppy endpoint used by Anagine. |
| config.anagineOllamaModel | string | `"llama3.2:1b"` | Ollama model used by Anagine and pulled by the Ollama init container. |
| config.composeProjectName | string | `"anagine"` | Compose project name retained from the reference deployment. |
| config.openaiBaseUrl | string | `"https://18.189.29.178/v1"` | OpenAI-compatible API base URL. |
| config.openaiInsecureTls | string | `"true"` | Permit insecure TLS for the OpenAI-compatible endpoint. |
| config.openaiModel | string | `"gpt-oss:20b"` | OpenAI-compatible model name. |
| existingSecret | object | `{"key":"OPENAI_API_KEY","name":"anagine-secret"}` | Existing Secret containing the API key. The chart never creates it. |
| existingSecret.key | string | `"OPENAI_API_KEY"` | Key in the existing Secret. |
| existingSecret.name | string | `"anagine-secret"` | Existing Secret name. |
| ollama | object | `{"affinity":{},"image":{"pullPolicy":"Always","repository":"ollama/ollama","tag":"latest"},"imagePullSecrets":[],"modelPull":{"enabled":true},"nodeSelector":{},"persistence":{"accessModes":["ReadWriteOnce"],"enabled":true,"existingClaim":"","mountPath":"/root/.ollama","size":"20Gi","storageClass":"gp2"},"podAnnotations":{},"podLabels":{},"podSecurityContext":{},"replicaCount":1,"resources":{},"securityContext":{},"service":{"annotations":{},"port":11434,"targetPort":11434,"type":"ClusterIP"},"tolerations":[]}` | Ollama configuration. |
| ollama.affinity | object | `{}` | Affinity rules. |
| ollama.image.pullPolicy | string | `"Always"` | Ollama image pull policy. |
| ollama.image.repository | string | `"ollama/ollama"` | Ollama image repository. |
| ollama.image.tag | string | `"latest"` | Ollama image tag. |
| ollama.imagePullSecrets | list | `[]` | Image pull secrets. |
| ollama.modelPull.enabled | bool | `true` | Pull the configured Ollama model before starting the main container. |
| ollama.nodeSelector | object | `{}` | Node selector. |
| ollama.persistence.accessModes | list | `["ReadWriteOnce"]` | PVC access modes. |
| ollama.persistence.enabled | bool | `true` | Persist the model cache in a PVC. When disabled, use an emptyDir. |
| ollama.persistence.existingClaim | string | `""` | Existing PVC name. Leave empty to create the chart PVC. |
| ollama.persistence.mountPath | string | `"/root/.ollama"` | Ollama model cache mount path. |
| ollama.persistence.size | string | `"20Gi"` | Requested PVC size. |
| ollama.persistence.storageClass | string | `"gp2"` | StorageClass used by the generated PVC. |
| ollama.podAnnotations | object | `{}` | Pod annotations. |
| ollama.podLabels | object | `{}` | Additional pod labels. |
| ollama.podSecurityContext | object | `{}` | Pod security context. |
| ollama.replicaCount | int | `1` | Number of Ollama replicas. Keep at one with the default RWO PVC. |
| ollama.resources | object | `{}` | Resource requests and limits. |
| ollama.securityContext | object | `{}` | Container security context. |
| ollama.service.annotations | object | `{}` | Service annotations. |
| ollama.service.port | int | `11434` | Service port. |
| ollama.service.targetPort | int | `11434` | Container target port. |
| ollama.service.type | string | `"ClusterIP"` | Kubernetes Service type. |
| ollama.tolerations | list | `[]` | Tolerations. |
| pyKernel | object | `{"affinity":{},"image":{"pullPolicy":"Always","repository":"quay.io/sulab/anagine-pykernel","tag":"latest"},"imagePullSecrets":[],"nodeSelector":{},"podAnnotations":{},"podLabels":{},"podSecurityContext":{},"replicaCount":2,"resources":{},"securityContext":{},"service":{"annotations":{},"port":8000,"targetPort":8000,"type":"ClusterIP"},"tolerations":[]}` | Python kernel configuration. |
| pyKernel.affinity | object | `{}` | Affinity rules. |
| pyKernel.image.pullPolicy | string | `"Always"` | Python kernel image pull policy. |
| pyKernel.image.repository | string | `"quay.io/sulab/anagine-pykernel"` | Python kernel image repository. |
| pyKernel.image.tag | string | `"latest"` | Python kernel image tag. |
| pyKernel.imagePullSecrets | list | `[]` | Image pull secrets. |
| pyKernel.nodeSelector | object | `{}` | Node selector. |
| pyKernel.podAnnotations | object | `{}` | Pod annotations. |
| pyKernel.podLabels | object | `{}` | Additional pod labels. |
| pyKernel.podSecurityContext | object | `{}` | Pod security context. |
| pyKernel.replicaCount | int | `2` | Number of Python kernel replicas. |
| pyKernel.resources | object | `{}` | Resource requests and limits. |
| pyKernel.securityContext | object | `{}` | Container security context. |
| pyKernel.service.annotations | object | `{}` | Service annotations. |
| pyKernel.service.port | int | `8000` | Service port. |
| pyKernel.service.targetPort | int | `8000` | Container target port. |
| pyKernel.service.type | string | `"ClusterIP"` | Kubernetes Service type. |
| pyKernel.tolerations | list | `[]` | Tolerations. |
| rserve | object | `{"affinity":{},"image":{"pullPolicy":"Always","repository":"quay.io/sulab/anagine-rserve","tag":"latest"},"imagePullSecrets":[],"livenessProbe":{"failureThreshold":10,"initialDelaySeconds":5,"periodSeconds":10,"tcpSocket":{"port":"rserve"},"timeoutSeconds":3},"nodeSelector":{},"podAnnotations":{},"podLabels":{},"podSecurityContext":{},"replicaCount":2,"resources":{},"securityContext":{},"service":{"annotations":{},"port":6311,"targetPort":6311,"type":"ClusterIP"},"tolerations":[]}` | Rserve configuration. |
| rserve.affinity | object | `{}` | Affinity rules. |
| rserve.image.pullPolicy | string | `"Always"` | Rserve image pull policy. |
| rserve.image.repository | string | `"quay.io/sulab/anagine-rserve"` | Rserve image repository. |
| rserve.image.tag | string | `"latest"` | Rserve image tag. |
| rserve.imagePullSecrets | list | `[]` | Image pull secrets. |
| rserve.livenessProbe | object | `{"failureThreshold":10,"initialDelaySeconds":5,"periodSeconds":10,"tcpSocket":{"port":"rserve"},"timeoutSeconds":3}` | Rserve liveness probe. |
| rserve.nodeSelector | object | `{}` | Node selector. |
| rserve.podAnnotations | object | `{}` | Pod annotations. |
| rserve.podLabels | object | `{}` | Additional pod labels. |
| rserve.podSecurityContext | object | `{}` | Pod security context. |
| rserve.replicaCount | int | `2` | Number of Rserve replicas. |
| rserve.resources | object | `{}` | Resource requests and limits. |
| rserve.securityContext | object | `{}` | Container security context. |
| rserve.service.annotations | object | `{}` | Service annotations. |
| rserve.service.port | int | `6311` | Service port. |
| rserve.service.targetPort | int | `6311` | Container target port. |
| rserve.service.type | string | `"ClusterIP"` | Kubernetes Service type. |
| rserve.tolerations | list | `[]` | Tolerations. |
