{
  inputs.app.url = github:defn/app/0.0.19;
  outputs = inputs: inputs.app.kustomizeMain rec { src = ./.; };
}
