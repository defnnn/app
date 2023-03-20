{
  inputs = {
    pkg.url = github:defn/pkg/0.0.170;
    kustomize.url = github:defn/pkg/kustomize-5.0.1-0?dir=kustomize;
    helm.url = github:defn/pkg/helm-3.11.2-3?dir=helm;
  };

  outputs = inputs:
    let
      kustomizeMain = caller:
        let
          kustomize = ctx: ctx.wrap.bashBuilder {
            src = caller.src;

            buildInputs = [
              inputs.kustomize.defaultPackage.${ctx.system}
              inputs.helm.defaultPackage.${ctx.system}
            ];

            installPhase = ''
              mkdir -p $out
              kustomize build --enable-helm local > $out/main.yaml
            '';
          };
        in
        inputs.pkg.main rec {
          src = caller.src;

          defaultPackage = ctx: kustomize (ctx // { inherit src; });
        };
    in
    {
      inherit kustomizeMain;
    } // inputs.pkg.main rec {
      src = ./.;
      defaultPackage = ctx: ctx.wrap.nullBuilder { };
    };
}
