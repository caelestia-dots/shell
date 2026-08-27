{
  lib,
  stdenv,
  makeWrapper,
  gjs,
  glib,
}:
stdenv.mkDerivation {
  pname = "caelestia-bbm-daemon";
  version = "1.0.0";

  src = lib.fileset.toSource {
    root = ./..;
    fileset = lib.fileset.unions [
      ./../bbm/daemon
      ./../bbm/lib
      ./../bbm/icons
    ];
  };

  nativeBuildInputs = [makeWrapper glib];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -d $out/share/bbm
    cp -r bbm/daemon $out/share/bbm/daemon
    cp -r bbm/lib    $out/share/bbm/lib
    cp -r bbm/icons  $out/share/bbm/icons

    # Compile GSettings schemas for the target system's GLib version
    glib-compile-schemas $out/share/bbm/daemon/schemas/

    install -d $out/bin
    makeWrapper ${gjs}/bin/gjs $out/bin/bbm-daemon \
      --add-flags "-m $out/share/bbm/daemon/main.js"

    runHook postInstall
  '';

  meta = {
    description = "Bluetooth Battery Meter headless D-Bus daemon";
    homepage = "https://github.com/maniacx/Bluetooth-Battery-Meter";
    license = lib.licenses.gpl2Only;
    mainProgram = "bbm-daemon";
  };
}
