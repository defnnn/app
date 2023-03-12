package c

import (
	core "github.com/defn/boot/k8s.io/api/core/v1"
	batch "github.com/defn/boot/k8s.io/api/batch/v1"
	apps "github.com/defn/boot/k8s.io/api/apps/v1"
	rbac "github.com/defn/boot/k8s.io/api/rbac/v1"
)

kustomize: (#Transform & {
	transformer: #TransformChicken

	inputs: {
		rocky: {}
		rosie: {}
	}
}).outputs

kustomize: "hello": #Kustomize & {
	namespace: "default"

	resource: "hello": {
		url: "hello.yaml"
	}

	resource: "default": {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name:      "default"
			namespace: "default"
			labels: "kuma.io/sidecar-injection": "disabled"
			labels: "kuma.io/mesh":              "dev"
		}
	}
}

kustomize: "mastodon": #Kustomize & {
	namespace: "mastodon"

	resource: "mastodon": {
		url: "mastodon.yaml"
	}
}

kustomize: "events": #Kustomize & {
	namespace: "default"

	resource: "events": {
		url: "events.yaml"
	}
}

kustomize: "demo1": #Kustomize & {
	resource: "demo": {
		url: "https://bit.ly/demokuma"
	}
}

kustomize: "demo2": #Kustomize & {
	resource: "demo": {
		url: "https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml"
	}
}

kustomize: "argo-cd": #Kustomize & {
	namespace: "argocd"

	resource: "namespace-argocd": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "argocd"
		}
	}

	resource: "argo-cd": {
		url: "https://raw.githubusercontent.com/argoproj/argo-cd/v2.6.4/manifests/install.yaml"
	}

	psm: "configmap-argocd-cm": core.#ConfigMap & {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: name: "argocd-cm"
		data: {
			"kustomize.buildOptions": "--enable-helm"

			"application.resourceTrackingMethod": "annotation"

			"resource.customizations.health.networking.k8s.io_Ingress": """
				hs = {}
				hs.status = "Healthy"
				return hs
				"""

			"resource.customizations.health.tf.isaaguilar.com_Terraform": """
				hs = {}
				hs.status = "Progressing"
				hs.message = ""
				if obj.status ~= nil then
					if obj.status.phase ~= nil then
					  	if obj.status.phase == "completed" then
				   			hs.status = "Healthy"
					 	end

					  	if obj.status.stage ~= nil then
							if obj.status.stage.reason ~= nil then
						  		hs.message = obj.status.stage.reason
							end
					  	end
					end
				end
				return hs
				"""

			"resource.customizations.health.argoproj.io_Application": """
				hs = {}
				hs.status = "Progressing"
				hs.message = ""
				if obj.status ~= nil then
					if obj.status.health ~= nil then
					hs.status = obj.status.health.status
					if obj.status.health.message ~= nil then
						hs.message = obj.status.health.message
					end
					end
				end
				return hs
				"""

			"resource.customizations.ignoreDifferences.admissionregistration.k8s.io_MutatingWebhookConfiguration": """
				jsonPointers:
				  - /webhooks/0/clientConfig/caBundle
				  - /webhooks/0/rules

				"""

			"resource.customizations.ignoreDifferences.admissionregistration.k8s.io_ValidatingWebhookConfiguration": """
				jsonPointers:
				  - /webhooks/0/rules

				"""

			"resource.customizations.ignoreDifferences.apps_Deployment": """
				jsonPointers:
				  - /spec/template/spec/tolerations

				"""

			"resource.customizations.ignoreDifferences.kyverno.io_ClusterPolicy": """
				jqPathExpressions:
				  - .spec.rules[] | select(.name|test("autogen-."))

				"""
		}
	}
}

kustomize: "argo-events": #KustomizeHelm & {
	namespace: "argo-events"

	helm: {
		release: "argo-events"
		name:    "argo-events"
		version: "2.0.6"
		repo:    "https://argoproj.github.io/argo-helm"
	}

	resource: "namespace-argo-events": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "argo-events"
		}
	}
}

kustomize: "argo-workflows": #KustomizeHelm & {
	helm: {
		release:   "argo-workflows"
		name:      "argo-workflows"
		namespace: "argo-workflows"
		version:   "0.20.2"
		repo:      "https://argoproj.github.io/argo-helm"
	}

	resource: "namespace-argo-workflows": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "argo-work-flows"
		}
	}
}

kustomize: "kyverno": #KustomizeHelm & {
	namespace: "kyverno"

	helm: {
		release: "kyverno"
		name:    "kyverno"
		version: "2.7.1"
		repo:    "https://kyverno.github.io/kyverno"
		values: {
			replicaCount: 1
		}
	}

	resource: "namespace-kyverno": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "kyverno"
		}
	}
}

kustomize: "keda": #KustomizeHelm & {
	namespace: "keda"

	helm: {
		release: "keda"
		name:    "keda"
		version: "2.8.2"
		repo:    "https://kedacore.github.io/charts"
	}

	resource: "namespace-keda": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "keda"
		}
	}
}

kustomize: "external-dns": #KustomizeHelm & {
	namespace: "external-dns"

	helm: {
		release: "external-dns"
		name:    "external-dns"
		version: "6.7.2"
		repo:    "https://charts.bitnami.com/bitnami"
		values: {
			sources: [
				"service",
				"ingress",
			]
			provider: "cloudflare"
		}
	}

	resource: "namespace-external-dns": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "external-dns"
		}
	}
}

kustomize: "vault": #KustomizeHelm & {
	namespace: "vault"

	helm: {
		release: "vault"
		name:    "vault"
		version: "0.20.1"
		repo:    "https://helm.releases.hashicorp.com"
		values: {
			server: {
				dataStorage: size: "1Gi"
				standalone: config: """
					disable_mlock = true
					ui = true

					listener "tcp" {
					  tls_disable = 1
					  address = "[::]:8200"
					  cluster_address = "[::]:8201"
					}

					storage "file" {
					  path = "/vault/data"
					}

					seal "transit" {
					  address = "http://vault.default.svc:8200"
					  disable_renewal = "false"
					  key_name = "autounseal-remo"
					  mount_path = "transit/"
					  tls_skip_verify = "true"
					}

					"""
			}
		}
	}

	resource: "namespace-vault": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "vault"
		}
	}

	psm: "statefulset-vault-set-vault-token": {
		apiVersion: "apps/v1"
		kind:       "StatefulSet"
		metadata: {
			name:      "vault"
			namespace: "vault"
		}
		spec: template: spec: containers: [
			{name: "vault"
				env: [
					{
						name: "VAULT_TOKEN"
						valueFrom: secretKeyRef: {
							name: "vault-unseal"
							key:  "VAULT_TOKEN"
						}
					},
				]
			},
		]
	}
}

kustomize: "kourier": #Kustomize & {
	resource: "kourier": {
		url: "https://github.com/knative-sandbox/net-kourier/releases/download/knative-v1.7.0/kourier.yaml"
	}

	psm: "service-kourier-set-cluster-ip": {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "kourier"
			namespace: "kourier-system"
		}
		spec: type: "ClusterIP"
	}
}

kustomize: "dev": #Kustomize & {
	namespace: "default"

	resource: "statefulset-dev": apps.#StatefulSet & {
		apiVersion: "apps/v1"
		kind:       "StatefulSet"
		metadata: {
			name:      "dev"
			namespace: "default"
		}
		spec: {
			serviceName: "dev"
			replicas:    1
			selector: matchLabels: app: "dev"
			template: {
				metadata: labels: app: "dev"
				spec: {
					volumes: [{
						name: "work"
						emptyDir: {}
					}]
					containers: [{
						name:            "code-server"
						image:           "169.254.32.1:5000/workspace"
						imagePullPolicy: "Always"
						command: [
							"/usr/bin/tini",
							"--",
						]
						args: [
							"bash",
							"-c",
							"exec ~/bin/e code-server --bind-addr 0.0.0.0:8888 --disable-telemetry",
						]
						tty: true
						env: [{
							name:  "PASSWORD"
							value: "admin"
						}]
						securityContext: privileged: true
						volumeMounts: [{
							mountPath: "/work"
							name:      "work"
						}]
					}]
				}
			}
		}
	}

	resource: "service-dev": core.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "dev"
			namespace: "default"
		}
		spec: {
			ports: [{
				port:       80
				protocol:   "TCP"
				targetPort: 8888
			}]
			selector: app: "dev"
			type: "ClusterIP"
		}
	}

	resource: "cluster-role-binding-admin": rbac.#ClusterRoleBinding & {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: name: "dev-admin"
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "cluster-admin"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "default"
			namespace: "default"
		}]
	}

	resource: "cluster-role-binding-delegator": rbac.#ClusterRoleBinding & {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: name: "dev-delegator"
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "system:auth-delegator"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "default"
			namespace: "default"
		}]
	}
}

kustomize: "external-secrets-operator": #KustomizeHelm & {
	namespace: "external-secrets"

	helm: {
		release: "external-secrets"
		name:    "external-secrets"
		version: "0.7.2"
		repo:    "https://charts.external-secrets.io"
		values: {
			webhook: create:        false
			certController: create: false
		}
	}

	resource: "namespace-external-secrets": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "external-secrets"
		}
	}

	resource: "cluster-role-binding-delegator": rbac.#ClusterRoleBinding & {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: name: "external-secrets-delegator"
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "system:auth-delegator"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "external-secrets"
			namespace: "external-secrets"
		}]
	}
}

kustomize: "pod-identity-webhook": #KustomizeHelm & {
	namespace: "default"

	helm: {
		release: "pod-identity-webhook"
		name:    "amazon-eks-pod-identity-webhook"
		version: "1.2.0"
		repo:    "https://jkroepke.github.io/helm-charts"
		values: {
			pki: certManager: certificate: duration:    "2160h0m0s"
			pki: certManager: certificate: renewBefore: "360h0m0s"
		}
	}
}

// helm template karpenter --include-crds --version v0.27.0 -f ../k/karpenter/values.yaml  oci://public.ecr.aws/karpenter/karpenter | tail -n +3 > ../k/karpenter/karpenter.yaml
kustomize: "karpenter": #Kustomize & {
	namespace: "karpenter"

	resource: "karpenter": {
		url: "karpenter.yaml"
	}

	resource: "namespace-karpenter": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "karpenter"
		}
	}

	resource: (#Transform & {
		transformer: #TransformKarpenterProvisioner

		inputs: {
			for _env_name, _env in env {
				if (_env & #VCluster) != _|_ {
					if len(_env.instance_types) > 0 {
						"\(_env_name)": {}
					}
				}
			}

			[N=string]: {
				label:          "provisioner-\(N)"
				instance_types: env[N].instance_types
			}
		}
	}).outputs
}

kustomize: "knative": #Kustomize & {
	resource: "knative-serving": {
		url: "https://github.com/knative/serving/releases/download/knative-v1.8.0/serving-core.yaml"
	}

	psm: "namespace-knative-serving": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "knative-serving"
		}
	}

	psm: "deployment-webhook": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "webhook"
			namespace: "knative-serving"
		}
	}

	psm: "deployment-domainmappingwebhook": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "domainmapping-webhook"
			namespace: "knative-serving"
		}
	}

	psm: "deployment-domain-mapping": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "domain-mapping"
			namespace: "knative-serving"
		}
	}

	psm: "deployment-controller": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "controller"
			namespace: "knative-serving"
		}
	}

	psm: "deployment-autoscaler": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "autoscaler"
			namespace: "knative-serving"
		}
	}

	psm: "deployment-activator": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "activator"
			namespace: "knative-serving"
		}
	}

	psm: "config-map-config-defaults": core.#ConfigMap & {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "config-defaults"
			namespace: "knative-serving"
		}
		data: {
			"revision-timeout-seconds":     "1800"
			"max-revision-timeout-seconds": "1800"
		}
	}

	psm: "config-map-config-domain": core.#ConfigMap & {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "config-domain"
			namespace: "knative-serving"
		}
		data: {}
	}

	psm: "config-map-config-features": core.#ConfigMap & {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "config-features"
			namespace: "knative-serving"
		}
		data: {
			"kubernetes.podspec-affinity":    "enabled"
			"kubernetes.podspec-tolerations": "enabled"
		}
	}

	psm: "config-map-config-network": core.#ConfigMap & {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "config-network"
			namespace: "knative-serving"
		}
		data: "ingress-class": "kong"
	}
}

kustomize: "cert-manager": #KustomizeHelm & {
	helm: {
		release:   "cert-manager"
		name:      "cert-manager"
		namespace: "cert-manager"
		version:   "1.11.0"
		repo:      "https://charts.jetstack.io"
	}

	resource: "namespace-cert-manager": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "cert-manager"
		}
	}

	resource: "cert-manager-crds": {
		url: "https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml"
	}
}

kustomize: "tfo": #Kustomize & {
	namespace: "tf-system"

	resource: "tfo": {
		url: "https://raw.githubusercontent.com/isaaguilar/terraform-operator/master/deploy/bundles/v0.9.0-beta3/v0.9.0-beta3.yaml"
	}
}

kustomize: "bonchon": #Kustomize & {
	for chicken in ["rocky", "rosie"] {
		resource: "pre-sync-hook-dry-brine-\(chicken)-chicken": batch.#Job & {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      "dry-brine-\(chicken)-chicken"
				namespace: "default"
				annotations: "argocd.argoproj.io/hook": "PreSync"
			}

			spec: backoffLimit: 0
			spec: template: spec: {
				serviceAccountName: "default"
				containers: [{
					name:  "meh"
					image: "defn/dev:kubectl"
					command: ["bash", "-c"]
					args: ["""
					test "completed" == "$(kubectl get tf "\(chicken)" -o json | jq -r '.status.phase')"
					"""]
				}]
				restartPolicy: "Never"
			}
		}
	}

	resource: "tfo-demo-bonchon": {
		apiVersion: "tf.isaaguilar.com/v1alpha2"
		kind:       "Terraform"

		metadata: {
			name:      "bonchon"
			namespace: "default"
		}

		spec: {
			terraformVersion: "1.0.0"
			terraformModule: source: "https://github.com/defn/app.git//tf/m/fried-chicken?ref=master"

			serviceAccount: "default"
			scmAuthMethods: []

			ignoreDelete:       true
			keepLatestPodsOnly: true

			outputsToOmit: ["0"]

			backend: """
				terraform {
					backend "kubernetes" {
						in_cluster_config = true
						secret_suffix     = "bonchon"
						namespace         = "default"
					}
				}
				"""
		}
	}
}

kustomize: "sysbox": #Kustomize & {
	resource: "sysbox": {
		url: "https://raw.githubusercontent.com/nestybox/sysbox/master/sysbox-k8s-manifests/sysbox-install.yaml"
	}

	psm: "daemonset-vault-set-vault-token": {
		apiVersion: "apps/v1"
		kind:       "DaemonSet"

		metadata: {
			name:      "sysbox-deploy-k8s"
			namespace: "kube-system"
		}

		spec: template: spec: tolerations: [{
			key:      "env"
			operator: "Exists"
		}]
	}
}
