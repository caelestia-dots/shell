# Caelestia SDDM theme

This optional theme mirrors Caelestia's lockscreen layout: dynamic clock and
date, Material surfaces, pill-shaped credentials, and animated passphrase
shapes.

Install the `extras/sddm/corners` directory as an SDDM theme, then run the
sync helper whenever the Caelestia wallpaper or colour scheme changes. The
helper updates the theme palette and copies the current wallpaper into the
theme directory.

The checked-in theme includes a neutral fallback background. The helper
defaults to `/usr/share/sddm/themes/caelestia`. Set
`CAELESTIA_SDDM_THEME_DIR` to use another installed theme location.
