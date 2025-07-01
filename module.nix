{
  config,
  pkgs,
  lib,
  caeshellPackage,
  ...
}:

let
  cfg = config.programs.caeshell;
in
{
  options.programs.caeshell = {
    enable = lib.mkEnableOption "a custom btop module for Home Manager";

    iconTheme = lib.mkOption {
      type = lib.types.attributeSet;
      description = "The iconTheme of qt.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      caeshellPackage
      pkgs.material-symbols
    ];
    qt.iconTheme = cfg.iconTheme;
  };
}
