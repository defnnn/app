{
  inputs = {
    pkg.url = github:defn/pkg/0.0.170;
    argo-cd.url = github:defn/app/argo-cd-0.0.7?dir=k/argo-cd;
    argo-workflows.url = github:defn/app/argo-workflows-0.0.6?dir=k/argo-workflows;
  };

  outputs = inputs: inputs.pkg.main rec {
    src = ./.;

    defaultPackage = ctx: ctx.wrap.bashBuilder {
      inherit src;

      installPhase = ''
        mkdir -p $out
        cat \
            ${inputs.argo-cd.defaultPackage.${ctx.system}}/main.yaml \
            ${inputs.argo-workflows.defaultPackage.${ctx.system}}/main.yaml \
            > $out/main.yaml
      '';
    };
  };
}
