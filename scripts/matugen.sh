#!/usr/bin/env bash

INPUT_SOURCE="$1"
SHELL_DIR="$2"
CONFIG_DIR="$3"
MODE="$4"
IS_LIGHT="$5"
ICON_THEME="$6"

if [ -z "$SHELL_DIR" ] || [ -z "$CONFIG_DIR" ]; then
    echo "Usage: $0 <input_source> <shell_dir> <config_dir> <mode> [is_light] [icon_theme]" >&2
    echo "  input_source: wallpaper path for 'generate' mode, hex color for 'generate-color' mode" >&2
    exit 1
fi
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
        
        if [ "$icon_theme" != "System Default" ] && [ -n "$icon_theme" ]; then
            dconf write /org/gnome/desktop/interface/icon-theme "\"$icon_theme\""
            echo "Set icon-theme to: $icon_theme"
        fi
    elif command -v gsettings >/dev/null 2>&1; then
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

if [ "$MODE" = "generate" ]; then
    if [ ! -f "$INPUT_SOURCE" ]; then
        echo "Wallpaper file not found: $INPUT_SOURCE" >&2
        exit 1
    fi
elif [ "$MODE" = "generate-color" ]; then
    if ! echo "$INPUT_SOURCE" | grep -qE '^#[0-9A-Fa-f]{6}$'; then
        echo "Invalid hex color format: $INPUT_SOURCE (expected format: #RRGGBB)" >&2
        exit 1
    fi
fi

if [ ! -d "$SHELL_DIR" ]; then
    echo "Shell directory not found: $SHELL_DIR" >&2
    exit 1
fi

mkdir -p "$CONFIG_DIR/gtk-3.0" "$CONFIG_DIR/gtk-4.0" "$CONFIG_DIR/qt5ct/colors" "$CONFIG_DIR/qt6ct/colors" "$(dirname "$CONFIG_DIR")/.local/share/color-schemes"

cd "$SHELL_DIR" || exit 1

if [ ! -f "matugen/matugen-default-cfg.toml" ]; then
    echo "Config file not found: $SHELL_DIR/matugen/matugen-default-cfg.toml" >&2
    exit 1
fi

TEMP_CONFIG="/tmp/matugen-config-$$.toml"
cp "matugen/matugen-default-cfg.toml" "$TEMP_CONFIG"

if [ "$IS_LIGHT" = "true" ]; then
    COLLOID_TEMPLATE="$SHELL_DIR/matugen/templates/gtk3-colloid-light.css"
else
    COLLOID_TEMPLATE="$SHELL_DIR/matugen/templates/gtk3-colloid-dark.css"
fi

sed -i "/\[templates\.gtk3\]/,/^\[/ s|input_path = './matugen/templates/gtk-colors.css'|input_path = '$COLLOID_TEMPLATE'|" "$TEMP_CONFIG"
sed -i "s|input_path = './matugen/templates/|input_path = '$SHELL_DIR/matugen/templates/|g" "$TEMP_CONFIG"

MATUGEN_MODE=""
if [ "$IS_LIGHT" = "true" ]; then
    MATUGEN_MODE="-m light"
else
    MATUGEN_MODE="-m dark"
fi

if [ "$MODE" = "generate" ]; then
    echo "Generating matugen themes from wallpaper: $INPUT_SOURCE"
    echo "Using config: $TEMP_CONFIG with template: $COLLOID_TEMPLATE"
    
    if ! matugen -v -c "$TEMP_CONFIG" image "$INPUT_SOURCE" $MATUGEN_MODE; then
        echo "Failed to generate themes with matugen" >&2
        rm -f "$TEMP_CONFIG"
        exit 1
    fi
elif [ "$MODE" = "generate-color" ]; then
    echo "Generating matugen themes from color: $INPUT_SOURCE"
    echo "Using config: $TEMP_CONFIG with template: $COLLOID_TEMPLATE"
    
    if ! matugen -v -c "$TEMP_CONFIG" color hex "$INPUT_SOURCE" $MATUGEN_MODE; then
        echo "Failed to generate themes with matugen" >&2
        rm -f "$TEMP_CONFIG"
        exit 1
    fi
fi

TEMP_CONTENT_CONFIG="/tmp/matugen-content-config-$$.toml"
cp "matugen/matugen-content-cfg.toml" "$TEMP_CONTENT_CONFIG"
sed -i "s|input_path = './matugen/templates/|input_path = '$SHELL_DIR/matugen/templates/|g" "$TEMP_CONTENT_CONFIG"
if [ "$IS_LIGHT" = "true" ]; then
    sed -i '/\[templates\.ghostty-dark\]/,/^$/d' "$TEMP_CONTENT_CONFIG"
else
    sed -i '/\[templates\.ghostty-light\]/,/^$/d' "$TEMP_CONTENT_CONFIG"
fi

if [ "$MODE" = "generate" ]; then
    matugen -v -c "$TEMP_CONTENT_CONFIG" -t scheme-fidelity image "$INPUT_SOURCE" $MATUGEN_MODE
elif [ "$MODE" = "generate-color" ]; then
    matugen -v -c "$TEMP_CONTENT_CONFIG" -t scheme-fidelity color hex "$INPUT_SOURCE" $MATUGEN_MODE
fi

rm -f "$TEMP_CONFIG" "$TEMP_CONTENT_CONFIG"

echo "Updating system theme preferences..."

color_scheme=""
if [ "$IS_LIGHT" = "true" ]; then
    color_scheme="prefer-light"
else
    color_scheme="prefer-dark"
fi

update_theme_settings "$color_scheme" "$ICON_THEME"

echo "Matugen theme generation completed successfully"
echo "dank-colors.css files generated in $CONFIG_DIR/gtk-3.0/ and $CONFIG_DIR/gtk-4.0/"
echo "Qt color schemes generated in $CONFIG_DIR/qt5ct/colors/ and $CONFIG_DIR/qt6ct/colors/"