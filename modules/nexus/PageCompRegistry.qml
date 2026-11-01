pragma Singleton

import QtQuick

QtObject {
    id: root

    // One file per Nexus section, indexed by the page index NexusState uses. A section is only compiled
    // when it's first opened, so the Nexus doesn't load every page up front.
    readonly property list<url> pageUrls: [Qt.resolvedUrl("AppearanceSection.qml"), Qt.resolvedUrl("NetworkSection.qml"), Qt.resolvedUrl("BluetoothSection.qml"), Qt.resolvedUrl("AudioSection.qml"), root.placeholderUrl, root.placeholderUrl, Qt.resolvedUrl("PanelsSection.qml"), Qt.resolvedUrl("AppsSection.qml"), Qt.resolvedUrl("ServicesSection.qml"), Qt.resolvedUrl("LanguageSection.qml"), Qt.resolvedUrl("AboutSection.qml")]

    readonly property url placeholderUrl: Qt.resolvedUrl("common/PlaceholderPage.qml")
}
