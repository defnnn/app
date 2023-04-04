{
  inputs.app.url = github:defn/app/0.0.28;
  outputs = inputs: inputs.app.goMain rec {
    src = ./.;

    extendBuild = ctx: {
      propagatedBuildInputs = [
        inputs.app.inputs.nodedev.defaultPackage.${ctx.system}
      ];
    };
  };
}
