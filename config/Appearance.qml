pragma Singleton

import Quickshell

Singleton {
    // Literally just here to shorten accessing stuff :woe:
    // Also kinda so I can keep accessing it with `Appearance.xxx` instead of `Config.appearance.xxx`
    readonly property AppearanceConfig.Rounding rounding: Config.appearance.rounding
    readonly property AppearanceConfig.Spacing spacing: Config.appearance.spacing
    readonly property AppearanceConfig.Padding padding: Config.appearance.padding
    readonly property AppearanceConfig.FontStuff font: Config.appearance.font
    readonly property AppearanceConfig.Anim anim: Config.appearance.anim
    readonly property AppearanceConfig.Transparency transparency: Config.appearance.transparency
}
