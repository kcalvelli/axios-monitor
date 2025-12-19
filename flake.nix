{
  description = "Nix Monitor - A DankMaterialShell plugin for monitoring Nix store and home-manager generations";

  outputs =
    { self, ... }:
    let
      mkNixMonitorModule =
        {
          isNixOS ? false,
        }:
        {
          config,
          lib,
          pkgs,
          ...
        }:
        with lib;
        let
          cfg = if isNixOS then config.services.nix-monitor else config.programs.nix-monitor;
          username = if isNixOS then config.services.nix-monitor.user else config.home.username;

          configFile = pkgs.writeText "nix-monitor-config.json" (
            builtins.toJSON {
              generationsCommand = cfg.generationsCommand;
              storeSizeCommand = cfg.storeSizeCommand;
              rebuildCommand = cfg.rebuildCommand;
              gcCommand = cfg.gcCommand;
              updateInterval = cfg.updateInterval;
            }
          );

          options = {
            enable = mkEnableOption "Nix Monitor plugin for DankMaterialShell";

            generationsCommand = mkOption {
              type = types.listOf types.str;
              default = [
                "sh"
                "-c"
                "nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l"
              ];
              description = "Command to count Nix system generations";
              example = literalExpression ''
                [ "sh" "-c" "nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l" ]
              '';
            };

            storeSizeCommand = mkOption {
              type = types.listOf types.str;
              default = [
                "sh"
                "-c"
                "du -sh /nix/store 2>/dev/null | cut -f1"
              ];
              description = "Command to get Nix store size";
              example = literalExpression ''
                [ "sh" "-c" "du -sh /nix/store 2>/dev/null | cut -f1" ]
              '';
            };

            rebuildCommand = mkOption {
              type = types.listOf types.str;
              description = "Command to run for system rebuild (required)";
              example = literalExpression ''
                [ "bash" "-c" "sudo nixos-rebuild switch --flake .#hostname 2>&1" ]
              '';
            };

            gcCommand = mkOption {
              type = types.listOf types.str;
              default = [
                "sh"
                "-c"
                "nix-collect-garbage -d 2>&1"
              ];
              description = "Command to run for garbage collection";
              example = literalExpression ''
                [ "bash" "-c" "nix-collect-garbage -d 2>&1" ]
              '';
            };

            updateInterval = mkOption {
              type = types.int;
              default = 300;
              description = "Update interval in seconds for refreshing statistics";
              example = 600;
            };
          }
          // (
            if isNixOS then
              {
                user = mkOption {
                  type = types.str;
                  description = "User for which to install the plugin";
                  example = "youruser";
                };
              }
            else
              { }
          );

          configPath =
            if isNixOS then
              "/home/${username}/.config/DankMaterialShell/plugins/NixMonitor"
            else
              ".config/DankMaterialShell/plugins/NixMonitor";
        in
        {
          options =
            if isNixOS then
              {
                services.nix-monitor = options;
              }
            else
              {
                programs.nix-monitor = options;
              };

          config = mkIf cfg.enable (mkMerge [
            {
              assertions = [
                {
                  assertion = cfg.rebuildCommand != null;
                  message = "${
                    if isNixOS then "services" else "programs"
                  }.nix-monitor.rebuildCommand must be set when nix-monitor is enabled";
                }
              ];
            }
            (
              if isNixOS then
                {
                  system.userActivationScripts.nix-monitor = ''
                    mkdir -p /home/${username}/.config/DankMaterialShell/plugins/NixMonitor
                    cp -rf ${self}/* /home/${username}/.config/DankMaterialShell/plugins/NixMonitor/
                    cp ${configFile} /home/${username}/.config/DankMaterialShell/plugins/NixMonitor/config.json
                    chown -R ${username} /home/${username}/.config/DankMaterialShell/plugins/NixMonitor
                  '';
                }
              else
                {
                  home.file.".config/DankMaterialShell/plugins/NixMonitor" = {
                    source = self;
                    recursive = true;
                  };

                  home.file.".config/DankMaterialShell/plugins/NixMonitor/config.json" = {
                    source = configFile;
                  };
                }
            )
          ]);
        };
    in
    {
      homeManagerModules.default = mkNixMonitorModule { isNixOS = false; };

      nixosModules.default = mkNixMonitorModule { isNixOS = true; };

      dmsPlugin = self;
    };
}
