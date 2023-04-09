{
  inputs.infra.url = github:defn/app/infra-0.0.20?dir=cmd/infra;
  outputs = inputs: inputs.infra.inputs.app.cdktfMain rec {
    src = ./.;
    infra = inputs.infra;
    infra_cli = "infra";
  };
}
