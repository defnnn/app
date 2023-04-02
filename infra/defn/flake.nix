{
  inputs.lib.url = github:defn/lib/0.0.75;
  inputs.infra.url = github:defn/app/infra-0.0.15?dir=cmd/infra;
  outputs = inputs: inputs.lib.cdktfMain rec {
    src = ./.;
    infra = inputs.infra;
    infra_cli = "infra";
  };
}
