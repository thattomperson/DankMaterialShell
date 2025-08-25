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
        sed -i "s|input_path = './matugen/templates/|input_path = '$shell_dir/matugen/templates/|g" "$temp_config"
        echo "" >> "$temp_config"
    else
        echo "  - Skipping ghostty config (ghostty not found)"
    fi
    
    if command -v kitty >/dev/null 2>&1; then
        echo "  - Including kitty config (kitty found)"
        cat "$shell_dir/matugen/configs/kitty.toml" >> "$temp_config"
        sed -i "s|input_path = './matugen/templates/|input_path = '$shell_dir/matugen/templates/|g" "$temp_config"
        echo "" >> "$temp_config"
    else
        echo "  - Skipping kitty config (kitty not found)"
    fi
    
    if command -v dgop >/dev/null 2>&1; then
        echo "  - Including dgop config (dgop found)"
        cat "$shell_dir/matugen/configs/dgop.toml" >> "$temp_config"
        sed -i "s|input_path = './matugen/templates/|input_path = '$shell_dir/matugen/templates/|g" "$temp_config"
        echo "" >> "$temp_config"
    else
        echo "  - Skipping dgop config (dgop not found)"
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

EXTRACTED_PRIMARY=""

if [ "$MODE" = "generate" ]; then
    echo "Generating matugen themes from wallpaper: $INPUT_SOURCE"
    echo "Using dynamic config: $TEMP_CONFIG"
    
    # Generate templates (no JSON needed for main themes)
    if ! matugen -c "$TEMP_CONFIG" image "$INPUT_SOURCE" $MATUGEN_MODE; then
        echo "Failed to generate themes with matugen" >&2
        rm -f "$TEMP_CONFIG"
        exit 1
    fi
elif [ "$MODE" = "generate-color" ]; then
    echo "Generating matugen themes from color: $INPUT_SOURCE"
    echo "Using dynamic config: $TEMP_CONFIG"
    
    # Generate templates, for color mode we already have the primary
    if ! matugen -c "$TEMP_CONFIG" color hex "$INPUT_SOURCE" $MATUGEN_MODE; then
        echo "Failed to generate themes with matugen" >&2
        rm -f "$TEMP_CONFIG"
        exit 1
    fi
    
    # For color mode, we already have the input color as primary
    EXTRACTED_PRIMARY="$INPUT_SOURCE"
fi

TEMP_CONTENT_CONFIG="/tmp/matugen-content-config-$$.toml"
build_content_config "$TEMP_CONTENT_CONFIG" "$IS_LIGHT" "$SHELL_DIR"

if [ -s "$TEMP_CONTENT_CONFIG" ] && grep -q '\[templates\.' "$TEMP_CONTENT_CONFIG"; then
    echo "Running content-specific theme generation..."
    # Generate content-specific templates 
    if [ "$MODE" = "generate" ]; then
        matugen -c "$TEMP_CONTENT_CONFIG" -t scheme-content image "$INPUT_SOURCE" $MATUGEN_MODE
    elif [ "$MODE" = "generate-color" ]; then
        matugen -c "$TEMP_CONTENT_CONFIG" -t scheme-content color hex "$INPUT_SOURCE" $MATUGEN_MODE
    fi
    
    # Small delay to ensure content generation completes
    sleep 0.1
    
    # Get JSON with error handling
    if [ "$MODE" = "generate" ]; then
        if ! DEFAULT_JSON=$(matugen --json hex image "$INPUT_SOURCE" $MATUGEN_MODE 2>&1); then
            echo "Warning: Failed to get JSON from matugen for image mode"
            DEFAULT_JSON=""
        fi
    elif [ "$MODE" = "generate-color" ]; then
        if ! DEFAULT_JSON=$(matugen --json hex color hex "$INPUT_SOURCE" $MATUGEN_MODE 2>&1); then
            echo "Warning: Failed to get JSON from matugen for color mode"  
            DEFAULT_JSON=""
        fi
    fi

    # Extract primary_container for b16 base color and primary for honoring
    if [ -n "$DEFAULT_JSON" ] && echo "$DEFAULT_JSON" | grep -q '"primary_container"'; then
        EXTRACTED_PRIMARY=$(echo "$DEFAULT_JSON" | grep -oE '"primary_container":"#[0-9a-fA-F]{6}"' | sed -n '1p' | cut -d'"' -f4)
        echo "Successfully extracted primary_container: $EXTRACTED_PRIMARY"
        
        # Also extract the actual primary color to honor in palette
        if [ "$IS_LIGHT" = "true" ]; then
            # Light mode: get primary from light theme (second occurrence)
            HONOR_PRIMARY=$(echo "$DEFAULT_JSON" | grep -oE '"primary":"#[0-9a-fA-F]{6}"' | sed -n '2p' | cut -d'"' -f4)
        else
            # Dark mode: get primary from dark theme (first occurrence)
            HONOR_PRIMARY=$(echo "$DEFAULT_JSON" | grep -oE '"primary":"#[0-9a-fA-F]{6}"' | sed -n '1p' | cut -d'"' -f4)
        fi
        echo "Successfully extracted primary for honoring: $HONOR_PRIMARY"
    else
        echo "Warning: No primary_container found in JSON output"
        EXTRACTED_PRIMARY=""
        HONOR_PRIMARY=""
    fi

    # Fallback if extraction failed
    if [ -z "$EXTRACTED_PRIMARY" ]; then
        if [ "$MODE" = "generate-color" ]; then
            EXTRACTED_PRIMARY="$INPUT_SOURCE"
            HONOR_PRIMARY="$INPUT_SOURCE"
            echo "Using input color as primary: $EXTRACTED_PRIMARY"
        else
            EXTRACTED_PRIMARY="#6b5f8e"
            HONOR_PRIMARY="#ccbeff"  # Default Material Design primary for fallback
            echo "Warning: Could not extract primary color, using fallback: $EXTRACTED_PRIMARY"
        fi
    else
        echo "Extracted primary color from scheme-content: $EXTRACTED_PRIMARY"
    fi
    
    if command -v ghostty >/dev/null 2>&1; then
        echo "Generating base16 palette for ghostty..."
        
        PRIMARY_COLOR="$EXTRACTED_PRIMARY"
        if [ -z "$PRIMARY_COLOR" ]; then
            if [ "$MODE" = "generate-color" ]; then
                PRIMARY_COLOR="$INPUT_SOURCE"
                echo "Using input color as primary: $PRIMARY_COLOR"
            else
                PRIMARY_COLOR="#6b5f8e"
                echo "Warning: Could not extract primary color, using fallback: $PRIMARY_COLOR"
            fi
        fi
        
        B16_ARGS="$PRIMARY_COLOR"
        if [ "$IS_LIGHT" = "true" ]; then
            B16_ARGS="$B16_ARGS --light"
        fi
        if [ -n "$HONOR_PRIMARY" ]; then
            B16_ARGS="$B16_ARGS --honor-primary $HONOR_PRIMARY"
        fi
        
        B16_OUTPUT=$("$SHELL_DIR/matugen/b16.py" $B16_ARGS)
        
        if [ $? -eq 0 ] && [ -n "$B16_OUTPUT" ]; then
            TEMP_GHOSTTY="/tmp/ghostty-config-$$.conf"
            echo "$B16_OUTPUT" > "$TEMP_GHOSTTY"
            echo "" >> "$TEMP_GHOSTTY"
            
            if [ -f "$CONFIG_DIR/ghostty/config-dankcolors" ]; then
                cat "$CONFIG_DIR/ghostty/config-dankcolors" >> "$TEMP_GHOSTTY"
                mv "$TEMP_GHOSTTY" "$CONFIG_DIR/ghostty/config-dankcolors"
                echo "Base16 palette prepended to ghostty config"
            else
                echo "Warning: $CONFIG_DIR/ghostty/config-dankcolors not found, skipping b16 prepend"
                rm -f "$TEMP_GHOSTTY"
            fi
        else
            echo "Warning: Failed to generate base16 palette"
        fi
    fi
    
    if command -v kitty >/dev/null 2>&1; then
        echo "Generating base16 palette for kitty..."
        
        PRIMARY_COLOR="$EXTRACTED_PRIMARY"
        if [ -z "$PRIMARY_COLOR" ]; then
            if [ "$MODE" = "generate-color" ]; then
                PRIMARY_COLOR="$INPUT_SOURCE"
                echo "Using input color as primary: $PRIMARY_COLOR"
            else
                PRIMARY_COLOR="#6b5f8e"
                echo "Warning: Could not extract primary color, using fallback: $PRIMARY_COLOR"
            fi
        fi
        
        B16_ARGS="$PRIMARY_COLOR"
        if [ "$IS_LIGHT" = "true" ]; then
            B16_ARGS="$B16_ARGS --light"
        fi
        if [ -n "$HONOR_PRIMARY" ]; then
            B16_ARGS="$B16_ARGS --honor-primary $HONOR_PRIMARY"
        fi
        
        B16_OUTPUT=$("$SHELL_DIR/matugen/b16.py" $B16_ARGS --kitty)
        
        if [ $? -eq 0 ] && [ -n "$B16_OUTPUT" ]; then
            TEMP_KITTY="/tmp/kitty-config-$$.conf"
            echo "$B16_OUTPUT" > "$TEMP_KITTY"
            echo "" >> "$TEMP_KITTY"
            
            if [ -f "$CONFIG_DIR/kitty/dank-theme.conf" ]; then
                cat "$CONFIG_DIR/kitty/dank-theme.conf" >> "$TEMP_KITTY"
                mv "$TEMP_KITTY" "$CONFIG_DIR/kitty/dank-theme.conf"
                echo "Base16 palette prepended to kitty config"
            else
                echo "Warning: $CONFIG_DIR/kitty/dank-theme.conf not found, skipping b16 prepend"
                rm -f "$TEMP_KITTY"
            fi
        else
            echo "Warning: Failed to generate base16 palette for kitty"
        fi
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
command -v kitty >/dev/null 2>&1 && [ -f "$CONFIG_DIR/kitty/dank-theme.conf" ] && echo "  - Kitty terminal"
command -v dgop >/dev/null 2>&1 && [ -f "$CONFIG_DIR/dgop/colors.json" ] && echo "  - Dgop colors"
