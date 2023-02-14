{
  inputs.app.url = github:defn/app/0.0.5;
  outputs = inputs: inputs.app.main rec { src = ./.; };
}
