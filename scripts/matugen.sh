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

build_dynamic_config() {
    local temp_config="$1"
    local is_light="$2"
    local shell_dir="$3"
    
    echo "Building dynamic matugen configuration..."
    
    cat "$shell_dir/matugen/configs/base.toml" > "$temp_config"
    echo "" >> "$temp_config"
    
    if command -v niri >/dev/null 2>&1; then
        echo "  - Including niri config (niri found)"
        cat "$shell_dir/matugen/configs/niri.toml" >> "$temp_config"
        echo "" >> "$temp_config"
    else
        echo "  - Skipping niri config (niri not found)"
    fi
    
    if command -v qt5ct >/dev/null 2>&1; then
        echo "  - Including qt5ct config (qt5ct found)"
        cat "$shell_dir/matugen/configs/qt5ct.toml" >> "$temp_config"
        echo "" >> "$temp_config"
    else
        echo "  - Skipping qt5ct config (qt5ct not found)"
    fi
    
    if command -v qt6ct >/dev/null 2>&1; then
        echo "  - Including qt6ct config (qt6ct found)"
        cat "$shell_dir/matugen/configs/qt6ct.toml" >> "$temp_config"
        echo "" >> "$temp_config"
    else
        echo "  - Skipping qt6ct config (qt6ct not found)"
    fi
    
    if [ "$is_light" = "true" ]; then
        COLLOID_TEMPLATE="$shell_dir/matugen/templates/gtk3-colloid-light.css"
    else
        COLLOID_TEMPLATE="$shell_dir/matugen/templates/gtk3-colloid-dark.css"
    fi
    
    sed -i "/\[templates\.gtk3\]/,/^$/ s|input_path = './matugen/templates/gtk-colors.css'|input_path = '$COLLOID_TEMPLATE'|" "$temp_config"
    sed -i "s|input_path = './matugen/templates/|input_path = '$shell_dir/matugen/templates/|g" "$temp_config"
}

build_content_config() {
    local temp_config="$1"
    local is_light="$2"
    local shell_dir="$3"
    
    echo "Building dynamic content configuration..."
    
    echo "[config]" > "$temp_config"
    echo "" >> "$temp_config"
    
    if command -v ghostty >/dev/null 2>&1; then
        echo "  - Including ghostty config (ghostty found)"
        cat "$shell_dir/matugen/configs/ghostty.toml" >> "$temp_config"
        if [ "$is_light" = "true" ]; then
            sed -i '/\[templates\.ghostty-dark\]/,/^$/d' "$temp_config"
        else
            sed -i '/\[templates\.ghostty-light\]/,/^$/d' "$temp_config"
        fi
        sed -i "s|input_path = './matugen/templates/|input_path = '$shell_dir/matugen/templates/|g" "$temp_config"
        echo "" >> "$temp_config"
    else
        echo "  - Skipping ghostty config (ghostty not found)"
    fi
    
    if command -v dgop >/dev/null 2>&1; then
        echo "  - Including dgop config (dgop found)"
        cat "$shell_dir/matugen/configs/dgop.toml" >> "$temp_config"
        sed -i "s|input_path = './matugen/templates/|input_path = '$shell_dir/matugen/templates/|g" "$temp_config"
        echo "" >> "$temp_config"
    else
        echo "  - Skipping dgop config (dgop not found)"
    fi
    
    if command -v fastfetch >/dev/null 2>&1; then
        echo "  - Including fastfetch config (fastfetch found)"
        cat "$shell_dir/matugen/configs/fastfetch.toml" >> "$temp_config"
        sed -i "s|input_path = './matugen/templates/|input_path = '$shell_dir/matugen/templates/|g" "$temp_config"
        echo "" >> "$temp_config"
    else
        echo "  - Skipping fastfetch config (fastfetch not found)"
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

cd "$SHELL_DIR" || exit 1

if [ ! -d "matugen/configs" ]; then
    echo "Config directory not found: $SHELL_DIR/matugen/configs" >&2
    exit 1
fi

TEMP_CONFIG="/tmp/matugen-config-$$.toml"
build_dynamic_config "$TEMP_CONFIG" "$IS_LIGHT" "$SHELL_DIR"

MATUGEN_MODE=""
if [ "$IS_LIGHT" = "true" ]; then
    MATUGEN_MODE="-m light"
else
    MATUGEN_MODE="-m dark"
fi

if [ "$MODE" = "generate" ]; then
    echo "Generating matugen themes from wallpaper: $INPUT_SOURCE"
    echo "Using dynamic config: $TEMP_CONFIG"
    
    if ! matugen -v -c "$TEMP_CONFIG" image "$INPUT_SOURCE" $MATUGEN_MODE; then
        echo "Failed to generate themes with matugen" >&2
        rm -f "$TEMP_CONFIG"
        exit 1
    fi
elif [ "$MODE" = "generate-color" ]; then
    echo "Generating matugen themes from color: $INPUT_SOURCE"
    echo "Using dynamic config: $TEMP_CONFIG"
    
    if ! matugen -v -c "$TEMP_CONFIG" color hex "$INPUT_SOURCE" $MATUGEN_MODE; then
        echo "Failed to generate themes with matugen" >&2
        rm -f "$TEMP_CONFIG"
        exit 1
    fi
fi

TEMP_CONTENT_CONFIG="/tmp/matugen-content-config-$$.toml"
build_content_config "$TEMP_CONTENT_CONFIG" "$IS_LIGHT" "$SHELL_DIR"

if [ -s "$TEMP_CONTENT_CONFIG" ] && grep -q '\[templates\.' "$TEMP_CONTENT_CONFIG"; then
    echo "Running content-specific theme generation..."
    if [ "$MODE" = "generate" ]; then
        matugen -v -c "$TEMP_CONTENT_CONFIG" -t scheme-fidelity image "$INPUT_SOURCE" $MATUGEN_MODE
    elif [ "$MODE" = "generate-color" ]; then
        matugen -v -c "$TEMP_CONTENT_CONFIG" -t scheme-fidelity color hex "$INPUT_SOURCE" $MATUGEN_MODE
    fi
else
    echo "No content-specific tools found, skipping content generation"
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
echo "Generated configs for detected tools:"
[ -f "$CONFIG_DIR/gtk-3.0/dank-colors.css" ] && echo "  - GTK 3/4 themes"
[ -f "$(eval echo ~/.local/share/color-schemes/DankMatugen.colors)" ] && echo "  - KDE color scheme"
command -v niri >/dev/null 2>&1 && [ -f "$CONFIG_DIR/niri/dankshell-colors.kdl" ] && echo "  - Niri compositor"
command -v qt5ct >/dev/null 2>&1 && [ -f "$CONFIG_DIR/qt5ct/colors/matugen.conf" ] && echo "  - Qt5ct themes"
command -v qt6ct >/dev/null 2>&1 && [ -f "$CONFIG_DIR/qt6ct/colors/matugen.conf" ] && echo "  - Qt6ct themes"
command -v ghostty >/dev/null 2>&1 && [ -f "$CONFIG_DIR/ghostty/config-dankcolors" ] && echo "  - Ghostty terminal"
command -v dgop >/dev/null 2>&1 && [ -f "$CONFIG_DIR/dgop/colors.json" ] && echo "  - Dgop colors"
command -v fastfetch >/dev/null 2>&1 && [ -f "$CONFIG_DIR/fastfetch/colors.jsonc" ] && echo "  - Fastfetch colors"