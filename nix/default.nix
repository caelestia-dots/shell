{
  rev,
  lib,
  stdenv,
  makeWrapper,
  makeFontsConf,
  fish,
  ddcutil,
  brightnessctl,
  app2unit,
  cava,
  networkmanager,
  lm_sensors,
  grim,
  swappy,
  wl-clipboard,
  libqalculate,
  inotify-tools,
  bluez,
  bash,
  hyprland,
  coreutils,
  findutils,
  file,
  material-symbols,
  rubik,
  nerd-fonts,
  gcc,
  qt6,
  quickshell,
  aubio,
  pipewire,
  wayland,
  wayland-protocols,
  wayland-scanner,
  caelestia-cli,
  withCli ? false,
  extraRuntimeDeps ? [],
}: let
  runtimeDeps =
    [
      fish
      ddcutil
      brightnessctl
      app2unit
      cava
      networkmanager
      lm_sensors
      grim
      swappy
      wl-clipboard
      libqalculate
      inotify-tools
      bluez
      bash
      hyprland
      coreutils
      findutils
      file
    ]
    ++ extraRuntimeDeps
    ++ lib.optional withCli caelestia-cli;

  fontconfig = makeFontsConf {
    fontDirectories = [material-symbols rubik nerd-fonts.caskaydia-cove];
  };

  beatDetector = stdenv.mkDerivation {
    pname = "beat-detector";
    version = "1.0";

    src = ./..;

    nativeBuildInputs = [gcc];
    buildInputs = [aubio pipewire];

    buildPhase = ''
      mkdir -p bin
      g++ -std=c++17 -Wall -Wextra \
      	-I${pipewire.dev}/include/pipewire-0.3 \
      	-I${pipewire.dev}/include/spa-0.2 \
      	-I${aubio}/include/aubio \
      	assets/cpp/beat-detector.cpp \
      	-o bin/beat_detector \
      	-lpipewire-0.3 -laubio
    '';

    installPhase = ''
      install -Dm755 bin/beat_detector $out/bin/beat_detector
    '';
  };

  idleInhibitor = stdenv.mkDerivation {
    pname = "wayland-idle-inhibitor";
    version = "1.0";

    src = ./..;

    nativeBuildInputs = [gcc wayland-scanner wayland-protocols];
    buildInputs = [wayland];

    buildPhase = ''
      wayland-scanner client-header < ${wayland-protocols}/share/wayland-protocols/unstable/idle-inhibit/idle-inhibit-unstable-v1.xml > idle-inhibitor.h
      wayland-scanner private-code < ${wayland-protocols}/share/wayland-protocols/unstable/idle-inhibit/idle-inhibit-unstable-v1.xml > idle-inhibitor.c
      cp assets/cpp/idle-inhibitor.cpp .

      gcc -o idle-inhibitor.o -c idle-inhibitor.c
      g++ -o inhibit_idle idle-inhibitor.cpp idle-inhibitor.o -lwayland-client
    '';

    installPhase = ''
      mkdir -p $out/bin
      install -Dm755 inhibit_idle $out/bin/inhibit_idle
    '';
  };
in
  stdenv.mkDerivation {
    pname = "caelestia-shell";
    version = "${rev}";
    src = ./..;

    nativeBuildInputs = [gcc makeWrapper qt6.wrapQtAppsHook];
    buildInputs = [quickshell beatDetector idleInhibitor qt6.qtbase];
    propagatedBuildInputs = runtimeDeps;

    installPhase = ''
      mkdir -p $out/share/caelestia-shell
      cp -r ./* $out/share/caelestia-shell

      makeWrapper ${quickshell}/bin/qs $out/bin/caelestia-shell \
      	--prefix PATH : "${lib.makeBinPath runtimeDeps}" \
      	--set FONTCONFIG_FILE "${fontconfig}" \
      	--set CAELESTIA_BD_PATH ${beatDetector}/bin/beat_detector \
      	--set CAELESTIA_II_PATH ${idleInhibitor}/bin/inhibit_idle \
      	--add-flags "-p $out/share/caelestia-shell"

      	ln -sf ${beatDetector}/bin/beat_detector $out/bin
      	ln -sf ${idleInhibitor}/bin/inhibit_idle $out/bin
    '';

    meta = {
      description = "A very segsy desktop shell";
      homepage = "https://github.com/caelestia-dots/shell";
      license = lib.licenses.gpl3Only;
      mainProgram = "caelestia-shell";
    };
  }
