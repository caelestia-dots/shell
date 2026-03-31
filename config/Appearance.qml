pragma Singleton

import Quickshell

Singleton {
    // Literally just here to shorten accessing stuff :woe:
    // Also kinda so I can keep accessing it with `Appearance.xxx` instead of `Config.appearance.xxx`
    readonly property AppearanceConfig.Rounding rounding: Config.appearance.rounding // qmllint disable missing-property
    readonly property AppearanceConfig.Spacing spacing: Config.appearance.spacing // qmllint disable missing-property
    readonly property AppearanceConfig.Padding padding: Config.appearance.padding // qmllint disable missing-property
    readonly property AppearanceConfig.FontStuff font: Config.appearance.font // qmllint disable missing-property
    readonly property AppearanceConfig.Anim anim: Config.appearance.anim // qmllint disable missing-property
    readonly property AppearanceConfig.Transparency transparency: Config.appearance.transparency // qmllint disable missing-property
}
