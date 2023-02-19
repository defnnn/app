{
  inputs.app.url = github:defn/app/0.0.14;
  outputs = inputs: inputs.app.main rec { src = ./.; };
}
