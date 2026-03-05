pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.containers
import qs.components.live
import qs.services
import qs.config

Item {
    id: root

    default property alias pageSections: contentColumn.data
    
    property var sectionsList: []
    property string currentSection: ""
    property bool programmaticScroll: false
    property bool initializing: true
    
    property real bottomPaddingViewportRatio: 0.66
    property real bottomPaddingExtra: Appearance.padding.larger * 4
    
    readonly property var subsections: sectionsList.map(section => ({
        id: section.sectionId,
        name: section.sectionName,
        icon: section.sectionIcon
    }))

    Timer {
        id: scrollTimer
        interval: Appearance.anim.durations.normal + 50
        onTriggered: root.programmaticScroll = false
    }

    Component.onCompleted: {
        sectionsList = contentColumn.children.filter(child => 
            child.sectionId !== undefined && child.sectionName !== undefined
        )
        
        // Set initial section without animation
        if (sectionsList.length > 0) {
            currentSection = sectionsList[0].sectionId
        }
        
        initializing = false
    }

    function scrollToSection(sectionId: string): void {
        for (let i = 0; i < sectionsList.length; i++) {
            if (sectionsList[i].sectionId === sectionId) {
                const targetY = sectionsList[i].sectionHeader.mapToItem(contentColumn, 0, 0).y
                programmaticScroll = true
                root.currentSection = sectionId
                contentFlickable.contentY = targetY
                scrollTimer.restart()
                return
            }
        }
    }

    function updateCurrentSection(): void {
        if (programmaticScroll) return

        const scrollY = contentFlickable.contentY
        const viewportCenter = scrollY + (contentFlickable.height / 3)

        let currentSectionId = sectionsList.length > 0 ? sectionsList[0].sectionId : ""
        let minDistance = Infinity

        for (let i = 0; i < sectionsList.length; i++) {
            const sectionY = sectionsList[i].sectionHeader.mapToItem(contentColumn, 0, 0).y
            const distance = Math.abs(sectionY - scrollY)

            if (sectionY <= viewportCenter && distance < minDistance) {
                minDistance = distance
                currentSectionId = sectionsList[i].sectionId
            }
        }

        root.currentSection = currentSectionId
    }

    RowLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.large

        ColumnLayout {
            VerticalNav {
                id: verticalNav

                Layout.alignment: Qt.AlignTop

                sections: root.subsections
                activeSection: root.currentSection
                disableAnimations: root.initializing
                onSectionChanged: sectionId => root.scrollToSection(sectionId)
            }

            Item {
                Layout.fillHeight: true
            }
        }

        StyledFlickable {
            id: contentFlickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentWrapper.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            onContentYChanged: root.updateCurrentSection()

            Behavior on contentY {
                enabled: root.programmaticScroll && !root.initializing
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            Item {
                id: contentWrapper
                
                width: parent.width
                implicitHeight: contentColumn.implicitHeight + bottomPadding.height
                
                ColumnLayout {
                    id: contentColumn

                    width: parent.width
                    spacing: 0

                    // PageSection children added via default property alias
                }
                
                Item {
                    id: bottomPadding
                    
                    anchors.top: contentColumn.bottom
                    width: parent.width
                    height: contentFlickable.height * root.bottomPaddingViewportRatio + root.bottomPaddingExtra
                }
            }
        }
    }
}
