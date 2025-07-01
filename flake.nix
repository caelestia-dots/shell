{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";

      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
    in
    {
      packages.${system} =
        let
          pkgs = import inputs.nixpkgs {
            config.allowUnfree = true;
            inherit system;
          };
        in
        {
          default = pkgs.stdenv.mkDerivation {
            name = "caeshell";
            version = "0.1.0";
            buildInputs = with pkgs; [
              inputs.quickshell.packages.${system}.default
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
              material-symbols
            ];
            nativeBuildInputs = [
              pkgs.makeWrapper
              pkgs.qt6.wrapQtAppsHook
              pkgs.pkg-config
              pkgs.pipewire.dev
            ];
            src = ./.;
            doCheck = false;
            buildPhase = ''
              g++ -std=c++17 -Wall -Wextra -o beat_detector assets/beat_detector.cpp \
              $(pkg-config --cflags --libs aubio libpipewire-0.3)
            '';
            installPhase = ''
              mkdir -p $out/lib
              cp -r $src/* $out/lib
              cp beat_detector $out/lib/beat_detector
              wrapProgram $out/lib/run.fish \
                --set PATH "$out/lib:$PATH" \
                --set CAELESTIA_BD_PATH $out/lib/beat_detector
            '';
          };
        };
    };
}
