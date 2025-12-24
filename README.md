# axiOS Monitor

A [DankMaterialShell](https://danklinux.com/) plugin for monitoring [axiOS](https://github.com/kcalvelli/axios) systems with integrated rebuild and update tracking capabilities.

> **Note:** This plugin is **exclusively designed for axiOS** and is not compatible with standard NixOS installations. For general NixOS monitoring, see the [original nix-monitor](https://github.com/antonjah/nix-monitor) by [Anton Andersson](https://github.com/antonjah).

## About This Fork

axiOS Monitor is a fork of [nix-monitor](https://github.com/antonjah/nix-monitor) with significant modifications to integrate seamlessly with the [axiOS](https://github.com/kcalvelli/axios) modular NixOS distribution. All credit for the original implementation goes to Anton Andersson.

### Key Differences from nix-monitor

This fork includes axiOS-specific modifications:

- **Two Rebuild Buttons**: Separate "Rebuild Switch" and "Rebuild Boot" buttons instead of a single rebuild action
- **axiOS Version Tracking**: Monitors axiOS library version from flake.lock instead of nixpkgs
- **Zero Configuration**: Automatically configured when using axiOS desktop module
- **Smart Flake Detection**: Matches axiOS fish function behavior (`$FLAKE_PATH` or `~/.config/nixos_config`)
- **Required Commands**: Both switch and boot rebuild commands must be configured

**This plugin will NOT work correctly on non-axiOS systems** as it expects:
- axiOS as a flake input in your configuration
- axiOS-specific module structure
- Flake-based NixOS configuration

## Features

### Bar Widget Display
- **Generation count** - Shows NixOS system generations
- **Store size** - Shows Nix store disk usage
- **Update status** - Check icon shows axiOS update availability:
  - Green: axiOS is up-to-date with upstream
  - Yellow: axiOS update available
  - Red: Could not fetch version info
- **Visual warnings** - Icon and text turn red when store exceeds threshold
- **Auto-updates** - Configurable refresh interval (default: 5 minutes)

### Detailed Popout Panel
Click the widget to open a detailed view with:
- **Summary cards** - Large stat cards for generation count and store size
- **axiOS update status** - Shows local and remote axiOS revisions with update availability
- **Warning banner** - Appears when store size exceeds threshold
- **Real-time console** - View command output as it runs
- **Action buttons**:
  - **Refresh** - Update statistics immediately
  - **Rebuild Switch** - Run `nixos-rebuild switch` (activates immediately)
  - **Rebuild Boot** - Run `nixos-rebuild boot` (activates on next boot)
  - **GC** - Run garbage collection
  - **Cancel** - Stop running operation
- **Clear button** - Hide console output

### Configurable Settings
Access via DMS Settings → Plugins → axiOS Monitor:
- Show/hide generation count
- Show/hide store size
- Update interval (60-3600 seconds)
- Warning threshold (10-200 GB)
- Enable/disable axiOS update checking
- Update check interval (300-86400 seconds)

## Installation

### For axiOS Users (Automatic)

If you're using [axiOS](https://github.com/kcalvelli/axios) with the desktop module enabled (`modules.desktop = true`), **this plugin is automatically configured** - no additional setup required!

The plugin is included as part of the axiOS desktop module and will:
- Auto-detect your flake location via `$FLAKE_PATH` or default to `~/.config/nixos_config`
- Configure rebuild commands matching axiOS fish functions
- Track axiOS library version for updates
- Enable all features with sensible defaults

Simply rebuild your system and the widget will appear in DMS.

### Manual Configuration (Advanced)

If you need custom configuration, you can override the defaults in your home-manager configuration:

```nix
{
  programs.axios-monitor = {
    enable = true;

    # Override rebuild commands if needed
    rebuildCommand = [
      "bash" "-c"
      ''
        FLAKE_PATH=''${FLAKE_PATH:-~/.config/nixos_config}
        sudo nixos-rebuild switch --flake "$FLAKE_PATH#$(hostname)" 2>&1
      ''
    ];

    rebuildBootCommand = [
      "bash" "-c"
      ''
        FLAKE_PATH=''${FLAKE_PATH:-~/.config/nixos_config}
        sudo nixos-rebuild boot --flake "$FLAKE_PATH#$(hostname)" 2>&1
      ''
    ];

    # Customize update interval
    updateInterval = 300; # 5 minutes
  };
}
```

### Activation

1. Rebuild your axiOS configuration: `sudo nixos-rebuild switch`
2. Restart DMS: `dms restart` (or log out and back in)
3. Open DMS Settings → Plugins
4. Click "Scan for Plugins"
5. Toggle "axiOS Monitor" ON
6. Add to your DankBar layout

### Updating

The plugin updates automatically when you update your axiOS flake input:

```bash
# Update axiOS (includes axios-monitor)
nix flake update axios

# Rebuild
sudo nixos-rebuild switch

# Clear QML cache and restart DMS
rm -rf ~/.cache/quickshell/qmlcache/
dms restart
```

**Note:** Due to QML disk caching with Nix symlinks, you must clear the QML cache after plugin updates for changes to take effect.

## Usage

### Bar Widget
- The widget shows in your DankBar with an icon, generation count, and store size
- Click icon shows axiOS update status (green/yellow/red)
- Click to open the detailed popout panel
- Colors change to red when store exceeds threshold

### Popout Panel
- **Refresh** - Updates all statistics and checks for axiOS updates
- **Rebuild Switch** - Builds and activates new generation immediately (like `rebuild-switch` fish function)
- **Rebuild Boot** - Builds new generation for next boot (like `rebuild-boot` fish function)
- **GC** - Runs garbage collection (`nix-collect-garbage -d`)

### Console Output
- Appears automatically when running rebuild or GC operations
- Shows real-time stdout/stderr from nixos-rebuild
- Auto-scrolls to latest output
- Click "Clear" to hide

## Configuration Options

For advanced users, the following options are available via `programs.axios-monitor`:

**Required:**
- `rebuildCommand` - Command for `nixos-rebuild switch` **(REQUIRED)**
- `rebuildBootCommand` - Command for `nixos-rebuild boot` **(REQUIRED)**
- `localRevisionCommand` - Command to get local axiOS revision from flake.lock **(REQUIRED)**
- `remoteRevisionCommand` - Command to get remote axiOS revision from GitHub **(REQUIRED)**

**Optional (with defaults):**
- `generationsCommand` - Command to count NixOS generations
  Default: `nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l`
- `storeSizeCommand` - Command to get Nix store size
  Default: `du -sh /nix/store | cut -f1`
- `gcCommand` - Command for garbage collection
  Default: `nix-collect-garbage -d`
- `updateInterval` - Statistics refresh interval in seconds
  Default: `300` (5 minutes)

## Requirements

- [axiOS](https://github.com/kcalvelli/axios) - This plugin ONLY works with axiOS
- [DankMaterialShell](https://danklinux.com/) >= 1.0.0
- Nix package manager
- bash (for rebuild commands)
- git (for update checking)
- jq (for parsing flake.lock)

## Troubleshooting

### Widget doesn't appear in DMS
1. Ensure you have `modules.desktop = true` in your axiOS configuration
2. Rebuild your system: `sudo nixos-rebuild switch`
3. Restart DMS: `dms restart`
4. Check DMS Settings → Plugins and ensure "axiOS Monitor" is toggled ON

### Update status shows red/N/A
- Check that your flake.lock contains an `axios` input
- Verify network connectivity to github.com
- Ensure jq is installed (should be automatic with axiOS)

### Rebuild buttons don't work
- Check that your user has sudo permissions for `nixos-rebuild`
- Verify `$FLAKE_PATH` points to your flake directory, or ensure `~/.config/nixos_config` exists
- Check console output for error messages

### Version shows N/A
- Ensure your axiOS configuration imports axios as a flake input
- Verify flake.lock has `axios.locked.rev` field
- Check that git is installed and can access github.com

## Links

- **axiOS**: https://github.com/kcalvelli/axios
- **DankMaterialShell**: https://github.com/AvengeMedia/DankMaterialShell
- **Original nix-monitor**: https://github.com/antonjah/nix-monitor

## Credits

- **Original Implementation**: [Anton Andersson](https://github.com/antonjah) - [nix-monitor](https://github.com/antonjah/nix-monitor)
- **axiOS Fork**: [Keith Calvelli](https://github.com/kcalvelli) - axiOS-specific modifications

## License

MIT License

Copyright (c) 2023 Keith Calvelli

Based on nix-monitor by Anton Andersson, also MIT licensed.

See [LICENSE](LICENSE) file for details.
