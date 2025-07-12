{
  description = "Caelstia Shell Packaged as flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    quickshell = {
      # Apparently these dots track master branch not release
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-cli = {
      url = "github:pinksteven/caelestia-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      quickshell,
      caelestia-cli,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        qs = quickshell.packages.${system}.default;
      in
      {
        packages = {
          shell =
            let
              deps = with pkgs; [
                app2unit
                aubio
                bluez
                brightnessctl
                cava
                curl
                ddcutil
                fishMinimal
                grim
                inotify-tools
                libqalculate
                lm_sensors
                networkmanager
                pipewire
                power-profiles-daemon
                procps
                kdePackages.qtdeclarative
                qs
                jq
                swappy
              ];

              fontconfig = pkgs.makeFontsConf {
                fontDirectories = [ pkgs.material-symbols ];
              };
            in
            pkgs.stdenv.mkDerivation {
              pname = "caelestia-shell";
              src = ./.;
              version = "0.0.1+git.${self.shortRev or "dirty"}";

              nativeBuildInputs = with pkgs; [
                gcc
                makeWrapper
                qt6.wrapQtAppsHook
              ];

              propagatedBuildInputs = deps;

              buildPhase = ''
                runHook preBuild

                mkdir -p bin
                g++ -std=c++17 -Wall -Wextra \
                -I${pkgs.pipewire.dev}/include/pipewire-0.3 \
                -I${pkgs.pipewire.dev}/include/spa-0.2 \
                -I${pkgs.aubio}/include/aubio \
                assets/beat_detector.cpp \
                -o bin/beat_detector \
                -lpipewire-0.3 -laubio

                runHook postBuild
              '';

              installPhase = ''
                runHook preInstall

                mkdir -p $out/bin
                mkdir -p $out/share/quickshell/caelestia
                mkdir -p $out/share/fonts

                cp -r assets config modules services utils widgets $out/share/quickshell/caelestia/
                cp -r ${pkgs.material-symbols}/share/fonts/* $out/share/fonts/
                cp shell.qml $out/share/quickshell/caelestia/
                cp bin/beat_detector $out/bin/

                runHook postInstall
              '';

              patchPhase = ''
                substituteInPlace run.fish \
                  --replace-fail "(dirname (status filename))" "$out/share/quickshell/caelestia"
              '';

              postFixup = ''
                cat > $out/bin/caelestia-shell << EOF
                #!/usr/bin/env bash

                unset QT_STYLE_OVERRIDE
                export QT_QUICK_CONTROLS_STYLE=Basic
                export CAELESTIA_BD_PATH="$out/bin/beat_detector"

                export PATH="${pkgs.lib.makeBinPath deps}:$PATH"
                export FONTCONFIG_PATH="${fontconfig}:$FONTCONFIG_PATH"

                shellPath="$out/share/quickshell/caelestia/shell.qml"

                ${qs}/bin/qs list --all -j | jq -c --arg sp "\$shellPath" '
                .[]
                | select(.config_path | contains("caelestia"))
                | select(.config_path != \$sp)
                | {pid: .pid, config_path: .config_path}
                ' | while read -r line; do
                  pid=\$(echo "\$line" | jq '.pid')
                  path=\$(echo "\$line" | jq -r '.config_path')
                  echo "Killing PID \$pid due to mismatched config path:"
                  echo "Found:    \$path"
                  echo "Expected: \$shellPath"
                  ${qs}/bin/qs kill --pid "\$pid"
                  ${qs}/bin/qs -p "$out/share/quickshell/caelestia" -d
                done

                ${qs}/bin/qs -p "$out/share/quickshell/caelestia" \$@
                EOF

                chmod +x $out/bin/caelestia-shell
              '';
            };
          default = pkgs.buildEnv {
            name = "caelestia";
            paths = [
              self.packages.${system}.shell
              caelestia-cli.packages.${system}.default
            ];
          };
        };
      }
    );
}
