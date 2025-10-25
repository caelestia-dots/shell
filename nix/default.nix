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
  networkmanager,
  lm_sensors,
  swappy,
  wl-clipboard,
  libqalculate,
  bash,
  hyprland,
  material-symbols,
  rubik,
  nerd-fonts,
  qt6,
  quickshell,
  aubio,
  libcava,
  fftw,
  pipewire,
  xkeyboard-config,
  cmake,
  ninja,
  pkg-config,
  caelestia-cli,
  papirus-icon-theme,
  adwaita-icon-theme,
  hicolor-icon-theme, # if using pkgs.hicolor-icon-theme
  acpi,
  debug ? false,
  withCli ? true,
  extraRuntimeDeps ? []
}:

let
  version = "1.0.0";

  runtimeDeps =
    [
      fish
      ddcutil
      brightnessctl
      app2unit
      networkmanager
      lm_sensors
      swappy
      wl-clipboard
      libqalculate
      bash
      hyprland
      papirus-icon-theme
      adwaita-icon-theme
      hicolor-icon-theme
      acpi
    ]
    ++ extraRuntimeDeps
    ++ lib.optional withCli caelestia-cli;

  fontconfig = makeFontsConf {
    fontDirectories = [ material-symbols rubik nerd-fonts.caskaydia-cove ];
  };

  cmakeBuildType = if debug then "Debug" else "RelWithDebInfo";

  cmakeVersionFlags = [
    (lib.cmakeFeature "VERSION" version)
    (lib.cmakeFeature "GIT_REVISION" rev)
    (lib.cmakeFeature "DISTRIBUTOR" "nix-flake")
  ];

  extras = stdenv.mkDerivation {
    inherit cmakeBuildType;
    pname = "caelestia-extras${lib.optionalString debug "-debug"}";
    src = lib.fileset.toSource {
      root = ./..;
      fileset = lib.fileset.union ./../CMakeLists.txt ./../extras;
    };

    nativeBuildInputs = [ cmake ninja ];

    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "extras")
        (lib.cmakeFeature "INSTALL_LIBDIR" "${placeholder "out"}/lib")
      ]
      ++ cmakeVersionFlags;
  };

  plugin = stdenv.mkDerivation {
    inherit cmakeBuildType;
    pname = "caelestia-qml-plugin${lib.optionalString debug "-debug"}";
    src = lib.fileset.toSource {
      root = ./..;
      fileset = lib.fileset.union ./../CMakeLists.txt ./../plugin;
    };

    nativeBuildInputs = [ cmake ninja pkg-config ];
    buildInputs = [ qt6.qtbase qt6.qtdeclarative libqalculate pipewire aubio libcava fftw ];
    dontWrapQtApps = true;

    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "plugin")
        (lib.cmakeFeature "INSTALL_QMLDIR" qt6.qtbase.qtQmlPrefix)
      ]
      ++ cmakeVersionFlags;
  };

  # Proper XDG data dir resolution for icon themes
  xdgDirs = lib.makeSearchPathOutput "share" [
    papirus-icon-theme
    adwaita-icon-theme
    hicolor-icon-theme
  ];

in
stdenv.mkDerivation rec {
  pname = "caelestia-shell${lib.optionalString debug "-debug"}";
  name = pname;
  version = "1.0.0";
  src = ./..;

  nativeBuildInputs = [ cmake ninja makeWrapper qt6.wrapQtAppsHook ];
  buildInputs = [ quickshell extras plugin xkeyboard-config qt6.qtbase ];
  propagatedBuildInputs = runtimeDeps;

  cmakeBuildType = if debug then "Debug" else "RelWithDebInfo";
  dontStrip = debug;

  cmakeFlags =
    [
      (lib.cmakeFeature "ENABLE_MODULES" "shell")
      (lib.cmakeFeature "INSTALL_QSCONFDIR" "${placeholder "out"}/share/caelestia-shell")
    ]
    ++ cmakeVersionFlags;

  prePatch = ''
    substituteInPlace assets/pam.d/fprint \
      --replace-fail pam_fprintd.so /run/current-system/sw/lib/security/pam_fprintd.so

    substituteInPlace shell.qml \
      --replace-fail 'ShellRoot {' 'ShellRoot { settings.watchFiles: false'
  '';

  postInstall = ''
    # Wrap the main executable
    makeWrapper ${quickshell}/bin/qs $out/bin/caelestia-shell \
      --prefix PATH : "${lib.makeBinPath runtimeDeps}" \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set CAELESTIA_LIB_DIR ${extras}/lib \
      --set CAELESTIA_XKB_RULES_PATH ${xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst \
      --set XDG_DATA_DIRS "${xdgDirs}" \
      --add-flags "-p $out/share/caelestia-shell"

    mkdir -p $out/lib
    ln -s ${extras}/lib/* $out/lib/
  '';

  passthru = {
    inherit plugin extras;
  };

  meta = {
    description = "A very segsy desktop shell";
    homepage = "https://github.com/caelestia-dots/shell";
    license = lib.licenses.gpl3Only;
    mainProgram = "caelestia-shell";
  };
}






























/*{
  rev,
  lib,
  stdenv,
  makeWrapper,
  makeFontsConf,
  fish,
  ddcutil,
  brightnessctl,
  app2unit,
  networkmanager,
  lm_sensors,
  swappy,
  wl-clipboard,
  libqalculate,
  bash,
  hyprland,
  material-symbols,
  rubik,
  nerd-fonts,
  qt6,
  quickshell,
  aubio,
  libcava,
  fftw,
  pipewire,
  xkeyboard-config,
  cmake,
  ninja,
  pkg-config,
  caelestia-cli,
  papirus-icon-theme,
  adwaita-icon-theme,
  hicolor-icon-theme,  # if using pkgs.hicolor-icon-theme,
  acpi,
  debug ? false,
  withCli ? true,
  extraRuntimeDeps ? [],
}: let
	xdgDirs = lib.makeSearchPathOutput "share"
  version = "1.0.0";

  runtimeDeps =
    [
      fish
      ddcutil
      brightnessctl
      app2unit
      networkmanager
      lm_sensors
      swappy
      wl-clipboard
      libqalculate
      bash
      hyprland
	  papirus-icon-theme
	  adwaita-icon-theme
	  hicolor-icon-theme 
	  acpi
    ]
    ++ extraRuntimeDeps
    ++ lib.optional withCli caelestia-cli;

  fontconfig = makeFontsConf {
    fontDirectories = [material-symbols rubik nerd-fonts.caskaydia-cove];
  };

  cmakeBuildType =
    if debug
    then "Debug"
    else "RelWithDebInfo";

  cmakeVersionFlags = [
    (lib.cmakeFeature "VERSION" version)
    (lib.cmakeFeature "GIT_REVISION" rev)
    (lib.cmakeFeature "DISTRIBUTOR" "nix-flake")
  ];

  extras = stdenv.mkDerivation {
    inherit cmakeBuildType;
    name = "caelestia-extras${lib.optionalString debug "-debug"}";
    src = lib.fileset.toSource {
      root = ./..;
      fileset = lib.fileset.union ./../CMakeLists.txt ./../extras;
    };

    nativeBuildInputs = [cmake ninja];

    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "extras")
        (lib.cmakeFeature "INSTALL_LIBDIR" "${placeholder "out"}/lib")
      ]
      ++ cmakeVersionFlags;
  };

  plugin = stdenv.mkDerivation {
    inherit cmakeBuildType;
    name = "caelestia-qml-plugin${lib.optionalString debug "-debug"}";
    src = lib.fileset.toSource {
      root = ./..;
      fileset = lib.fileset.union ./../CMakeLists.txt ./../plugin;
    };

    nativeBuildInputs = [cmake ninja pkg-config];
    buildInputs = [qt6.qtbase qt6.qtdeclarative libqalculate pipewire aubio libcava fftw];

    dontWrapQtApps = true;
    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "plugin")
        (lib.cmakeFeature "INSTALL_QMLDIR" qt6.qtbase.qtQmlPrefix)
      ]
      ++ cmakeVersionFlags;
  };
in
  stdenv.mkDerivation {
    inherit version cmakeBuildType;
    pname = "caelestia-shell${lib.optionalString debug "-debug"}";
    src = ./..;

    nativeBuildInputs = [cmake ninja makeWrapper qt6.wrapQtAppsHook];
    buildInputs = [quickshell extras plugin xkeyboard-config qt6.qtbase];
    propagatedBuildInputs = runtimeDeps;

    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "shell")
        (lib.cmakeFeature "INSTALL_QSCONFDIR" "${placeholder "out"}/share/caelestia-shell")
      ]
      ++ cmakeVersionFlags;

    dontStrip = debug;

    prePatch = ''
      substituteInPlace assets/pam.d/fprint \
        --replace-fail pam_fprintd.so /run/current-system/sw/lib/security/pam_fprintd.so
      substituteInPlace shell.qml \
        --replace-fail 'ShellRoot {' 'ShellRoot {  settings.watchFiles: false'
    '';

	xdgDirs = lib.makeSearchPathOutput "share" (lib.filter (x: x != null) [ papirus-icon-theme adwaita-icon-theme hicolor-icon-theme ]);

	postInstall = ''
  		makeWrapper ${quickshell}/bin/qs $out/bin/caelestia-shell \
    		--prefix PATH : "${lib.makeBinPath runtimeDeps}" \
    		--set FONTCONFIG_FILE "${fontconfig}" \
    		--set CAELESTIA_LIB_DIR ${extras}/lib \
    		--set CAELESTIA_XKB_RULES_PATH ${xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst \
    		--set XDG_DATA_DIRS "$xdgDirs" \
    		--add-flags "-p $out/share/caelestia-shell"

  		mkdir -p $out/lib
  		ln -s ${extras}/lib/* $out/lib/
'';


    passthru = {
      inherit plugin extras;
    };

    meta = {
      description = "A very segsy desktop shell";
      homepage = "https://github.com/caelestia-dots/shell";
      license = lib.licenses.gpl3Only;
      mainProgram = "caelestia-shell";
    };
  }*/

