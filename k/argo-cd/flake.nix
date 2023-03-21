{
  inputs.app.url = github:defn/app/0.0.18;
  outputs = inputs: inputs.app.kustomizeMain rec { src = ./.; };
}
