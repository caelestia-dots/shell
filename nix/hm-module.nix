self: {
  config,
  pkgs,
  lib,
  ...
}: let
  shell-default = self.packages.${pkgs.system}.default;

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
    };
  };

  config = let
    shell = cfg.package or shell-default;
  in
    lib.mkIf cfg.enable {
      systemd.user.services.caelestia = {
        Unit = {
          Description = "Caelestia Shell Service";
          After = ["hyprland-session.target"];
          Requires = ["hyprland-session.target"];
          PartOf = ["graphical-session.target"];
        };

        Service = {
          ExecStart = "${shell}/bin/caelestia-shell";
          Restart = "on-failure";
          RestartSec = "5s";
          Environment = [
            "QT_QPA_PLATFORM=wayland"
          ];

          PassEnvironment = [
            "WAYLAND_DISPLAY"
            "XDG_RUNTIME_DIR"
            "HYPRLAND_INSTANCE_SIGNATURE"
          ];
          Slice = "session.slice";
        };

        Install = {
          WantedBy = ["hyprland-session.target"];
        };
      };

      home.file.".config/caelestia/shell.json".text = let
        extraConfig =
          if cfg.extraConfig != ""
          then cfg.extraConfig
          else "{}";
      in
        builtins.toJSON (lib.recursiveUpdate
          (cfg.settings or {}) (builtins.fromJSON extraConfig));

      home.packages = [shell];
    };
}
