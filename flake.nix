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
        quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
          withX11 = false;
          withI3 = false;
        };
        caelestia-cli = inputs.caelestia-cli.packages.${pkgs.stdenv.hostPlatform.system}.default;
        qt6 = pkgs.qt6;
      };
      with-cli = caelestia-shell.override {withCli = true;};
      debug = caelestia-shell.override {debug = true;};
      default = caelestia-shell;
    });

    devShells = forAllSystems (pkgs: {
  default = let
    shell = self.packages.${pkgs.stdenv.hostPlatform.system}.caelestia-shell;
  in
    pkgs.mkShell.override {stdenv = shell.stdenv;} {
      inputsFrom = [shell shell.plugin shell.extras];
      packages = with pkgs; [
        clazy material-symbols rubik nerd-fonts.caskaydia-cove
        qt6.qtmultimedia
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-libav
      ];
      CAELESTIA_XKB_RULES_PATH = "${pkgs.xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst";
      shellHook = ''
      export QML2_IMPORT_PATH="$PWD/build/qml:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:$QML2_IMPORT_PATH"
      export QT_PLUGIN_PATH="${pkgs.qt6.qtmultimedia}/lib/qt-6/plugins:${pkgs.gst_all_1.gstreamer}/lib/qt-6/plugins:$QT_PLUGIN_PATH"
      '';
    };
});

    homeManagerModules.default = import ./nix/hm-module.nix self;
  };
}
