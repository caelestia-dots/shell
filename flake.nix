/*{
  description = "Desktop shell for Caelestia dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
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
      caelestia-shell = pkgs.callPackage ./nix {
        rev = self.rev or self.dirtyRev;
        stdenv = pkgs.clangStdenv;
        quickshell = inputs.quickshell.packages.${pkgs.system}.default.override {
          withX11 = false;
          withI3 = false;
        };
        app2unit = pkgs.callPackage ./nix/app2unit.nix {inherit pkgs;};
        caelestia-cli = inputs.caelestia-cli.packages.${pkgs.system}.default;
      };
      with-cli = caelestia-shell.override {withCli = true;};
      debug = caelestia-shell.override {debug = true;};
      default = caelestia-shell;
    });

    devShells = forAllSystems (pkgs: {
      default = let
        shell = self.packages.${pkgs.system}.caelestia-shell;
      in
        pkgs.mkShell.override {stdenv = shell.stdenv;} {
          inputsFrom = [shell shell.plugin shell.extras];
          packages = with pkgs; [clazy material-symbols rubik nerd-fonts.caskaydia-cove];
          CAELESTIA_XKB_RULES_PATH = "${pkgs.xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst";
        };
    });

    homeManagerModules.default = import ./nix/hm-module.nix self;
  };
}*/
{
  description = "Desktop shell for Caelestia dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.caelestia-shell.follows = "";
    };
  };

  outputs = { self, nixpkgs, ... } @ inputs:
  let
    forAllSystems = fn:
      nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux
        (system: fn nixpkgs.legacyPackages.${system});
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (pkgs: rec {
      caelestia-shell =
        (pkgs.callPackage ./nix {
          rev = "local";
          stdenv = pkgs.clangStdenv;
          quickshell = inputs.quickshell.packages.${pkgs.system}.default.override {
            withX11 = false;
            withI3 = false;
          };
          app2unit = pkgs.callPackage ./nix/app2unit.nix { inherit pkgs; };
          caelestia-cli = inputs.caelestia-cli.packages.${pkgs.system}.default;
        })
        // {
          # Ensure Home Manager sees a valid name attribute
          name = "caelestia-shell";
        };

      with-cli = caelestia-shell.override { withCli = true; };
      debug = caelestia-shell.override { debug = true; };

      # Default package output
      default = caelestia-shell;
    });

    devShells = forAllSystems (pkgs: {
      default =
        let shell = self.packages.${pkgs.system}.caelestia-shell;
        in pkgs.mkShell.override { stdenv = shell.stdenv; } {
          inputsFrom = [ shell shell.plugin shell.extras ];
          packages = with pkgs; [
            clazy
            material-symbols
            rubik
            nerd-fonts.caskaydia-cove
          ];
          CAELESTIA_XKB_RULES_PATH =
            "${pkgs.xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst";
        };
    });

    homeManagerModules.default = import ./nix/hm-module.nix self;
  };
}

