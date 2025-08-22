#!/usr/bin/env bash

INPUT_SOURCE="$1"
SHELL_DIR="$2"
CONFIG_DIR="$3"
MODE="$4"
IS_LIGHT="$5"
ICON_THEME="$6"
GTK_THEMING="$7"
QT_THEMING="$8"

if [ -z "$SHELL_DIR" ] || [ -z "$CONFIG_DIR" ]; then
    echo "Usage: $0 <input_source> <shell_dir> <config_dir> [mode] [is_light] [icon_theme] [gtk_theming] [qt_theming]" >&2
    echo "  input_source: wallpaper path for 'generate' mode, hex color for 'generate-color' mode" >&2
    echo "  For restore mode, input_source can be empty" >&2
    exit 1
fi

MODE=${MODE:-"generate"}
IS_LIGHT=${IS_LIGHT:-"false"}
ICON_THEME=${ICON_THEME:-"System Default"}
GTK_THEMING=${GTK_THEMING:-"false"}
QT_THEMING=${QT_THEMING:-"false"}

if [ "$MODE" = "restore" ]; then
    echo "Restore mode not supported in modular script system" >&2
    exit 1
fi

# Always run matugen generation
echo "Running matugen theme generation..."
if ! "$SHELL_DIR/scripts/matugen.sh" "$INPUT_SOURCE" "$SHELL_DIR" "$CONFIG_DIR" "$MODE" "$IS_LIGHT" "$ICON_THEME"; then
    echo "Failed to generate matugen themes" >&2
    exit 1
fi

# Apply GTK theming if requested
if [ "$GTK_THEMING" = "true" ]; then
    echo "Applying GTK colors..."
    if ! "$SHELL_DIR/scripts/gtk.sh" "$CONFIG_DIR" "$IS_LIGHT" "$SHELL_DIR"; then
        echo "Failed to apply GTK colors" >&2
        exit 1
    fi
fi

# Apply Qt theming if requested
if [ "$QT_THEMING" = "true" ]; then
    echo "Applying Qt colors..."
    if ! "$SHELL_DIR/scripts/qt.sh" "$CONFIG_DIR"; then
        echo "Failed to apply Qt colors" >&2
        exit 1
    fi
fi

echo "Theme generation completed successfully"