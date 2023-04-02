{
  inputs = {
    pkg.url = github:defn/pkg/0.0.172;
    terraform.url = github:defn/pkg/terraform-1.4.0-2?dir=terraform;
    godev.url = github:defn/pkg/godev-0.0.18?dir=godev;
    kustomize.url = github:defn/pkg/kustomize-5.0.1-0?dir=kustomize;
    helm.url = github:defn/pkg/helm-3.11.2-3?dir=helm;
    nodedev.url = github:defn/pkg/nodedev-0.0.4?dir=nodedev;
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

      goMain = caller:
        let
          defaultCaller = {
            extendBuild = ctx: { };
            extendShell = ctx: { };
            generateCompletion = "";
          } // caller;

          goShell = ctx: ctx.wrap.nullBuilder ({ } // (defaultCaller.extendShell ctx));

          go = ctx:
            ctx.wrap.bashBuilder (
              let
                goEnv = ctx.pkgs.mkGoEnv {
                  pwd = caller.src;
                };
              in
              {
                src = caller.src;

                buildInputs = [
                  goEnv
                  inputs.godev.defaultPackage.${ctx.system}
                ];

                installPhase = ''
                  mkdir -p $out/bin
                  ls -ltrhd ${ctx.goCmd}/bin/*
                  cp ${ctx.goCmd}/bin/${ctx.config.cli} $out/bin/
                  if [[ -n "${defaultCaller.generateCompletion}" ]]; then
                    mkdir -p $out/share/bash-completion/completions
                    $out/bin/${ctx.config.slug} completion bash > $out/share/bash-completion/completions/_${ctx.config.slug}
                  fi
                '';
              } // (defaultCaller.extendBuild ctx)
            );
        in
        inputs.pkg.main rec {
          src = caller.src;

          defaultPackage = ctx:
            let
              goCmd = ctx.pkgs.buildGoApplication rec {
                inherit src;
                pwd = src;
                pname = ctx.config.slug;
                version = ctx.config.version;
              };
            in
            go (ctx // { inherit src; inherit goCmd; });

          devShell = ctx:
            let
              goEnv = ctx.pkgs.mkGoEnv {
                pwd = src;
              };
            in
            ctx.wrap.devShell {
              devInputs = ctx.commands ++ [
                goEnv
                ctx.pkgs.gomod2nix
                inputs.godev.defaultPackage.${ctx.system}
                inputs.nodedev.defaultPackage.${ctx.system}
                inputs.terraform.defaultPackage.${ctx.system}
                (goShell ctx)
              ];
            };

          scripts = { system }: {
            update = ''
              go get -u ./...
              go mod tidy
              gomod2nix
            '';
          };
        };

      cdktfMain = caller:
        let
          defaultCaller = {
            extendBuild = ctx: { };
            extendShell = ctx: { };
          } // caller;

          cdktfShell = ctx: ctx.wrap.nullBuilder ({ } // (defaultCaller.extendShell ctx));

          cdktf = ctx: ctx.wrap.bashBuilder
            ({
              src = caller.src;

              buildInputs = [
                inputs.nodedev.defaultPackage.${ctx.system}
                inputs.terraform.defaultPackage.${ctx.system}
              ];

              installPhase = ''
                echo 1
                mkdir -p $out
                ${caller.infra.defaultPackage.${ctx.system}}/bin/${caller.infra_cli}
                cp -a cdktf.out/. $out/.
              '';
            }) // (defaultCaller.extendBuild ctx);
        in
        inputs.pkg.main rec {
          src = caller.src;

          defaultPackage = ctx: cdktf (ctx // { inherit src; });

          devShell = ctx: ctx.wrap.devShell {
            devInputs = ctx.commands ++ [
              inputs.nodedev.defaultPackage.${ctx.system}
              inputs.terraform.defaultPackage.${ctx.system}
              caller.infra.defaultPackage.${ctx.system}
              (cdktfShell ctx)
            ];
          };
        };
    in
    {
      inherit kustomizeMain;
      inherit goMain;
      inherit cdktfMain;
    } // inputs.pkg.main rec {
      src = ./.;
      defaultPackage = ctx: ctx.wrap.nullBuilder {
        propagatedBuildInputs = with ctx.pkgs; [
          bashInteractive
          inputs.godev.defaultPackage.${ctx.system}
          inputs.nodedev.defaultPackage.${ctx.system}
        ];
      };

      packages = ctx: rec {
        devShell = ctx: ctx.wrap.devShell {
          devInputs = [
            (defaultPackage ctx)
          ];
        };
      };
    };
}
