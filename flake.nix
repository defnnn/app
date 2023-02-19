{
  inputs = {
    pkg.url = github:defn/pkg/0.0.158;
    kubernetes.url = github:defn/pkg/kubernetes-0.0.7?dir=kubernetes;
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

      main = { src }:
        let
          s = src;
        in
        inputs.dev.main rec {
          inherit inputs;

          src = builtins.path { path = s; name = (builtins.fromJSON (builtins.readFile "${s}/flake.json")).slug; };

          handler = { pkgs, wrap, system, builders, commands, config }: rec {
            defaultPackage = kustomize { inherit src; inherit wrap; };
          };
        };
    in
    {
      inherit kustomize;
      inherit main;
    } // inputs.pkg.main rec {
      src = ./.;

      defaultPackage = ctx: ctx.wrap.nullBuilder {
        propagatedBuildInputs = ctx.wrap.flakeInputs;
      };
    };
}
