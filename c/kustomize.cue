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
		url: "https://raw.githubusercontent.com/argoproj/argo-cd/v2.5.0/manifests/install.yaml"
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
		version: "2.5.5"
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

kustomize: {
	for a in ["k3d-global"] {
		"\(a)-kuma-global": #KustomizeHelm & {
			namespace: "kuma"

			helm: {
				release: "kuma"
				name:    "kuma"
				version: "1.8.1"
				repo:    "https://kumahq.github.io/charts"
				values: {
					controlPlane: {
						mode: "global"
						service: type: "LoadBalancer"
						tls: {
							general: {
								secretName: "generic-tls-cert"
								caBundle:   "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURiekNDQWxlZ0F3SUJBZ0lSQUt1M3pPcFVGUVVtRjJtZFhrdkRNZmN3RFFZSktvWklodmNOQVFFTEJRQXcKSWpFZ01CNEdBMVVFQXhNWGEzVnRZUzFqYjI1MGNtOXNMWEJzWVc1bExtdDFiV0V3SGhjTk1qSXhNREV3TURVMApOakl5V2hjTk16SXhNREEzTURVME5qSXlXakFpTVNBd0hnWURWUVFERXhkcmRXMWhMV052Ym5SeWIyd3RjR3hoCmJtVXVhM1Z0WVRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTnhHK0FsZXM2QVMKc2Y4ZXM4VWx4Q1lrV1kxeURpUUpwT3VQd1BOWERiamJmcXZCQVg1YkNIeGo0by9RVkdRTm04RlBleW9KT0p1NgppWmFYa2xCbG1RVGJuTTl2TVZlZE5lbjlteUZhM0YwV0xMUlFjYmF0bTRSNUY5c0lZQzRiY2J3bXMxSTROQUlMCnhxU1puR096THZzMDRGaThXK2FtZS9pRkt6emdlZW5uV2VsTTF4aSthM0dzU0NkRlEvaEt1UmNZMW5OZTFhNmQKY1hWaHRDSWF1S2dWWWRybVlDeUNoczBXbFlrZWxVQ1czcVJrV1dkMDhTbVd2TFB3dDdVUXlNb1JVc2kxTkdYZQpFdk5Sd1BWS29ZS0UzZ1p3eDA3TjcvaUdvVjFSc3dqclNRTjFyTnV5WTFmTFVYNXhCS2cwTlAwMnMrN3hteCtaCnd6d0d5K1hEZDhFQ0F3RUFBYU9CbnpDQm5EQU9CZ05WSFE4QkFmOEVCQU1DQXFRd0V3WURWUjBsQkF3d0NnWUkKS3dZQkJRVUhBd0V3RHdZRFZSMFRBUUgvQkFVd0F3RUIvekFkQmdOVkhRNEVGZ1FVYlBhV1lCNm5NSkl6bStregpuWDdPTG9zUXlXOHdSUVlEVlIwUkJENHdQSUlYYTNWdFlTMWpiMjUwY205c0xYQnNZVzVsTG10MWJXR0NHMnQxCmJXRXRZMjl1ZEhKdmJDMXdiR0Z1WlM1cmRXMWhMbk4yWTRjRVpFQnVFREFOQmdrcWhraUc5dzBCQVFzRkFBT0MKQVFFQVFxK2pzSXRHV09qcWZFRWI5TzZndnNJakNPWWVIVWsyUi9mUkZhZGFlVFRUZU5xODc2cU10T0kvSmZOcgpLUmZvN25idkdNTGMyZVJQUmNsZUlLcjZUY1VIU3dXdG5YNGVWR2o4VGtORVV0NXhyeUlRMTc4NFRoemU3eUtKCm12dWtoL0hyTG5aR2dDWWJsOEFUSUcwek94cXlyRDQvR05CK0p4QVZDemtiYldYU3VtZk81bnBLUWdtUllkS08KV29iZ0QzMDBOdVB1QmRJS3Jrc1A5N3lWdE90ck1weGg0MENPdi9jMUZHRHB3RXN2MFJhS2doQVF5emlSc2xlUgpJY0JkOGgwRXpzaU1nZVZTdXdURHZTNG1YWWxBcVdhcjNEek9NQkdXaG9RUFY2bWM1Szh5QnVlM3FZRE5jdklwCjdGekEySjVQdkV2SVlwVWZWRUlUT2J1SmR3PT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
							}
							kdsGlobalServer: secretName: "kds-server-tls"
						}
					}
				}
			}

			resource: "external-secret-kds-server-tls": (#VaultSecret & {
				secret_name:      "kds-server-tls"
				secret_namespace: "kuma"
				secret_key:       "/dev/\(a)/kuma-global"
				secret_type:      "kubernetes.io/tls"
				secret_template: "tls.crt": '{{ index . "cert" }}'
				secret_template: "tls.key": '{{ index . "key" }}'
				secret_refresh: "60s"
				secret_store:   "dev"
			}).out

			resource: "external-secret-generic-tls-cert": (#VaultSecret & {
				secret_name:      "generic-tls-cert"
				secret_namespace: "kuma"
				secret_key:       "/dev/\(a)/kuma-global"
				secret_template: "tls.crt": '{{ index . "tls.crt" }}'
				secret_template: "tls.key": '{{ index . "tls.key" }}'
				secret_template: "ca.crt":  '{{ index . "ca.crt" }}'
				secret_refresh: "60s"
				secret_store:   "dev"
			}).out

			resource: "namespace-kuma": core.#Namespace & {
				apiVersion: "v1"
				kind:       "Namespace"
				metadata: {
					name: "kuma"
				}
			}
		}
	}
}

kustomize: {
	for a in ["k3d-control", "k3d-smiley"] {
		"\(a)-kuma-zone": #KustomizeHelm & {
			namespace: "kuma"

			helm: {
				release: "kuma"
				name:    "kuma"
				version: "1.8.1"
				repo:    "https://kumahq.github.io/charts"
				values: {
					controlPlane: {
						mode:             "zone"
						zone:             a
						kdsGlobalAddress: "grpcs://100.64.110.16:5685"
						tls: {
							general: {
								secretName: "kuma-tls-cert"
								caBundle:   "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURhRENDQWxDZ0F3SUJBZ0lRVmFrY1RoQ2lEb3oyYVdVRXhDVk1jVEFOQmdrcWhraUc5dzBCQVFzRkFEQWkKTVNBd0hnWURWUVFERXhkcmRXMWhMV052Ym5SeWIyd3RjR3hoYm1VdWEzVnRZVEFlRncweU1qRXdNVE13TXpNMApNVEZhRncwek1qRXdNVEF3TXpNME1URmFNQ0l4SURBZUJnTlZCQU1URjJ0MWJXRXRZMjl1ZEhKdmJDMXdiR0Z1ClpTNXJkVzFoTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFxeEozN093L2NRRlYKQldQcTNOTUd6OGNvdjFlT0pOcVo1K0hudXZlSVdlQ0NjOWNQR2FIMzlBRkRNUVA3Q0FiT3drVzAzemZ4YnVnUQprSnF3RXpQd2FBK1FHdkdPK09FRVNENUJyeSthNEFyV0ZoZVFhOTZCdUhoN0pyUHVoczFJRnVwakFxc0M3dEtOCkQwczllNnA1Ry9GeTFmcXJ2RVlWWUxqaTIyTGp4d0tnb0ZHWm1yWXZ1MFcvK3FJNUM1OGF4R1Iwa21OUUI5VE0KTGU4K3V5ZmNoVnI2a2Iyb0ZHWUpneFNORjh6ZWxVWmJRbmlCWUFsU1dXWEVMZ21YaHVhNzl6ZkhkaVJQbWVqVgpoNktheWJWR3RrSEFBREdXY0tSdkpOMlhORDBqaTZmbDZQUGVJRjNianZ2SXFkTWhvckN2NjV1TUt4Q0lUSHp0Cjg1OXJ6R0JMOVFJREFRQUJvNEdaTUlHV01BNEdBMVVkRHdFQi93UUVBd0lDcERBVEJnTlZIU1VFRERBS0JnZ3IKQmdFRkJRY0RBVEFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQjBHQTFVZERnUVdCQlRvZVc0VTFDcVRSbGtGTHNDdApKK2ZrQXdiRUZqQS9CZ05WSFJFRU9EQTJnaGRyZFcxaExXTnZiblJ5YjJ3dGNHeGhibVV1YTNWdFlZSWJhM1Z0CllTMWpiMjUwY205c0xYQnNZVzVsTG10MWJXRXVjM1pqTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFBLzl3YWEKWVpucTJQaTBmUk1Ma00velNHaDMwcys0OWZITW5JUWtGRVRiNisvZmNCazB6S2J6U3NGRy9obFB4YWdzRXdRTQpCcFZtUnNMV21YUVBzUUR3bUx4TnJDQ1g4NXFsLzJYdVJSdys2RmN3MzRhK252Y0VXWVpQUUJhUU83UGtSOVFCCmpPeGRqUGp3cVVSWWowTURVSVVkMVB6MzJJUTE5b3d6MHJieGtpRWxrNk1EOGlCMXFva3pzb0E3di9WR1Y4RGQKQU41NVNHM3hTbHE1bnFPU2N3NENMa2lGUmt2MnZDbUZnQ2phME05clJIMlR4U2lkNHRIOE96QkZlT09OL0hCRgpSb2ZTZmdvV21mbDUreDJ2K2Fpd2drK0d2WVY3ZHVBYkVkaFVOMFNRZDNkc282ZktaMUdIQ2tYbmhUMVFreDZoCmhRazlkcnFJczc1Umw3VUIKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
							}
							kdsZoneClient: secretName: "kds-ca-certs"
						}
					}
					ingress: enabled: true
					egress: enabled:  true
				}
			}

			resource: "namespace-kuma": core.#Namespace & {
				apiVersion: "v1"
				kind:       "Namespace"
				metadata: {
					name: "kuma"
				}
			}

			resource: "external-secret-kds-ca-certs": (#VaultSecret & {
				secret_name:      "kds-ca-certs"
				secret_namespace: "kuma"
				secret_key:       "/dev/k3d-global/kuma-global"
				secret_template: "ca.crt": '{{ index . "ca.crt" }}'
				secret_refresh: "60s"
				secret_store:   "dev"
			}).out

			resource: "external-secret-kuma-tls-cert": (#VaultSecret & {
				secret_name:      "kuma-tls-cert"
				secret_namespace: "kuma"
				secret_key:       "/dev/\(a)/kuma-zone"
				secret_template: "tls.crt": '{{ index . "tls.crt" }}'
				secret_template: "tls.key": '{{ index . "tls.key" }}'
				secret_template: "ca.crt":  '{{ index . "ca.crt" }}'
				secret_refresh: "60s"
				secret_store:   "dev"
			}).out
		}
	}
}

kustomize: "mesh": #Kustomize & {
	resource: "mesh-default": {
		apiVersion: "kuma.io/v1alpha1"
		kind:       "Mesh"
		metadata: name: "default"
		spec: mtls: {
			enabledBackend: "ca-default-1"
			backends: [{
				name: "ca-default-1"
				type: "builtin"
			}]
		}
	}

	resource: "mesh-dev": {
		apiVersion: "kuma.io/v1alpha1"
		kind:       "Mesh"
		metadata: name: "dev"
		spec: mtls: {
			enabledBackend: "ca-dev-1"
			backends: [{
				name: "ca-dev-1"
				type: "builtin"
			}]
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

kustomize: "kong": #Kustomize & {
	namespace: "kong"

	resource: "kong": {
		url: "https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.7.0/deploy/single/all-in-one-dbless.yaml"
	}

	psm: "namespace-kong": {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name:      "kong"
			namespace: "kong"
			labels: "kuma.io/sidecar-injection": "enabled"
			labels: "kuma.io/mesh":              "dev"
		}
	}

	psm: "deployment-ingress-kong": {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "ingress-kong"
			namespace: "kong"
			annotations: "kuma.io/gateway": "enabled"
		}
	}

	psm: "service-kong-proxy-set-cluster-ip": {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "kong-proxy"
			namespace: "kong"
		}
		spec: type: "ClusterIP"
	}
}

kustomize: "arc": #KustomizeHelm & {
	namespace: "arc"

	helm: {
		release: "arc"
		name:    "actions-runner-controller"
		version: "0.21.0"
		repo:    "https://actions-runner-controller.github.io/actions-runner-controller"
	}

	resource: "runner-deployment-defn": {
		apiVersion: "actions.summerwind.dev/v1alpha1"
		kind:       "RunnerDeployment"
		metadata: name: "defn"
		spec: template: spec: {
			organization:                 "defn"
			dockerdWithinRunnerContainer: true
			image:                        "summerwind/actions-runner-dind"
		}
	}

	resource: "namespace-arc": core.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "arc"
		}
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
		version: "0.6.0"
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
		version: "1.0.3"
		repo:    "https://jkroepke.github.io/helm-charts"
		values: {
			pki: certManager: certificate: duration:    "2160h0m0s"
			pki: certManager: certificate: renewBefore: "360h0m0s"
		}
	}
}

// helm template karpenter --include-crds --version v0.18.1 -f ../k/karpenter/values.yaml  oci://public.ecr.aws/karpenter/karpenter | tail -n +3 > ../k/karpenter/karpenter.yaml
kustomize: "karpenter": #Kustomize & {
	namespace: "karpenter"

	resource: "karpenter": {
		url: "karpenter.yaml"
	}

	psm: "deployment-karpenter-irsa": apps.#Deployment & {
		apiVersion: "v1"
		kind:       "ServiceAccount"
		metadata: {
			name: "karpenter"
			annotations: {
				"eks.amazonaws.com/role-arn":               "arn:aws:iam::319951235442:role/karpenter"
				"eks.amazonaws.com/audience":               "sts.amazonaws.com"
				"eks.amazonaws.com/sts-regional-endpoints": "true"
				"eks.amazonaws.com/token-expiration":       "86400"
			}
		}
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
			labels: "kuma.io/sidecar-injection": "enabled"
			labels: "kuma.io/mesh":              "dev"
		}
	}

	psm: "deployment-webhook": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "webhook"
			namespace: "knative-serving"
		}

		spec: template: metadata: annotations: "traffic.kuma.io/exclude-inbound-ports": "8443"

		spec: template: metadata: annotations: "kuma.io/virtual-probes": "disabled"
	}

	psm: "deployment-domainmappingwebhook": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "domainmapping-webhook"
			namespace: "knative-serving"
		}

		spec: template: metadata: annotations: "traffic.kuma.io/exclude-inbound-ports": "8443"

		spec: template: metadata: annotations: "kuma.io/virtual-probes": "disabled"
	}

	psm: "deployment-domain-mapping": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "domain-mapping"
			namespace: "knative-serving"
		}

		spec: template: metadata: annotations: "kuma.io/virtual-probes": "disabled"
	}

	psm: "deployment-controller": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "controller"
			namespace: "knative-serving"
		}

		spec: template: metadata: annotations: "kuma.io/virtual-probes": "disabled"
	}

	psm: "deployment-autoscaler": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "autoscaler"
			namespace: "knative-serving"
		}

		spec: template: metadata: annotations: "traffic.kuma.io/exclude-inbound-ports": "8080"

		spec: template: metadata: annotations: "kuma.io/virtual-probes": "disabled"
	}

	psm: "deployment-activator": apps.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "activator"
			namespace: "knative-serving"
		}

		spec: template: metadata: annotations: "traffic.kuma.io/exclude-inbound-ports":  "8012"
		spec: template: metadata: annotations: "traffic.kuma.io/exclude-outbound-ports": "8080"

		spec: template: metadata: annotations: "kuma.io/virtual-probes": "disabled"
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
		version:   "1.10.0"
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
		url: "https://raw.githubusercontent.com/isaaguilar/terraform-operator/master/deploy/bundles/v0.9.0-alpha1/v0.9.0-alpha1.yaml"
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
