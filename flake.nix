{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Use { self, ... } to easily access inputs and this flake's own outputs
  outputs =
    {
      self,
      nixpkgs,
      quickshell,
    }:
    let
      # Define system and pkgs once for reuse
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };

      # 1. Define your package as a local variable
      caeshellPkg = pkgs.stdenv.mkDerivation {
        name = "caeshell";
        version = "0.1.0";
        src = ./.;

        buildInputs = with pkgs; [
          quickshell.packages.${system}.default
          ddcutil
          brightnessctl
          cava
          networkmanager
          lm_sensors
          qt6.qtdeclarative
          material-symbols
          nerd-fonts.jetbrains-mono
          grim
          swappy
          pipewire
          aubio
          libqalculate
          bluez
          inotify-tools
        ];

        nativeBuildInputs = [
          pkgs.makeWrapper
          pkgs.qt6.wrapQtAppsHook
          pkgs.pkg-config
          # Use pkgs.pipewire.dev for development headers
          pkgs.pipewire.dev
        ];

        doCheck = false;

        buildPhase = ''
          runHook preBuild
          g++ -std=c++17 -Wall -Wextra -o beat_detector assets/beat_detector.cpp \
            $(pkg-config --cflags --libs aubio libpipewire-0.3)
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          # Create a bin directory for executables
          mkdir -p $out/bin $out/lib
          # Copy library files and assets
          cp -r $src/* $out/lib
          # Copy the compiled binary
          cp beat_detector $out/lib/beat_detector

          # Wrap the main script and place it in $out/bin
          makeWrapper $out/lib/run.fish $out/bin/caeshell \
            --set PATH "$out/lib:${pkgs.lib.makeBinPath [ pkgs.fish ]}" \
            --set CAELESTIA_BD_PATH "$out/lib/beat_detector"
          runHook postInstall
        '';
      };

    in
    {
      # 2. Expose the package using the variable
      packages.${system} = {
        default = caeshellPkg;
        caeshell = caeshellPkg;
      };
      overlay =
        final: prev:
        let
          pkgs = final;
        in
        {
          caeshell = self.packages.system.default;
        };
      # 3. Pass the package variable into your module
      homeModules.caeshell = import ./module.nix self;
    };
}
