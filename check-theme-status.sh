#!/bin/bash

# Theme verification script
echo "=== Theme Status Check ==="

# Check dconf/gsettings values
echo ""
echo "Current theme settings:"
if command -v dconf >/dev/null 2>&1; then
    echo "  color-scheme (dconf): $(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null || echo 'not set')"
    echo "  gtk-theme (dconf): $(dconf read /org/gnome/desktop/interface/gtk-theme 2>/dev/null || echo 'not set')"
    echo "  icon-theme (dconf): $(dconf read /org/gnome/desktop/interface/icon-theme 2>/dev/null || echo 'not set')"
fi

if command -v gsettings >/dev/null 2>&1; then
    echo "  color-scheme (gsettings): $(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'not available')"
    echo "  gtk-theme (gsettings): $(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'not available')"
    echo "  icon-theme (gsettings): $(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'not available')"
fi

# Check settings.ini files
echo ""
echo "GTK settings.ini files:"
for gtk_dir in ~/.config/gtk-3.0 ~/.config/gtk-4.0; do
    if [ -f "$gtk_dir/settings.ini" ]; then
        echo "  $gtk_dir/settings.ini:"
        grep -E "(gtk-theme-name|gtk-icon-theme-name|gtk-application-prefer-dark-theme)" "$gtk_dir/settings.ini" | sed 's/^/    /'
    else
        echo "  $gtk_dir/settings.ini: not found"
    fi
done

# Check for generated color files
echo ""
echo "Generated color files:"
for color_file in ~/.config/gtk-3.0/colors.css ~/.config/gtk-4.0/colors.css; do
    if [ -f "$color_file" ]; then
        echo "  $color_file: exists ($(stat -c%y "$color_file" | cut -d' ' -f1,2))"
        # Show first few lines to verify it has content
        echo "    Preview: $(head -3 "$color_file" | tr '\n' ' ')"
    else
        echo "  $color_file: not found"
    fi
done

# Check for Qt color schemes
echo ""
echo "Qt color schemes:"
if [ -f ~/.local/share/color-schemes/Matugen.colors ]; then
    echo "  Matugen.colors: exists ($(stat -c%y ~/.local/share/color-schemes/Matugen.colors | cut -d' ' -f1,2))"
else
    echo "  Matugen.colors: not found"
fi

# Test immediate effect
echo ""
echo "Testing immediate color-scheme change:"
if command -v dconf >/dev/null 2>&1; then
    current_scheme=$(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null)
    echo "  Current: $current_scheme"
    echo "  You can test by running:"
    if [[ "$current_scheme" == *"dark"* ]]; then
        echo "    dconf write /org/gnome/desktop/interface/color-scheme '\"prefer-light\"'"
        echo "    (then switch back with: dconf write /org/gnome/desktop/interface/color-scheme '\"prefer-dark\"')"
    else
        echo "    dconf write /org/gnome/desktop/interface/color-scheme '\"prefer-dark\"'"
        echo "    (then switch back with: dconf write /org/gnome/desktop/interface/color-scheme '\"prefer-light\"')"
    fi
fi