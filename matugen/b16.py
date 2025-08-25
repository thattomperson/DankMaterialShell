#!/usr/bin/env python3
import colorsys
import sys

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16)/255.0 for i in (0, 2, 4))

def rgb_to_hex(r, g, b):
    return f"#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}"

def generate_palette(base_color, is_light=False):
    r, g, b = hex_to_rgb(base_color)
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    
    palette = []
    
    if is_light:
        palette.append("#f8f8f8")
    else:
        palette.append("#1a1a1a")
    
    red_h = h * 0.15
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(red_h, 0.5, 0.88)))
    
    green_h = h + 0.25 if h < 0.75 else h - 0.75
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(green_h, s * 0.6, v * 1.1)))
    
    yellow_h = h + 0.15 if h < 0.85 else h - 0.85
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(yellow_h, s * 0.5, v * 1.3)))
    
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(h, s * 0.8, v * 1.2)))
    
    mag_h = h - 0.08 if h > 0.08 else h + 0.08
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(mag_h, s * 0.9, v * 1.1)))
    
    cyan_h = h + 0.08
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(cyan_h, s * 0.7, v * 1.15)))
    
    if is_light:
        palette.append("#2e2e2e")
        palette.append("#4a4a4a")
    else:
        palette.append("#abb2bf")
        palette.append("#5c6370")
    
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(red_h, 0.4, 0.94)))
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(green_h, s * 0.5, v * 1.3)))
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(yellow_h, s * 0.4, v * 1.4)))
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(h, s * 0.7, min(v * 1.4, 1.0))))
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(mag_h, s * 0.8, min(v * 1.3, 1.0))))
    palette.append(rgb_to_hex(*colorsys.hsv_to_rgb(cyan_h, s * 0.6, min(v * 1.3, 1.0))))
    
    if is_light:
        palette.append("#1a1a1a")
    else:
        palette.append("#ffffff")
    
    return palette

if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: b16.py <hex_color> [--light]", file=sys.stderr)
        sys.exit(1)
    
    base = sys.argv[1]
    if not base.startswith('#'):
        base = '#' + base
    
    is_light = len(sys.argv) == 3 and sys.argv[2] == "--light"
    colors = generate_palette(base, is_light)
    
    for i, color in enumerate(colors):
        print(f"palette = {i}={color}")