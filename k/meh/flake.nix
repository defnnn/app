{
  inputs = {
    dev.url = github:defn/pkg/dev-0.0.23?dir=dev;
    argo-cd.url = github:defn/app/argo-cd-0.0.1?dir=k/argo-cd;
    argo-workflows.url = github:defn/app/argo-workflows-0.0.1?dir=k/argo-workflows;
  };

  outputs = inputs: inputs.dev.main rec {
    inherit inputs;

    src = builtins.path { path = ./.; name = builtins.readFile ./SLUG; };

    handler = { pkgs, wrap, system, builders, commands, config }: rec {
      defaultPackage = wrap.bashBuilder
        {
          inherit src;

          installPhase = ''
            mkdir -p $out
            cat \
               ${inputs.argo-cd.defaultPackage.${system}}/main.yaml \
               ${inputs.argo-workflows.defaultPackage.${system}}/main.yaml \
               > $out/main.yam
          '';
        };
        };
    };
  }
