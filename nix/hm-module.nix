self: {
  config,
  pkgs,
  lib,
  ...
}: let
  caelestia-cli = self.inputs.caelestia-cli.packages.${pkgs.system}.default;
  caelestia-shell = self.packages.${pkgs.system}.default;

  caelestia-cli-ipc = "${caelestia-cli}/bin/caelestia shell";
  caelestia-shell-ipc = "${caelestia-shell}/bin/caelestia-shell ipc call"; # Using this seems faster than caelestia-cli-ipc

  cfg = config.programs.caelestia;
in {
  options = with lib; {
    programs.caelestia = {
      enable = mkEnableOption "Enable Caelestia shell";

      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "Caelestia settings written to shell.json";
      };

      ipcType = mkOption {
        type = types.enum [
          "shell"
          "cli"
        ];
        default = "shell";
        description = "Caelestia IPC type, can be either \"shell\" or \"cli\", note that some commands may not work on both";
      };

      ipcCmd = mkOption {
        type = types.str;
        description = "IPC command used in this module, configured by ipcType option";
        readOnly = true;
      };

      binds = {
        enable = mkEnableOption "Enable useful keybinds to Hyprland";
        toggleDashboard = mkOption {
          type = types.str;
          description = "Hyprland bind to toggle the dashboard.";
          example = "SUPER, D";
          default = "";
        };
        toggleLauncher = mkOption {
          type = types.str;
          description = "Hyprland bind to toggle the launcher.";
          example = "SUPER, D";
          default = "";
        };
        toggleOsd = mkOption {
          type = types.str;
          description = "Hyprland bind to toggle the OSD.";
          example = "SUPER, D";
          default = "";
        };
        toggleBar = mkOption {
          type = types.str;
          description = "Hyprland bind to toggle the bar.";
          example = "SUPER, D";
          default = "";
        };
        openPicker = mkOption {
          type = types.str;
          description = "Hyprland bind to open the picker.";
          example = "SUPER, D";
          default = "";
        };
        openPickerFreeze = mkOption {
          type = types.str;
          description = "Hyprland bind to open the picker while freezing the screen.";
          example = "SUPER, D";
          default = "";
        };
        openControlCenter = mkOption {
          type = types.str;
          description = "Hyprland bind to open the Control Center.";
          example = "SUPER, D";
          default = "";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.caelestia.ipcCmd =
      if cfg.ipcType == "shell"
      then caelestia-shell-ipc
      else caelestia-cli-ipc;

    wayland.windowManager.hyprland = {
      settings = {
        bind = let
          bindIfConfigured = bindOpt: bindCmd: (lib.optional (bindOpt != "") "${bindOpt}, exec, ${cfg.ipcCmd} ${bindCmd}");
        in
          with cfg.binds;
            lib.optionals cfg.binds.enable (
              []
              ++ bindIfConfigured toggleDashboard "drawers toggle dashboard"
              ++ bindIfConfigured toggleLauncher "drawers toggle launcher"
              ++ bindIfConfigured toggleOsd "drawers toggle osd"
              ++ bindIfConfigured toggleBar "drawers toggle bar"
              ++ bindIfConfigured openPicker "picker open"
              ++ bindIfConfigured openPickerFreeze "picker openFreeze"
              ++ bindIfConfigured openControlCenter "controlcenter open"
            );
      };
    };

    systemd.user.services.caelestia = {
      Unit = {
        Description = "Caelestia Shell Service";
        After = ["hyprland-session.target"];
        Requires = ["hyprland-session.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = "${caelestia-shell}/bin/caelestia-shell";
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

    home.file.".config/caelestia/shell.json".text = builtins.toJSON (cfg.settings or {});

    home.packages = [caelestia-cli caelestia-shell];
  };
}
