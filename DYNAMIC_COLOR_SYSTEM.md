# Dynamic Color System for Quickshell Caelestia

## Overview

This system automatically extracts colors from your wallpaper and applies them to the Quickshell interface, creating a cohesive theme that matches your wallpaper while maintaining UI usability.

## How It Works

### 1. Color Extraction Process

**Script Location:** `/home/dulc3/.local/bin/qs-dynamic-colors`

The system uses ImageMagick to analyze wallpapers:
```bash
# Extracts 12 dominant colors for better selection
COLORS=$(magick "$WALLPAPER" -resize 100x100 -colors 12 -unique-colors txt:- | grep -o '#[0-9A-F]\{6\}' | head -12)
```

### 2. Smart Color Selection

Instead of using raw extracted colors, the system intelligently selects colors based on luminance:

**Luminance Calculation:**
```bash
get_luminance() {
    local color="$1"
    local r=$((0x${color:1:2}))
    local g=$((0x${color:3:2}))
    local b=$((0x${color:5:2}))
    echo $(( (r * 299 + g * 587 + b * 114) / 1000 ))
}
```

**Color Selection Criteria:**
- **Accent colors:** Luminance 80-200 (visible but not blindingly bright)
- **Primary colors:** Luminance 40-120 (readable, not too dark)
- **Surfaces:** Lightened versions of primary colors for better visibility

### 3. Color Processing Functions

**Darken Function (20% reduction):**
```bash
darken_color() {
    r=$(( r * 8 / 10 ))
    g=$(( g * 8 / 10 ))
    b=$(( b * 8 / 10 ))
}
```

**Lighten Function (+80 brightness):**
```bash
lighten_color() {
    r=$(( (r + 80) > 255 ? 255 : (r + 80) ))
    g=$(( (g + 80) > 255 ? 255 : (g + 80) ))
    b=$(( (b + 80) > 255 ? 255 : (b + 80) ))
}
```

### 4. Theme Application

**Color Mapping Strategy:**
- `primary`: Extracted accent color (most vibrant)
- `secondary`: Darkened version of accent  
- `tertiary`: Extracted primary color (darker)
- `surface`: Lightened primary (better visibility)
- `background`: Always "#1e1e2e" (consistent dark base)
- `outline`: Always "#89b4fa" (bright blue for borders)
- `on*` colors: White (#ffffff) for maximum contrast

### 5. Integration with Wallpaper Scripts

**Modified Scripts:**
- `WallpaperSelect.sh` (Super+W keybind)
- `WallpaperRandom.sh` (Ctrl+Alt+W keybind)

**Integration Code:**
```bash
# Update Quickshell colors dynamically
if command -v qs-dynamic-colors &>/dev/null; then
    qs-dynamic-colors "$image_path" &
fi
```

## File Structure

```
~/.local/bin/
├── qs-dynamic-colors          # Main color extraction script
└── swww-colors               # SWWW wrapper (if needed)

~/.local/state/caelestia/
└── scheme.json               # Generated color scheme

~/.config/quickshell/caelestia/my-scripts/hypr/UserScripts/
├── WallpaperSelect.sh        # Modified for dynamic colors
└── WallpaperRandom.sh        # Modified for dynamic colors
```

## Why This Approach

### Problems with Simple Color Extraction
1. **Poor Contrast:** Raw wallpaper colors often too dark/similar
2. **Invisible UI:** Pure black making text/borders disappear  
3. **Inconsistent Results:** Some wallpapers produce unusable themes

### Our Solutions
1. **Luminance-Based Selection:** Only pick colors within usable brightness ranges
2. **Smart Contrast:** White text on colored backgrounds, fixed bright outlines
3. **Consistent Base:** Always use proper dark background, never pure black
4. **Color Role Optimization:** Swap primary/tertiary to use most vibrant color as accent

## Future Modifications

### Color Selection Tuning

**Adjust Luminance Ranges:**
```bash
# For brighter accents, increase range:
if [[ $lum -gt 100 && $lum -lt 220 ]]; then

# For darker primaries:  
if [[ $lum -gt 20 && $lum -lt 100 ]]; then
```

**Modify Color Processing:**
```bash
# Lighter surfaces (current: +80)
r=$(( (r + 120) > 255 ? 255 : (r + 120) ))

# Less darkening (current: 20% reduction)
r=$(( r * 9 / 10 ))  # 10% reduction instead
```

### Color Mapping Adjustments

**In the JSON generation section, modify:**
```bash
"primary": "${TERTIARY#\#}",           # Currently: extracted accent
"secondary": "${SECONDARY#\#}",        # Currently: darkened accent  
"tertiary": "${PRIMARY#\#}",           # Currently: extracted primary
"surface": "${SURFACE#\#}",            # Currently: lightened primary
```

**Example: Make UI more vibrant**
```bash
"primary": "${ACCENT#\#}",             # Use pure accent
"surfaceContainer": "${TERTIARY#\#}",  # Use more colorful surfaces
"outline": "${ACCENT#\#}",             # Use wallpaper accent for borders
```

### Advanced Modifications

**1. Multiple Color Extraction Strategies:**
```bash
# Add color temperature detection
get_color_temperature() {
    # Warm vs cool color detection
    # Adjust color selection based on temperature
}

# Add saturation boosting for dull wallpapers
boost_saturation() {
    # Convert to HSV, increase saturation, convert back
}
```

**2. User Preferences:**
```bash
# Add config file: ~/.config/qs-colors.conf
ACCENT_BRIGHTNESS=150    # Preferred accent luminance
SURFACE_LIGHTNESS=80     # How much to lighten surfaces
USE_WALLPAPER_OUTLINE=false  # Use fixed blue vs wallpaper colors
```

**3. Fallback Strategies:**
```bash
# If no good colors found, use preset themes:
FALLBACK_THEMES=(
    "catppuccin"  # Purple theme
    "tokyo-night" # Blue theme  
    "gruvbox"     # Orange theme
)
```

**4. Color Harmony Rules:**
```bash
# Ensure colors work well together
check_color_harmony() {
    # Implement color theory rules
    # Complementary, analogous, triadic schemes
}
```

### Testing New Configurations

**Test with specific wallpaper:**
```bash
qs-dynamic-colors "/path/to/test-wallpaper.jpg"
```

**Debug color selection:**
```bash
# Add to script for debugging:
echo "Extracted colors: ${COLOR_ARRAY[@]}"
echo "Selected accent: $BEST_ACCENT (luminance: $(get_luminance "$BEST_ACCENT"))"
echo "Selected primary: $BEST_PRIMARY (luminance: $(get_luminance "$BEST_PRIMARY"))"
```

**Preview without applying:**
```bash
# Modify script to show preview instead of applying:
cat "$SCHEME_FILE"  # Show generated JSON
# Comment out the restart commands
```

## Current Behavior Summary

✅ **What Works Well:**
- Automatic wallpaper integration via Super+W / Ctrl+Alt+W
- Smart color selection avoiding pure black/poor contrast
- Consistent UI visibility with white text and bright borders
- Good balance between wallpaper theming and usability

⚠️ **Known Limitations:**
- Some wallpapers may still produce similar surface/primary colors
- Very colorful wallpapers might need manual tuning
- Monochrome wallpapers fall back to preset colors

🔧 **Easy Tweaks:**
- Adjust luminance ranges for different color preferences
- Modify lightening/darkening amounts
- Change outline color strategy
- Add more sophisticated color harmony rules