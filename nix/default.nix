{
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
  qt6,
  quickshell,
  aubio,
  pipewire,
  xkeyboard-config,
  cmake,
  ninja,
  pkg-config,
  caelestia-cli,
  withCli ? false,
  extraRuntimeDeps ? [],
}: let
  version = "1.0.0";

  runtimeDeps =
    [
      fish
      ddcutil
      brightnessctl
      app2unit
      cava
      networkmanager
      lm_sensors
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

  assets = stdenv.mkDerivation {
    name = "caelestia-assets";
    src = ./../assets/cpp;

    nativeBuildInputs = [cmake pkg-config];
    buildInputs = [aubio pipewire];

    cmakeFlags = [(lib.cmakeFeature "INSTALL_LIBDIR" "${placeholder "out"}/lib")];
  };

  plugin = stdenv.mkDerivation {
    name = "caelestia-qml-plugin";
    src = ./../plugin;
    nativeBuildInputs = [cmake];
    buildInputs = [qt6.qtbase qt6.qtdeclarative];
    dontWrapQtApps = true;
    cmakeFlags = [(lib.cmakeFeature "INSTALL_QMLDIR" qt6.qtbase.qtQmlPrefix)];
  };
in
  stdenv.mkDerivation {
    inherit version;
    pname = "caelestia-shell";
    src = ./..;

    nativeBuildInputs = [cmake ninja makeWrapper qt6.wrapQtAppsHook];
    buildInputs = [quickshell assets plugin xkeyboard-config qt6.qtbase];
    propagatedBuildInputs = runtimeDeps;

    cmakeBuildType = "Release";
    cmakeFlags = [
      (lib.cmakeFeature "VERSION" version)
      (lib.cmakeFeature "DONT_BUILD_PLUGIN" "ON")
      (lib.cmakeFeature "DONT_BUILD_ASSETS" "ON")
      (lib.cmakeFeature "INSTALL_QSCONFDIR" "${placeholder "out"}/share/caelestia-shell")
    ];

    prePatch = ''
      substituteInPlace assets/pam.d/fprint \
        --replace-fail pam_fprintd.so /run/current-system/sw/lib/security/pam_fprintd.so
    '';

    postInstall = ''
      makeWrapper ${quickshell}/bin/qs $out/bin/caelestia-shell \
      	--prefix PATH : "${lib.makeBinPath runtimeDeps}" \
      	--set FONTCONFIG_FILE "${fontconfig}" \
      	--set CAELESTIA_LIB_DIR ${assets}/lib \
        --set CAELESTIA_XKB_RULES_PATH ${xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst \
      	--add-flags "-p $out/share/caelestia-shell"
    '';

    passthru = {
      inherit plugin assets;
    };

    meta = {
      description = "A very segsy desktop shell";
      homepage = "https://github.com/caelestia-dots/shell";
      license = lib.licenses.gpl3Only;
      mainProgram = "caelestia-shell";
    };
  }
