package c

import (
	"encoding/yaml"
)

// Each environment is hosted on a Kubernetes machine.
// The machine's name is set to the env key.
env: [NAME=string]: (#K3D | #VCluster) & {
	name: NAME
}

bootstrap: (#Transform & {
	transformer: #TransformEnvToBootstrapMachine

	inputs: {
		for _env_name, _env in env {
			"\(_env_name)": {
				name:      _env_name
				type:      _env.type
				bootstrap: _env.bootstrap
			}
		}
	}
}).outputs

kustomize: (#Transform & {
	transformer: #TransformEnvToAnyResource

	inputs: {
		for _env_name, _env in env {
			"\(_env_name)": {
				name:  _env_name
				type:  _env.type
				label: "\(type)-\(name)"
			}
		}
	}
}).outputs

kustomize: (#Transform & {
	transformer: #TransformEnvToSecretStore

	inputs: {
		for _env_name, _env in env {
			"\(_env_name)": {
				name:  _env_name
				type:  _env.type
				label: "\(type)-\(name)-secrets-store"
			}
		}
	}
}).outputs

#TransformEnvToAnyResource: {
	from: {
		#Input

		type: string
	}

	to: #KustomizeHelm & {
		_in: from

		helm: {
			release: "bootstrap"
			name:    "any-resource"
			version: "0.1.0"
			repo:    "https://kiwigrid.github.io"
			values: {
				anyResources: {
					for _app_name, _app in bootstrap[_in.name].apps {
						"\(_app_name)": yaml.Marshal(_app.application)
					}
				}
			}
		}
	}
}

#TransformEnvToSecretStore: {
	from: {
		#Input

		type: string
	}

	to: #Kustomize & {
		_in: from

		resource: "cluster-secret-store-dev": {
			apiVersion: "external-secrets.io/v1beta1"
			kind:       "ClusterSecretStore"
			metadata: name: "dev"
			spec: provider: vault: {
				server:  "http://100.103.25.109:8200"
				path:    "kv"
				version: "v2"
				auth: kubernetes: {
					mountPath: "\(_in.type)-\(_in.name)"
					role:      "external-secrets"
				}
			}
		}
	}
}

#TransformEnvToBootstrapMachine: {
	from: {
		#Input

		type: string
		bootstrap: [string]: int
	}

	to: #BootstrapMachine
}

#BootstrapMachine: ctx={
	_in: #TransformEnvToBootstrapMachine.from

	machine_name: string | *_in.name
	machine_type: string | *_in.type

	apps: [string]: #BootstrapApp
	apps: {
		for _app_name, _app_weight in _in.bootstrap {
			"\(_app_name)": #BootstrapApp & {
				machine_type: ctx.machine_type
				machine_name: ctx.machine_name
				app_name:     _app_name
				app_wave:     _app_weight
			}
		}
	}
}

#BootstrapApp: {
	machine_type: string
	machine_name: string
	app_name:     string
	app_wave:     int

	application: {
		apiVersion: "argoproj.io/v1alpha1"
		kind:       "Application"

		metadata: {
			namespace: "argocd"
			if app_name =~ "^\(machine_type)-\(machine_name)-" {
				name: "\(app_name)"
			}
			if app_name !~ "^\(machine_type)-\(machine_name)-" {
				name: "\(machine_type)-\(machine_name)-\(app_name)"
			}
			annotations: "argocd.argoproj.io/sync-wave": "\(app_wave)"
		}

		spec: {
			project: "default"

			destination: {
				name: "\(machine_type)-\(machine_name)"
			}

			source: {
				repoURL:        "https://github.com/defn/app"
				targetRevision: "master"
				path:           "k/\(app_name)"
			}

			syncPolicy: automated: {
				prune:    true
				selfHeal: true
			}

			ignoreDifferences: [{
				group: ""
				kind:  "Secret"
				jsonPointers: ["/data"]
				name:      "karpenter-cert"
				namespace: "karpenter"
			}]
		}
	}
}

// Machine
#Machine: {
	type: string
	name: string

	bootstrap: [string]: int
}

// K3D Machine
#TransformK3D: {
	from: {
		#Input
		bootstrap: [string]: number
	}

	to: #K3D
}

#K3D: {
	_in: #TransformK3D.from

	#Machine

	type:      "k3d"
	bootstrap: _in.bootstrap

	// ex: k3d-control
	env: metadata: name: "\(type)-\(_in.name)"
}

// VCluster Machine
#TransformVCluster: {
	from: {
		#Input
		bootstrap: [string]: number
		parent: #K3D
	}

	to: #VCluster
}

#VCluster: ctx={
	_in: #TransformVCluster.from

	#Machine

	type:      "vcluster"
	bootstrap: _in.bootstrap

	parent: #K3D
	parent: _in.parent

	// ex: k3d-control-vc1
	env: metadata: name: "\(parent.env.metadata.name)-\(ctx.name)"
}
