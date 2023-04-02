{
  inputs.lib.url = github:defn/lib/0.0.74;
  outputs = inputs: inputs.lib.goMain rec {
    src = ./.;

    extendBuild = ctx: {
      propagatedBuildInputs = [
        inputs.lib.inputs.nodedev.defaultPackage.${ctx.system}
      ];
    };
  };
}
