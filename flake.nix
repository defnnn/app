{
  inputs = {
    pkg.url = github:defn/pkg/0.0.158;
    kustomize.url = github:defn/pkg/kustomize-5.0.0-7?dir=kustomize;
  };

  outputs = inputs:
    let
      kustomize = { src, wrap }: wrap.bashBuilder {
        inherit src;

        buildInputs = [
          inputs.kustomize
        ];

        installPhase = ''
          mkdir -p $out
          kustomize build --enable-helm local > $out/main.yaml
        '';
      };

      main = { src }:
        inputs.pkg.main rec {
          inherit src;

          defaultPackage = ctx: kustomize { inherit src; wrap = ctx.wrap; };
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
