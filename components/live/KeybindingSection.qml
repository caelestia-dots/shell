pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components.live
import qs.services
import qs.config

SectionContentArea {
    id: root

    property int targetColumns: 2
    property real responsiveBreakpoint: 800
    
    property list<var> groups: []

    content: Component {
        GridLayout {
            columns: parent.width > root.responsiveBreakpoint ? root.targetColumns : 1
            columnSpacing: Appearance.spacing.large
            rowSpacing: Appearance.spacing.large

            Repeater {
                model: root.groups

                delegate: SectionContentArea {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop
                    title: modelData.title

                    content: Component {
                        ColumnLayout {
                            spacing: Appearance.spacing.normal

                            Repeater {
                                model: modelData.bindings

                                delegate: KeybindingRow {
                                    required property var modelData

                                    label: modelData.label
                                    keys: modelData.keys
                                    desc: modelData.desc || ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
