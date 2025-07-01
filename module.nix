self:
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
      pkgs.material-symbols
      pkgs.caeshell
    ];
    qt.iconTheme = cfg.iconTheme;
  };
}
