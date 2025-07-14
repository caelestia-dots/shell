{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    quickshell.url = "github:outfoxxed/quickshell";
  };

  outputs = { self, nixpkgs, flake-utils, quickshell }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "caelestia-shell";
          src = ./.;

          buildInputs = with pkgs; [
            ddcutil
            brightnessctl
            cava
            networkmanager
            lm_sensors
            fish
            aubio
            pipewire
            qt6.qtdeclarative
            material-design-icons
            (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
            grim
            swappy
            libqalculate
          ];

          nativeBuildInputs = with pkgs; [
            gnumake
            gcc
          ];

          installPhase = ''
            mkdir -p $out/share/quickshell/caelestia
            cp -r ./* $out/share/quickshell/caelestia

            g++ -std=c++17 -Wall -Wextra -I${pkgs.pipewire}/include/pipewire-0.3 -I${pkgs.pipewire}/include/spa-0.2 -I${pkgs.aubio}/include/aubio -o beat_detector assets/beat_detector.cpp -lpipewire-0.3 -laubio
            mkdir -p $out/lib/caelestia
            mv beat_detector $out/lib/caelestia/beat_detector
          '';
        };
      });
}
