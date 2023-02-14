{
  inputs = {
    dev.url = github:defn/pkg/dev-0.0.23?dir=dev;
    kubernetes.url = github:defn/pkg/kubernetes-0.0.6?dir=kubernetes;
  };

  outputs = inputs:
    let
      kustomize = { src, wrap }: wrap.bashBuilder {
        buildInputs = wrap.flakeInputs;

        inherit src;

        installPhase = ''
          mkdir -p $out
          kustomize build --enable-helm local > $out/main.yaml
        '';
      };
    in
    { inherit kustomize; } // inputs.dev.main rec {
      inherit inputs;

      src = builtins.path { path = ./.; name = builtins.readFile ./SLUG; };

      handler = { pkgs, wrap, system, builders, commands, config }: rec {
        defaultPackage = wrap.nullBuilder {
          propagatedBuildInputs = wrap.flakeInputs;
        };
      };
    };
}
