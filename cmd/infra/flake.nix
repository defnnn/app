{
  inputs.app.url = github:defn/app/0.0.20;
  outputs = inputs: inputs.app.goMain rec {
    src = ./.;

    extendBuild = ctx: {
      propagatedBuildInputs = [
        inputs.lib.inputs.nodedev.defaultPackage.${ctx.system}
      ];
    };
  };
}
