#!/bin/bash

# System theme generation script for DankMaterialShell
# This script uses matugen to generate GTK and Qt themes from wallpaper

WALLPAPER_PATH="$1"
SHELL_DIR="$2"

if [ -z "$WALLPAPER_PATH" ] || [ -z "$SHELL_DIR" ]; then
    echo "Usage: $0 <wallpaper_path> <shell_dir>" >&2
    exit 1
fi

if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "Wallpaper file not found: $WALLPAPER_PATH" >&2
    exit 1
fi

if [ ! -d "$SHELL_DIR" ]; then
    echo "Shell directory not found: $SHELL_DIR" >&2
    exit 1
fi

# Create necessary directories
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.config/qt5ct/colors ~/.config/qt6ct/colors ~/.local/share/color-schemes

# Change to shell directory where matugen-config.toml is located
cd "$SHELL_DIR" || exit 1

# Verify config file exists
if [ ! -f "matugen-config.toml" ]; then
    echo "Config file not found: $SHELL_DIR/matugen-config.toml" >&2
    exit 1
fi

# Generate themes using matugen with verbose output
echo "Generating system themes from wallpaper: $WALLPAPER_PATH"
echo "Using config: $SHELL_DIR/matugen-config.toml"

if ! matugen -v -c matugen-config.toml image "$WALLPAPER_PATH"; then
    echo "Failed to generate system themes with matugen" >&2
    exit 1
fi

echo "System theme files generated successfully"