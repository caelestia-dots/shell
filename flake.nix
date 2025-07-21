{
  description = "Desktop shell for Caelestia dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    app2unit = {
      url = "github:soramanew/app2unit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.app2unit.follows = "app2unit";
      inputs.caelestia-shell.follows = "";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = fn:
      nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux (
        system: fn nixpkgs.legacyPackages.${system}
      );
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (pkgs: rec {
      caelestia-shell = pkgs.callPackage ./default.nix {
        rev = self.rev or self.dirtyRev;
        quickshell = inputs.quickshell.packages.${pkgs.system}.default.override {
          withX11 = false;
          withI3 = false;
        };
        app2unit = inputs.app2unit.packages.${pkgs.system}.default;
        caelestia-cli = inputs.caelestia-cli.packages.${pkgs.system}.default;
      };
      default = caelestia-shell;
    });

    devShells = forAllSystems (pkgs: {
      default = let
        shell = self.packages.${pkgs.system}.caelestia-shell;
      in
        pkgs.mkShellNoCC {
          inputsFrom = [shell];
          packages = [pkgs.material-symbols];
          CAELESTIA_BD_PATH = "${shell}/bin/beat_detector";
          QT_LOGGING_RULES = builtins.concatStringsSep ";" [
            "quickshell.dbus.properties.warning=false"
            "quickshell.dbus.dbusmenu.warning=false"
            "quickshell.service.notifications.warning=false"
            "quickshell.service.sni.host.warning=false"
            "qt.qpa.wayland.textinput.warning=false"
          ];
        };
    });
  };
}
