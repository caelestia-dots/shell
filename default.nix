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
  nerd-fonts,
  gcc,
  quickshell,
  aubio,
  pipewire,
  libxkbcommon,
  pkg-config,
  caelestia-cli,
  withCli ? false,
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
    ++ lib.optional withCli caelestia-cli;

  fontconfig = makeFontsConf {
    fontDirectories = [material-symbols nerd-fonts.jetbrains-mono];
  };
in
  stdenv.mkDerivation {
    pname = "caelestia-shell";
    version = "${rev}";
    src = ./.;

    nativeBuildInputs = [gcc makeWrapper];
    buildInputs = [quickshell aubio pipewire libxkbcommon pkg-config];
    propagatedBuildInputs = runtimeDeps;

    buildPhase = ''
      mkdir -p bin
      g++ -std=c++17 -Wall -Wextra \
      	-I${pipewire.dev}/include/pipewire-0.3 \
      	-I${pipewire.dev}/include/spa-0.2 \
      	-I${aubio}/include/aubio \
      	assets/beat_detector.cpp \
      	-o bin/beat_detector \
      	-lpipewire-0.3 -laubio
      g++ -std=c++17 -Wall -Wextra \
        -I${libxkbcommon.dev}/include \
       	assets/kb_brief_detector.cpp \
       	-o bin/kb_brief_detector \
        $(pkg-config --cflags --libs xkbregistry xkbcommon)
    '';

    installPhase = ''
      install -Dm755 bin/beat_detector $out/bin/beat_detector
      install -Dm755 bin/kb_brief_detector $out/bin/kb_brief_detector
      makeWrapper ${quickshell}/bin/qs $out/bin/caelestia-shell \
      	--prefix PATH : "${lib.makeBinPath runtimeDeps}" \
      	--set FONTCONFIG_FILE "${fontconfig}" \
      	--set CAELESTIA_BD_PATH $out/bin/beat_detector \
      	--set CAELESTIA_KBBD_PATH $out/bin/kb_brief_detector \
      	--add-flags '-p ${./.}'
    '';

    meta = {
      description = "A very segsy desktop shell";
      homepage = "https://github.com/caelestia-dots/shell";
      license = lib.licenses.gpl3Only;
      mainProgram = "caelestia-shell";
    };
  }
