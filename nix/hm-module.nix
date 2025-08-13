self: {
  config,
  pkgs,
  lib,
  ...
}: let
  cli-default = self.inputs.caelestia-cli.packages.${pkgs.system}.default;
  shell-default = self.packages.${pkgs.system}.with-cli;

  cfg = config.programs.caelestia;
in {
  options = with lib; {
    programs.caelestia = {
      enable = mkEnableOption "Enable Caelestia shell";
      package = mkOption {
        type = types.package;
        default = shell-default;
        description = "The package of Caelestia shell";
      };
      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "Caelestia shell settings";
      };
      extraConfig = mkOption {
        type = types.str;
        default = "";
        description = "Caelestia shell extra configs written to shell.json";
      };
      cli = {
        enable = mkEnableOption "Enable Caelestia CLI";
        package = mkOption {
          type = types.package;
          default = cli-default;
          description = "The package of Caelestia CLI"; # Doesn't override the shell's CLI, only change from home.packages
        };
      };
    };
  };

  config = let
    cli = cfg.cli.package or cli-default;
    shell = cfg.package or shell-default;
  in
    lib.mkIf cfg.enable {
      systemd.user.services.caelestia = {
        Unit = {
          Description = "Caelestia Shell Service";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };

        Service = {
          Type = "exec";
          ExecStart = "${shell}/bin/caelestia-shell";
          Restart = "on-failure";
          RestartSec = "5s";
          TimeoutStopSec = "5s";
          Environment = [
            "QT_QPA_PLATFORM=wayland"
          ];

          Slice = "session.slice";
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };

      xdg.configFile."caelestia/shell.json".text = let
        extraConfig =
          if cfg.extraConfig != ""
          then cfg.extraConfig
          else "{}";
      in
        builtins.toJSON (lib.recursiveUpdate
          (cfg.settings or {}) (builtins.fromJSON extraConfig));

      home.packages = [shell] ++ lib.optional cfg.cli.enable cli;
    };
}
