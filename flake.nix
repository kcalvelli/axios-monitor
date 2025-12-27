{
  description = "axiOS Monitor - A DankMaterialShell plugin for monitoring axiOS systems";

  outputs =
    { self, nixpkgs, ... }:
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
              updateFlakeCommand = cfg.updateFlakeCommand;
            }
          );

          # Build a complete plugin directory with all files including config.json
          pluginDir = pkgs.runCommand "axios-monitor-plugin" { } ''
            mkdir -p $out
            # Copy all plugin files from source
            cp -r ${self}/* $out/
            # Add the generated config.json
            cp ${configFile} $out/config.json
            # Make everything readable
            chmod -R +r $out
          '';
        in
        {
          options.programs.axios-monitor = {
            enable = mkEnableOption "axiOS Monitor plugin for DankMaterialShell";

            generationsCommand = mkOption {
              type = types.listOf types.str;
              default = [
                "sh"
                "-c"
                "ls -d /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l"
              ];
              description = "Command to count Nix system generations";
              example = literalExpression ''
                [ "sh" "-c" "ls -d /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l" ]
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
              default = [
                "bash"
                "-c"
                ''
                  export SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass
                  FLAKE_PATH=''${FLAKE_PATH:-$HOME/.config/nixos_config}
                  sudo -A nixos-rebuild switch --flake "$FLAKE_PATH#$(hostname)" 2>&1
                ''
              ];
              description = "Command to run for system rebuild switch";
              example = literalExpression ''
                [ "bash" "-c" "export SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass; sudo -A nixos-rebuild switch --flake ~/.config/nixos_config#hostname 2>&1" ]
              '';
            };

            rebuildBootCommand = mkOption {
              type = types.listOf types.str;
              default = [
                "bash"
                "-c"
                ''
                  export SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass
                  FLAKE_PATH=''${FLAKE_PATH:-$HOME/.config/nixos_config}
                  sudo -A nixos-rebuild boot --flake "$FLAKE_PATH#$(hostname)" 2>&1
                ''
              ];
              description = "Command to run for system rebuild boot";
              example = literalExpression ''
                [ "bash" "-c" "export SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass; sudo -A nixos-rebuild boot --flake ~/.config/nixos_config#hostname 2>&1" ]
              '';
            };

            gcCommand = mkOption {
              type = types.listOf types.str;
              default = [
                "bash"
                "-c"
                ''
                  export SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass
                  echo "Running system-level garbage collection..."
                  sudo -A nix-collect-garbage -d 2>&1
                  echo ""
                  echo "Running user-level garbage collection..."
                  nix-collect-garbage -d 2>&1
                ''
              ];
              description = "Command to run for garbage collection at both system and user level";
              example = literalExpression ''
                [ "bash" "-c" "export SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass; sudo -A nix-collect-garbage -d && nix-collect-garbage -d 2>&1" ]
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
              default = [
                "bash"
                "-c"
                ''
                  FLAKE_PATH=''${FLAKE_PATH:-$HOME/.config/nixos_config}
                  jq -r '.nodes.axios.locked.rev // "N/A"' "$FLAKE_PATH/flake.lock" 2>/dev/null | cut -c 1-7 || echo 'N/A'
                ''
              ];
              description = "Command to get local axiOS revision from flake.lock";
              example = literalExpression ''
                [ "sh" "-c" "jq -r '.nodes.axios.locked.rev' ~/.config/nixos_config/flake.lock | cut -c 1-7" ]
              '';
            };

            remoteRevisionCommand = mkOption {
              type = types.listOf types.str;
              default = [
                "bash"
                "-c"
                "git ls-remote https://github.com/kcalvelli/axios.git master 2>/dev/null | cut -c 1-7 || echo 'N/A'"
              ];
              description = "Command to get remote axiOS revision from GitHub";
              example = literalExpression ''
                [ "sh" "-c" "git ls-remote https://github.com/kcalvelli/axios.git master | cut -c 1-7" ]
              '';
            };

            updateFlakeCommand = mkOption {
              type = types.listOf types.str;
              default = [
                "bash"
                "-c"
                ''
                  FLAKE_PATH=''${FLAKE_PATH:-$HOME/.config/nixos_config}
                  nix flake update --flake "$FLAKE_PATH" 2>&1
                ''
              ];
              description = "Command to update the flake.lock file";
              example = literalExpression ''
                [ "bash" "-c" "nix flake update --flake ~/.config/nixos_config 2>&1" ]
              '';
            };
          };

          config = mkIf cfg.enable (mkMerge [
            (
              if isNixOS then
                {
                  environment.etc."xdg/quickshell/dms-plugins/AxiosMonitor" = {
                    source = pluginDir;
                  };
                }
              else
                {
                  home.file.".config/DankMaterialShell/plugins/AxiosMonitor" = {
                    source = pluginDir;
                    recursive = true;
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
