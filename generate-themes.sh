#!/bin/bash

# System theme generation script for DankMaterialShell
# This script uses matugen to generate GTK and Qt themes from wallpaper or color

INPUT_SOURCE="$1"       # Wallpaper path or hex color (e.g., "#42a5f5")
SHELL_DIR="$2"
CONFIG_DIR="$3"         # Config directory (typically ~/.config)
MODE="$4"               # "generate", "generate-color", or "restore"
IS_LIGHT="$5"           # "true" for light mode, "false" for dark mode
ICON_THEME="$6"         # Icon theme name
GTK_THEMING="$7"        # "true" to enable GTK theming, "false" to disable
QT_THEMING="$8"         # "true" to enable Qt theming, "false" to disable

if [ -z "$SHELL_DIR" ] || [ -z "$CONFIG_DIR" ]; then
    echo "Usage: $0 <input_source> <shell_dir> <config_dir> [mode] [is_light] [icon_theme] [gtk_theming] [qt_theming]" >&2
    echo "  input_source: wallpaper path for 'generate' mode, hex color for 'generate-color' mode" >&2
    echo "  For restore mode, input_source can be empty" >&2
    exit 1
fi

# Default values
MODE=${MODE:-"generate"}
IS_LIGHT=${IS_LIGHT:-"false"}
ICON_THEME=${ICON_THEME:-"System Default"}
GTK_THEMING=${GTK_THEMING:-"false"}
QT_THEMING=${QT_THEMING:-"false"}

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
    local config_dir="$1"
    local is_light="$2"
    local shell_dir="$3"
    
    echo "Updating GTK CSS..."
    
    # GTK-3.0: Copy the appropriate template file
    local gtk3_css="$config_dir/gtk-3.0/gtk.css"
    if [ "$is_light" = "true" ]; then
        echo "Copying light GTK-3.0 template..."
        cp "$shell_dir/templates/gtk3-colloid-light.css" "$gtk3_css"
    else
        echo "Copying dark GTK-3.0 template..."
        cp "$shell_dir/templates/gtk3-colloid-dark.css" "$gtk3_css"
    fi
    echo "Updated GTK-3.0 CSS"
    
    # GTK-4.0: Use simplified import
    local gtk4_import="@import url(\"dank-colors.css\");"
    local gtk4_css="$config_dir/gtk-4.0/gtk.css"
    if [ -f "$gtk4_css" ]; then
        # Remove existing import if present
        sed -i '/^@import url.*dank-colors\.css.*);$/d' "$gtk4_css"
        # Add import at the top
        sed -i "1i\\$gtk4_import" "$gtk4_css"
    else
        # Create new gtk.css with import
        echo "$gtk4_import" > "$gtk4_css"
    fi
    echo "Updated GTK-4.0 CSS import"
}

update_qt_config() {
    local config_dir="$1"
    
    echo "Updating Qt configuration..."
    
    # Function to update Qt config files with color scheme settings
    update_qt_color_config() {
        local config_file="$1"
        local version="$2"
        local color_scheme_path="$(dirname "$config_dir")/.local/share/color-schemes/DankMatugen.colors"
        
        if [ -f "$config_file" ]; then
            # Use a simple sed approach to only update specific lines
            # First, check if the [Appearance] section exists
            if grep -q '^\[Appearance\]' "$config_file"; then
                # Update custom_palette if it exists, otherwise add it after [Appearance]
                if grep -q '^custom_palette=' "$config_file"; then
                    sed -i 's/^custom_palette=.*/custom_palette=true/' "$config_file"
                else
                    sed -i '/^\[Appearance\]/a custom_palette=true' "$config_file"
                fi
                
                # Update color_scheme_path if it exists, otherwise add it after [Appearance]
                if grep -q '^color_scheme_path=' "$config_file"; then
                    sed -i "s|^color_scheme_path=.*|color_scheme_path=$color_scheme_path|" "$config_file"
                else
                    sed -i "/^\[Appearance\]/a color_scheme_path=$color_scheme_path" "$config_file"
                fi
            else
                # Add [Appearance] section at the end with our settings
                echo "" >> "$config_file"
                echo "[Appearance]" >> "$config_file"
                echo "custom_palette=true" >> "$config_file"
                echo "color_scheme_path=$color_scheme_path" >> "$config_file"
            fi
        else
            # Create new config file with minimal settings
            printf '[Appearance]\ncustom_palette=true\ncolor_scheme_path=%s\n' "$color_scheme_path" > "$config_file"
        fi
    }
    
    # Update Qt5ct if available
    if command -v qt5ct >/dev/null 2>&1; then
        update_qt_color_config "$config_dir/qt5ct/qt5ct.conf" "5"
        echo "Updated Qt5ct configuration"
    fi
    
    # Update Qt6ct if available  
    if command -v qt6ct >/dev/null 2>&1; then
        update_qt_color_config "$config_dir/qt6ct/qt6ct.conf" "6"
        echo "Updated Qt6ct configuration"
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
if [ "$MODE" = "generate" ]; then
    if [ ! -f "$INPUT_SOURCE" ]; then
        echo "Wallpaper file not found: $INPUT_SOURCE" >&2
        exit 1
    fi
elif [ "$MODE" = "generate-color" ]; then
    # Validate hex color format
    if ! echo "$INPUT_SOURCE" | grep -qE '^#[0-9A-Fa-f]{6}$'; then
        echo "Invalid hex color format: $INPUT_SOURCE (expected format: #RRGGBB)" >&2
        exit 1
    fi
fi

if [ ! -d "$SHELL_DIR" ]; then
    echo "Shell directory not found: $SHELL_DIR" >&2
    exit 1
fi

# Create necessary directories
mkdir -p "$CONFIG_DIR/gtk-3.0" "$CONFIG_DIR/gtk-4.0" "$CONFIG_DIR/qt5ct/colors" "$CONFIG_DIR/qt6ct/colors" "$(dirname "$CONFIG_DIR")/.local/share/color-schemes"

# Change to shell directory where matugen-config.toml is located
cd "$SHELL_DIR" || exit 1

if [ ! -f "matugen-config.toml" ]; then
    echo "Config file not found: $SHELL_DIR/matugen-config.toml" >&2
    exit 1
fi

# Generate themes using matugen with verbose output
if [ "$MODE" = "generate" ]; then
    echo "Generating system themes from wallpaper: $INPUT_SOURCE"
    echo "Using config: $SHELL_DIR/matugen-config.toml"
    
    if ! matugen -v -c matugen-config.toml image "$INPUT_SOURCE"; then
        echo "Failed to generate system themes with matugen" >&2
        exit 1
    fi
elif [ "$MODE" = "generate-color" ]; then
    echo "Generating system themes from color: $INPUT_SOURCE"
    echo "Using config: $SHELL_DIR/matugen-config.toml"
    
    if ! matugen -v -c matugen-config.toml color hex "$INPUT_SOURCE" --type scheme-fidelity; then
        echo "Failed to generate system themes with matugen" >&2
        exit 1
    fi
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

# Update GTK CSS imports if GTK theming is enabled
if [ "$GTK_THEMING" = "true" ]; then
    update_gtk_css "$CONFIG_DIR" "$IS_LIGHT" "$SHELL_DIR"
    echo "GTK theming updated"
else
    echo "GTK theming disabled - skipping GTK CSS updates"
fi

# Update Qt configuration if Qt theming is enabled
if [ "$QT_THEMING" = "true" ]; then
    update_qt_config "$CONFIG_DIR"
    echo "Qt theming updated"
else
    echo "Qt theming disabled - skipping Qt configuration updates"
fi

echo "System theme files generated successfully"
if [ "$GTK_THEMING" = "true" ]; then
    echo "dank-colors.css files should be available in $CONFIG_DIR/gtk-3.0/ and $CONFIG_DIR/gtk-4.0/"
fi
if [ "$QT_THEMING" = "true" ]; then
    echo "Qt color schemes should be available in $CONFIG_DIR/qt5ct/colors/ and $CONFIG_DIR/qt6ct/colors/"
fi