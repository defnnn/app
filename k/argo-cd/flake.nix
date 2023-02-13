{
  inputs = {
    dev.url = github:defn/pkg/dev-0.0.22?dir=dev;
    kubernetes.url = github:defn/pkg/kubernetes-0.0.6?dir=kubernetes;
  };

  outputs = inputs: inputs.dev.main rec {
    inherit inputs;

    src = builtins.path { path = ./.; name = builtins.readFile ./SLUG; };

    config = rec {
      slug = builtins.readFile ./SLUG;
      version = builtins.readFile ./VERSION;
    };

    handler = { pkgs, wrap, system, builders }: rec {
      defaultPackage = wrap.bashBuilder { 
        propagatedBuildInputs = wrap.flakeInputs;

        inherit src;

        installPhase = ''
          mkdir -p $out
          kustomize build --enable-helm local > $out/main.yaml
        '';
      };
    };
  };
}
