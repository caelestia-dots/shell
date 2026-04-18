import ".."
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

StyledRect {
    id: root

    property var options: [] // Array of {label: string, propertyName: string, onToggled: function, state: bool?}
    property var rootItem: null // The root item that contains the properties we want to bind to
    property string title: "" // Optional title text
    property int rows: 1 // Number of rows

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.normal
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
    clip: true

    Behavior on implicitHeight {
        Anim {}
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.normal

        StyledText {
            visible: root.title !== ""
            text: root.title
            font.pointSize: Tokens.font.size.normal
        }

        GridLayout {
            id: buttonGrid

            Layout.alignment: Qt.AlignHCenter
            rowSpacing: Tokens.spacing.small
            columnSpacing: Tokens.spacing.small
            rows: root.rows
            columns: Math.ceil(root.options.length / root.rows)

            Repeater {
                id: repeater

                model: root.options

                delegate: TextButton {
                    id: button

                    required property int index
                    required property var modelData

                    property bool _checked: false

                    Layout.fillWidth: true
                    text: modelData.label
                    checked: _checked
                    toggle: false
                    type: TextButton.Tonal

                    // Create binding in Component.onCompleted
                    Component.onCompleted: {
                        if (modelData.state !== undefined && modelData.state) {
                            _checked = modelData.state;
                        } else if (root.rootItem && modelData.propertyName) {
                            const propName = modelData.propertyName;
                            const rootItem = root.rootItem;
                            _checked = Qt.binding(function () {
                                return rootItem[propName] ?? false;
                            });
                        }
                    }

                    // Match utilities Toggles radius styling
                    // Each button has full rounding (not connected) since they have spacing
                    radius: stateLayer.pressed ? Tokens.rounding.small / 2 : internalChecked ? Tokens.rounding.small : Tokens.rounding.normal

                    // Match utilities Toggles inactive color
                    inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                    // Adjust width similar to utilities toggles
                    Layout.preferredWidth: implicitWidth + (stateLayer.pressed ? Tokens.padding.large : internalChecked ? Tokens.padding.smaller : 0)

                    onClicked: {
                        if (modelData.onToggled && root.rootItem && modelData.propertyName) {
                            const currentValue = root.rootItem[modelData.propertyName] ?? false;
                            modelData.onToggled(!currentValue);
                        }
                    }

                    Behavior on Layout.preferredWidth {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Behavior on radius {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                }
            }
        }
    }
}
