{
  inputs = {
    dev.url = github:defn/pkg/dev-0.0.23?dir=dev;
    app.url = github:defn/app/0.0.4;
  };

  outputs = inputs: inputs.dev.main rec {
    inherit inputs;

    src = builtins.path { path = ./.; name = builtins.readFile ./SLUG; };

    handler = { pkgs, wrap, system, builders, commands, config }: rec {
      defaultPackage = inputs.app.kustomize { inherit src; inherit wrap; };
    };
  };
}
