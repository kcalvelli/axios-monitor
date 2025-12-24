{
  description = "axiOS Monitor - A DankMaterialShell plugin for monitoring axiOS systems";

  outputs =
    { self, ... }:
    let
      mkAxiosMonitorModule =
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
          cfg = config.programs.axios-monitor;

          configFile = pkgs.writeText "axios-monitor-config.json" (
            builtins.toJSON {
              generationsCommand = cfg.generationsCommand;
              storeSizeCommand = cfg.storeSizeCommand;
              rebuildCommand = cfg.rebuildCommand;
              rebuildBootCommand = cfg.rebuildBootCommand;
              gcCommand = cfg.gcCommand;
              updateInterval = cfg.updateInterval;
              localRevisionCommand = cfg.localRevisionCommand;
              remoteRevisionCommand = cfg.remoteRevisionCommand;
            }
          );
        in
        {
          options.programs.axios-monitor = {
            enable = mkEnableOption "axiOS Monitor plugin for DankMaterialShell";

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
              description = "Command to run for system rebuild switch (required)";
              example = literalExpression ''
                [ "bash" "-c" "sudo nixos-rebuild switch --flake .#hostname 2>&1" ]
              '';
            };

            rebuildBootCommand = mkOption {
              type = types.listOf types.str;
              description = "Command to run for system rebuild boot (required)";
              example = literalExpression ''
                [ "bash" "-c" "sudo nixos-rebuild boot --flake .#hostname 2>&1" ]
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

            localRevisionCommand = mkOption {
              type = types.listOf types.str;
              description = "Command to get local axiOS revision from flake.lock";
              example = literalExpression ''
                [ "sh" "-c" "jq -r '.nodes.axios.locked.rev' ~/.config/nixos_config/flake.lock | cut -c 1-7" ]
              '';
            };

            remoteRevisionCommand = mkOption {
              type = types.listOf types.str;
              description = "Command to get remote axiOS revision from GitHub";
              example = literalExpression ''
                [ "sh" "-c" "git ls-remote https://github.com/kcalvelli/axios.git master | cut -c 1-7" ]
              '';
            };
          };

          config = mkIf cfg.enable (mkMerge [
            {
              assertions = [
                {
                  assertion = cfg.rebuildCommand != null;
                  message = "programs.axios-monitor.rebuildCommand must be set when axios-monitor is enabled";
                }
                {
                  assertion = cfg.rebuildBootCommand != null;
                  message = "programs.axios-monitor.rebuildBootCommand must be set when axios-monitor is enabled";
                }
                {
                  assertion = cfg.localRevisionCommand != null;
                  message = "programs.axios-monitor.localRevisionCommand must be set when axios-monitor is enabled";
                }
                {
                  assertion = cfg.remoteRevisionCommand != null;
                  message = "programs.axios-monitor.remoteRevisionCommand must be set when axios-monitor is enabled";
                }
              ];
            }
            (
              if isNixOS then
                {
                  environment.etc."xdg/quickshell/dms-plugins/AxiosMonitor" = {
                    source = self;
                  };

                  environment.etc."xdg/quickshell/dms-plugins/AxiosMonitor/config.json" = {
                    source = configFile;
                  };
                }
              else
                {
                  home.file.".config/DankMaterialShell/plugins/AxiosMonitor" = {
                    source = self;
                    recursive = true;
                  };

                  home.file.".config/DankMaterialShell/plugins/AxiosMonitor/config.json" = {
                    source = configFile;
                  };
                }
            )
          ]);
        };
    in
    {
      homeManagerModules.default = mkAxiosMonitorModule { isNixOS = false; };

      nixosModules.default = mkAxiosMonitorModule { isNixOS = true; };

      dmsPlugin = self;
    };
}
