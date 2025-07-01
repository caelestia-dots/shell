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
      type = lib.types.attrs;
      description = "The iconTheme of qt.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.material-symbols
      self.packages.${pkgs.system}.default
    ];
    stylix.iconTheme = cfg.iconTheme;
    systemd.user.services = {
      caeshell = {
        Unit = {
          Description = "";
          Documentation = "";
          PartOf = [ config.wayland.systemd.target ];
          After = [ config.wayland.systemd.target ];
        };
        Service = {
          ExecStart = "${self.packages.${pkgs.system}.default}/bin/caeshell";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        };
        Install = {
          WantedBy = [ config.wayland.systemd.target ];
        };
      };
    };
  };
}
