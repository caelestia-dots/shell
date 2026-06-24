pragma Singleton

import QtQuick
import Quickshell

// A flat index of searchable settings. Each entry points at the page that hosts
// it (pageIdx matches PageCompRegistry.pageComps) so the search bar can jump
// straight there. keywords are extra terms that should match but aren't shown.
//
// To make a new setting searchable, add a SettingEntry here. Stage 2 will also
// use the anchor field to scroll to and highlight the exact row.
Singleton {
    id: root

    readonly property list<SettingEntry> entries: [
        // Audio (pageComps[3])
        SettingEntry {
            pageIdx: 3
            page: qsTr("Audio")
            title: qsTr("Output volume")
            description: qsTr("Speaker and headphone level")
            keywords: "sound speaker headphone output loudness"
            anchor: "audio-output"
        },
        SettingEntry {
            pageIdx: 3
            page: qsTr("Audio")
            title: qsTr("Input volume")
            description: qsTr("Microphone level")
            keywords: "microphone mic input recording"
            anchor: "audio-input"
        },
        SettingEntry {
            pageIdx: 3
            page: qsTr("Audio")
            title: qsTr("App volumes")
            description: qsTr("Per-application volume mixer")
            keywords: "mixer per app application streams"
            anchor: "audio-app-volumes"
        },

        // Services (pageComps[8])
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Media refresh")
            description: qsTr("How often the media position updates")
            keywords: "media player position polling interval mpris"
            anchor: "services-media-refresh"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("System stats refresh")
            description: qsTr("CPU, memory and GPU update interval")
            keywords: "cpu memory ram gpu stats resources polling interval"
            anchor: "services-stats-refresh"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Wi-Fi rescan")
            description: qsTr("How often available networks are rescanned")
            keywords: "wifi wireless network rescan scan interval"
            anchor: "services-wifi-rescan"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Lyrics backend")
            description: qsTr("Source used to fetch synced lyrics")
            keywords: "lyrics synced lrclib netease music"
            anchor: "services-lyrics-backend"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Default player")
            description: qsTr("Preferred media player when several are open")
            keywords: "media player default preferred mpris"
            anchor: "services-default-player"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Volume step")
            description: qsTr("Amount the volume changes per scroll")
            keywords: "volume step increment scroll audio"
            anchor: "services-volume-step"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Brightness step")
            description: qsTr("Amount the brightness changes per scroll")
            keywords: "brightness step increment scroll backlight"
            anchor: "services-brightness-step"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Max volume")
            description: qsTr("Upper limit for output volume")
            keywords: "volume max maximum limit cap audio"
            anchor: "services-max-volume"
        }
    ]

    component SettingEntry: QtObject {
        required property int pageIdx
        required property string page
        required property string title
        property string description
        property string keywords
        property string anchor
    }
}
