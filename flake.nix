{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      mangbands' = pkgs: let
        default = pkgs.callPackage ./mangband.nix { };
        tf = [
          true
          false
        ];
        combs = pkgs.lib.attrsets.cartesianProductOfSets {
          enableGCU  = tf;
          enableX11  = tf;
          enableSDL  = tf;
          enableSDL2 = tf;
        };
        o' = pkgs.lib.strings.optionalString;
      in pkgs.lib.foldr (x: y: x // y) {} (map ({ enableGCU, enableX11, enableSDL, enableSDL2 }@args: let
        vals = [enableGCU enableX11 enableSDL enableSDL2];
        all = pkgs.lib.lists.all (x: x) vals;
        none = pkgs.lib.lists.all (x: !x) vals;
        name = if all then "mangband" else "mangband${o' enableGCU "-GCU"}${o' enableX11 "-X11"}${o' enableSDL "-SDL"}${o' enableSDL2 "-SDL2"}";
      in pkgs.lib.attrsets.optionalAttrs (!none) {
        "${name}" = default.override args;
      }) combs);
      # Static has some issues because of some problems with mangband
      # adding AC_PROG_AR && removing AC_FUNC_MALLOC & AC_FUNC_REALLOC
      # help however there is still a rediefinition conflict
      mangbands = mangbands' pkgs;

      installScript = m: pkgs.writeScriptBin "install-mangband.sh" ''
        #!${pkgs.bash}/bin/bash

        mkdir lib
        cp -r ${m}/share/mangband/* ./lib/
        chmod -R +rw ./
        cp -r ${m}/var/mangband/* ./lib/
        chmod -R +rw ./
        cp -r ${m}/etc/* ./
        chmod -R +rw ./
      '';

      startupScript = pkgs.writeScriptBin "entrypoint.sh" ''
        #!${pkgs.bash}/bin/bash

        cd /home/container
        mangband
      '';

      container = pkgs.dockerTools.buildLayeredImage {
        name = "mangband";
        tag = "latest";
        contents = [
          (pkgs.fakeNss.override {
            extraPasswdLines = ["container:x:9001:9001:new user:/home/container:/bin/bash"];
          })
          (pkgs.buildEnv {
            name = "image-root";
            paths = [
              mangbands.mangband-GCU
              startupScript
              (installScript mangbands.mangband-GCU)
            ];
            pathsToLink = [ "/bin" "/etc" "/share" "/var" ];
          })
        ];
        config = {
          User = "container";
          WorkingDir = "/home/container";
          Env = [
            "/home/container"
          ];
          Entrypoint = [
            "/bin/entrypoint.sh"
          ];
        };
      };
    in {
      packages = mangbands // {
        default = mangbands.mangband;
        container = container;
      };
    });
}
