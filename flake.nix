{
  inputs = {
    gomod2nix.url = github:defn/gomod2nix/1.5.0-9;
    godev.url = github:defn/pkg/godev-0.0.59?dir=godev;
    nodedev.url = github:defn/pkg/nodedev-0.0.38?dir=nodedev;
    terraform.url = github:defn/pkg/terraform-1.4.4-34?dir=terraform;
    kustomize.url = github:defn/pkg/kustomize-5.0.1-34?dir=kustomize;
    helm.url = github:defn/pkg/helm-3.11.2-37?dir=helm;
    latest.url = github:NixOS/nixpkgs?rev=64c27498901f104a11df646278c4e5c9f4d642db;
  };

  outputs = inputs:
    let
      pkg = inputs.godev.inputs.pkg;

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
        pkg.main rec {
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
                gomod2nixOverlay = inputs.gomod2nix.overlays.default;

                goPkgs = import inputs.latest {
                  system = ctx.system;
                  overlays = [ gomod2nixOverlay ];
                };

                goEnv = goPkgs.mkGoEnv {
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
        pkg.main rec {
          src = caller.src;

          defaultPackage = ctx:
            let
              gomod2nixOverlay = inputs.gomod2nix.overlays.default;

              goPkgs = import inputs.latest {
                system = ctx.system;
                overlays = [ gomod2nixOverlay ];
              };

              goCmd = goPkgs.buildGoApplication rec {
                inherit src;
                pwd = src;
                pname = ctx.config.slug;
                version = ctx.config.version;
              };
            in
            go (ctx // { inherit src; inherit goCmd; });

          devShell = ctx:
            let
              gomod2nixOverlay = inputs.gomod2nix.overlays.default;

              goPkgs = import inputs.latest {
                system = ctx.system;
                overlays = [ gomod2nixOverlay ];
              };

              goEnv = goPkgs.mkGoEnv {
                pwd = src;
              };
            in
            ctx.wrap.devShell {
              devInputs = ctx.commands ++ [
                goEnv
                goPkgs.gomod2nix
                (goShell ctx)
                inputs.godev.defaultPackage.${ctx.system}
                inputs.nodedev.defaultPackage.${ctx.system}
                inputs.terraform.defaultPackage.${ctx.system}
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
        pkg.main rec {
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
      inherit pkg;
      inherit kustomizeMain;
      inherit goMain;
      inherit cdktfMain;
    } // pkg.main rec {
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
