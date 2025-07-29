#!/bin/bash

# System theme generation script for DankMaterialShell
# This script uses matugen to generate GTK and Qt themes from wallpaper

WALLPAPER_PATH="$1"
SHELL_DIR="$2"
MODE="$3"        # "generate" or "restore"
IS_LIGHT="$4"    # "true" for light mode, "false" for dark mode
ICON_THEME="$5"  # Icon theme name

if [ -z "$SHELL_DIR" ]; then
    echo "Usage: $0 <wallpaper_path> <shell_dir> [mode] [is_light] [icon_theme]" >&2
    echo "  For restore mode, wallpaper_path can be empty" >&2
    exit 1
fi

# Default values
MODE=${MODE:-"generate"}
IS_LIGHT=${IS_LIGHT:-"false"}
ICON_THEME=${ICON_THEME:-"System Default"}

update_theme_settings() {
    local color_scheme="$1"
    local icon_theme="$2"
    
    echo "Updating theme settings..."
    
    if command -v dconf >/dev/null 2>&1; then
        dconf write /org/gnome/desktop/interface/color-scheme "\"$color_scheme\""
        echo "Set color-scheme to: $color_scheme"
        
        # Update icon theme if specified and not System Default
        if [ "$icon_theme" != "System Default" ] && [ -n "$icon_theme" ]; then
            dconf write /org/gnome/desktop/interface/icon-theme "\"$icon_theme\""
            echo "Set icon-theme to: $icon_theme"
        fi
    elif command -v gsettings >/dev/null 2>&1; then
        # Fallback to gsettings
        gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
        echo "Set color-scheme to: $color_scheme"
        
        if [ "$icon_theme" != "System Default" ] && [ -n "$icon_theme" ]; then
            gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
            echo "Set icon-theme to: $icon_theme"
        fi
    else
        echo "Warning: Neither dconf nor gsettings available"
    fi
}

# Handle restore mode
if [ "$MODE" = "restore" ]; then
    echo "Restoring default theme settings..."
    
    color_scheme=""
    if [ "$IS_LIGHT" = "true" ]; then
        color_scheme="prefer-light"
    else
        color_scheme="prefer-dark"
    fi
    
    update_theme_settings "$color_scheme" "$ICON_THEME"
    echo "Theme settings restored"
    exit 0
fi

# Continue with generation mode
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

# Set color scheme and icon theme based on light/dark mode
echo "Updating system theme preferences..."

color_scheme=""
if [ "$IS_LIGHT" = "true" ]; then
    color_scheme="prefer-light"
else
    color_scheme="prefer-dark"
fi

update_theme_settings "$color_scheme" "$ICON_THEME"

echo "System theme files generated successfully"
echo "Colors.css files should be available in ~/.config/gtk-3.0/ and ~/.config/gtk-4.0/"