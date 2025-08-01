#!/bin/bash

# System theme generation script for DankMaterialShell
# This script uses matugen to generate GTK and Qt themes from wallpaper

WALLPAPER_PATH="$1"
SHELL_DIR="$2"
HOME_DIR="$3"
MODE="$4"        # "generate" or "restore"
IS_LIGHT="$5"    # "true" for light mode, "false" for dark mode
ICON_THEME="$6"  # Icon theme name

if [ -z "$SHELL_DIR" ] || [ -z "$HOME_DIR" ]; then
    echo "Usage: $0 <wallpaper_path> <shell_dir> <home_dir> [mode] [is_light] [icon_theme]" >&2
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

update_gtk_css() {
    local home_dir="$1"
    local import_line="@import url(\"$home_dir/.config/gtk-4.0/dank-colors.css\");"
    
    echo "Updating GTK CSS imports..."
    
    # Update GTK-4.0
    local gtk4_css="$home_dir/.config/gtk-4.0/gtk.css"
    if [ -f "$gtk4_css" ]; then
        # Remove existing import if present
        sed -i '/^@import url.*dank-colors\.css.*);$/d' "$gtk4_css"
        # Add import at the top
        sed -i "1i\\$import_line" "$gtk4_css"
    else
        # Create new gtk.css with import
        echo "$import_line" > "$gtk4_css"
    fi
    echo "Updated GTK-4.0 CSS import"
    
    # Update GTK-3.0 with its own path
    local gtk3_import="@import url(\"$home_dir/.config/gtk-3.0/dank-colors.css\");"
    local gtk3_css="$home_dir/.config/gtk-3.0/gtk.css"
    if [ -f "$gtk3_css" ]; then
        # Remove existing import if present
        sed -i '/^@import url.*dank-colors\.css.*);$/d' "$gtk3_css"
        # Add import at the top
        sed -i "1i\\$gtk3_import" "$gtk3_css"
    else
        # Create new gtk.css with import
        echo "$gtk3_import" > "$gtk3_css"
    fi
    echo "Updated GTK-3.0 CSS import"
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
mkdir -p "$HOME_DIR/.config/gtk-3.0" "$HOME_DIR/.config/gtk-4.0" "$HOME_DIR/.config/qt5ct/colors" "$HOME_DIR/.config/qt6ct/colors" "$HOME_DIR/.local/share/color-schemes"

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

# Update GTK CSS imports
update_gtk_css "$HOME_DIR"

echo "System theme files generated successfully"
echo "dank-colors.css files should be available in $HOME_DIR/.config/gtk-3.0/ and $HOME_DIR/.config/gtk-4.0/"