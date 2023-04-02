{
  inputs.app.url = github:defn/app/0.0.20;
  inputs.infra.url = github:defn/app/infra-0.0.15?dir=cmd/infra;
  outputs = inputs: inputs.app.cdktfMain rec {
    src = ./.;
    infra = inputs.infra;
    infra_cli = "infra";
  };
}
