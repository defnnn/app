{
  inputs.app.url = github:defn/app/0.0.22;
  inputs.infra.url = github:defn/app/infra-0.0.16?dir=cmd/infra;
  outputs = inputs: inputs.app.cdktfMain rec {
    src = ./.;
    infra = inputs.infra;
    infra_cli = "infra";
  };
}
