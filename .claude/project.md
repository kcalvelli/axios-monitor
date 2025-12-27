# axiOS Monitor

## Project Overview

**axiOS Monitor** is a DankMaterialShell (DMS) plugin for monitoring axiOS systems with integrated rebuild and update tracking capabilities. This is a specialized fork of [nix-monitor](https://github.com/antonjah/nix-monitor) by Anton Andersson, customized exclusively for the [axiOS](https://github.com/kcalvelli/axios) modular NixOS distribution.

**Important**: This plugin is NOT compatible with standard NixOS installations - it is designed specifically for axiOS systems.

## Technology Stack

- **UI Framework**: QML (Qt Modeling Language) - declarative language for building user interfaces
- **Package Management**: Nix flakes for distribution and configuration
- **Integration**: DankMaterialShell plugin system
- **Languages**: QML, JavaScript, Nix
- **Runtime**: Quickshell (QML engine used by DankMaterialShell)

## Architecture

### Core Components

1. **NixMonitor.qml** (main component)
   - Bar widget display (horizontal/vertical pills)
   - Popout panel with detailed stats and controls
   - Process management for system commands
   - Real-time console output display
   - Update checking logic

2. **NixMonitorSettings.qml** (settings UI)
   - User-configurable options
   - Display toggles
   - Update intervals
   - Warning thresholds

3. **flake.nix** (Nix configuration)
   - Home-manager module
   - NixOS module
   - Default command configurations
   - Config file generation

4. **plugin.json** (metadata)
   - Plugin identification
   - Capability declarations
   - Component paths

### Configuration System

The plugin uses a dual-configuration approach:

1. **Nix-level config** (`flake.nix`):
   - Defines commands via `programs.axios-monitor.*` options
   - Generates `config.json` at build time
   - Provides sensible defaults for axiOS

2. **Runtime config** (QML):
   - Loads `config.json` on startup
   - Reads user preferences from plugin data
   - Manages UI state and intervals

### Key Features

#### Monitoring
- **Generation Count**: Tracks NixOS system generations
- **Store Size**: Monitors Nix store disk usage with threshold warnings
- **Update Status**: Compares local vs remote axiOS revisions

#### Actions
- **Rebuild Switch**: `nixos-rebuild switch` - activates immediately
- **Rebuild Boot**: `nixos-rebuild boot` - activates on next boot
- **Update Flake**: Updates flake.lock dependencies
- **Garbage Collection**: Runs `nix-collect-garbage -d`

#### UI Components
- **Bar Widget**: Compact display showing generations, store size, and update status
- **Popout Panel**: Detailed view with stats cards, action buttons, and console
- **Real-time Console**: Live stdout/stderr from running operations
- **Visual Warnings**: Color-coded indicators when thresholds are exceeded

## axiOS-Specific Features

Unlike generic nix-monitor, this fork includes:

1. **Two Rebuild Buttons**: Separate switch and boot operations
2. **axiOS Version Tracking**: Monitors `axios` flake input instead of nixpkgs
3. **Zero Configuration**: Auto-configured when using axiOS desktop module
4. **Smart Flake Detection**: Uses `$FLAKE_PATH` or defaults to `~/.config/nixos_config`
5. **GUI Password Prompts**: Uses `sudo -A` with `SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass`

## File Structure

```
axios-monitor/
├── .claude/
│   └── project.md              # This file
├── assets/
│   └── scrot.png              # Screenshot
├── flake.nix                  # Nix flake with HM/NixOS modules
├── flake.lock                 # Locked dependencies
├── plugin.json                # DMS plugin metadata
├── NixMonitor.qml             # Main plugin component
├── NixMonitorSettings.qml     # Settings UI component
├── README.md                  # User documentation
├── LICENSE                    # MIT license
└── CODE_OF_ETHICS.md          # Ethical guidelines
```

## Configuration Options

### Nix Module Options (`programs.axios-monitor`)

**Required Commands** (all have defaults):
- `rebuildCommand` - Command for `nixos-rebuild switch`
- `rebuildBootCommand` - Command for `nixos-rebuild boot`
- `localRevisionCommand` - Get local axiOS revision from flake.lock
- `remoteRevisionCommand` - Get remote axiOS revision from GitHub
- `updateFlakeCommand` - Update flake.lock

**Optional Commands** (with defaults):
- `generationsCommand` - Count system generations
- `storeSizeCommand` - Get Nix store size
- `gcCommand` - Run garbage collection
- `updateInterval` - Statistics refresh interval (default: 300s)

### User Settings (via DMS Settings UI)

- `showGenerations` - Toggle generation count display
- `showStoreSize` - Toggle store size display
- `updateInterval` - Refresh interval (60-3600s)
- `gcThresholdGB` - Warning threshold (10-200 GB)
- `checkUpdates` - Enable axiOS update checking
- `updateCheckInterval` - Update check interval (300-86400s)

## Process Management

The plugin uses QML `Process` components to execute commands:

- `configLoader` - Loads config.json on startup
- `generationCountProcess` - Counts system generations
- `storeSizeProcess` - Measures store size
- `rebuildProcess` - Runs nixos-rebuild switch
- `rebuildBootProcess` - Runs nixos-rebuild boot
- `updateFlakeProcess` - Updates flake.lock
- `garbageCollectProcess` - Runs GC
- `localRevisionProcess` - Gets local axiOS revision
- `remoteRevisionProcess` - Gets remote axiOS revision

All processes capture stdout/stderr and display in the console output.

## Development Workflow

### Installation for Testing
1. Build with Nix: Plugin is distributed via axiOS flake
2. Installed to `~/.config/DankMaterialShell/plugins/AxiosMonitor/` (home-manager)
3. Or `/etc/xdg/quickshell/dms-plugins/AxiosMonitor` (NixOS module)

### Making Changes
1. Edit QML files directly
2. **Important**: Clear QML cache after changes: `rm -rf ~/.cache/quickshell/qmlcache/`
3. Restart DMS: `dms restart` or re-login
4. Check DMS logs for errors

### Testing
- Use DMS Settings → Plugins to toggle plugin on/off
- Monitor console output for debugging
- Check `~/.config/DankMaterialShell/plugins/AxiosMonitor/config.json` for config issues

## Dependencies

### System Requirements
- axiOS (required - this is axiOS-specific)
- DankMaterialShell >= 1.0.0
- Nix package manager
- bash (for command execution)
- git (for update checking)
- jq (for parsing flake.lock)
- ksshaskpass (for GUI password prompts)

### QML Imports
- QtQuick - Core QML module
- Quickshell - DMS shell integration
- Quickshell.Io - Process management
- qs.Common - Theme and common components
- qs.Services - Toast notifications
- qs.Widgets - UI widgets
- qs.Modules.Plugins - Plugin system

## Common Issues

### QML Cache Problems
**Symptom**: Changes don't appear after rebuild
**Solution**: `rm -rf ~/.cache/quickshell/qmlcache/ && dms restart`

### Config Not Loading
**Symptom**: Commands show "No X command configured"
**Solution**: Check `config.json` exists and is valid JSON

### Update Status Shows N/A
**Symptom**: Version shows N/A or red error
**Solution**: Ensure flake.lock has `axios` input and network access to GitHub

### Rebuild Buttons Don't Work
**Symptom**: Nothing happens when clicking rebuild
**Solution**: Check sudo permissions and `$FLAKE_PATH` or `~/.config/nixos_config` exists

## Code Style Guidelines

### QML Conventions
- Use `root` for component ID
- Prefix properties with `root.` for clarity
- Use camelCase for property names
- Group related properties together
- Add descriptive comments for complex logic

### Nix Conventions
- Use `with lib;` for library functions
- Provide example values in option descriptions
- Use `mkOption` for all configurable options
- Set sensible defaults for optional values

## Links

- **axiOS**: https://github.com/kcalvelli/axios
- **DankMaterialShell**: https://github.com/AvengeMedia/DankMaterialShell
- **Original nix-monitor**: https://github.com/antonjah/nix-monitor
- **Author**: Keith Calvelli (https://github.com/kcalvelli)

## License

MIT License - See LICENSE file for details
Based on nix-monitor by Anton Andersson (also MIT licensed)
