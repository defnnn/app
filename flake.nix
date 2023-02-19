{
  inputs = {
    pkg.url = github:defn/pkg/0.0.158;
    kustomize.url = github:defn/pkg/kustomize-5.0.0-7?dir=kustomize;
  };

  outputs = inputs:
    let
      kustomize = ctx: ctx.wrap.bashBuilder {
        src = ctx.src;

        buildInputs = [
          inputs.kustomize.defaultPackage.${ctx.system}
        ];

        installPhase = ''
          mkdir -p $out
          kustomize build --enable-helm local > $out/main.yaml
        '';
      };

      main = caller:
        inputs.pkg.main rec {
          src = caller.src;

          defaultPackage = ctx: kustomize ctx;
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
