pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.components.common

ColumnLayout {
    id: root

    required property var thresholds
    property bool _selfWriting: false

    function _syncFromConfig(): void {
        thresholdsModel.clear();
        const list = root.thresholds || [];
        for (const t of list) {
            thresholdsModel.append({
                level: t.level ?? 50,
                setPowerProfile: t.setPowerProfile ?? "",
                setRefreshRate: t.setRefreshRate ?? "",
                disableAnimations: t.disableAnimations ?? "",
                disableBlur: t.disableBlur ?? "",
                disableRounding: t.disableRounding ?? "",
                disableShadows: t.disableShadows ?? ""
            });
        }
    }

    function _serialize(): var {
        const out = [];
        for (let i = 0; i < thresholdsModel.count; i++) {
            const it = thresholdsModel.get(i);
            out.push({
                level: it.level,
                setPowerProfile: it.setPowerProfile,
                setRefreshRate: it.setRefreshRate,
                disableAnimations: it.disableAnimations,
                disableBlur: it.disableBlur,
                disableRounding: it.disableRounding,
                disableShadows: it.disableShadows
            });
        }
        return out;
    }

    function _commit(): void {
        _selfWriting = true;
        const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
        pm.thresholds = _serialize();
        GlobalConfig.general.battery.powerManagement = pm;
        Qt.callLater(() => _selfWriting = false);
    }

    function updateField(idx: int, field: string, value: var): void {
        if (idx < 0 || idx >= thresholdsModel.count)
            return;
        thresholdsModel.setProperty(idx, field, value);
        _commit();
    }

    function removeAt(idx: int): void {
        if (idx < 0 || idx >= thresholdsModel.count)
            return;
        thresholdsModel.remove(idx);
        _commit();
    }

    function addThreshold(): void {
        thresholdsModel.append({
            level: 50,
            setPowerProfile: "",
            setRefreshRate: "auto",
            disableAnimations: "",
            disableBlur: "",
            disableRounding: "",
            disableShadows: ""
        });
        _commit();
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.normal

    onThresholdsChanged: {
        if (_selfWriting)
            return;
        _syncFromConfig();
    }

    Component.onCompleted: _syncFromConfig()

    ListModel {
        id: thresholdsModel
    }

    ListView {
        id: listView

        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight
        spacing: Tokens.spacing.normal
        model: thresholdsModel
        clip: true

        add: Transition {
            ParallelAnimation {
                Anim {
                    property: "opacity"
                    from: 0
                    to: 1
                }
                Anim {
                    property: "scale"
                    from: 0.80
                    to: 1
                }
            }
        }
        remove: Transition {
            ParallelAnimation {
                Anim {
                    property: "opacity"
                    from: 1
                    to: 0
                }
                Anim {
                    property: "scale"
                    from: 1
                    to: 0.80
                }
            }
        }
        removeDisplaced: Transition {
            Anim {
                property: "y"
            }
        }

        footer: StyledText {
            visible: thresholdsModel.count === 0
            width: ListView.view.width
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("No thresholds configured")
            color: Qt.alpha(Colours.palette.m3onSurface, 0.6)
            font.pointSize: Tokens.font.size.small
        }

        header: Item {
            width: ListView.view.width
            height: 56 + Tokens.spacing.normal

            StyledRect {
                anchors.fill: parent
                anchors.bottomMargin: Tokens.spacing.normal
                radius: Tokens.rounding.normal
                color: Colours.palette.m3primary
                opacity: root.enabled ? 1 : 0.4

                TapHandler {
                    onTapped: root.addThreshold()
                }

                HoverHandler {
                    id: addBtnHover

                    onHoveredChanged: parent.color = hovered ? Qt.lighter(Colours.palette.m3primary, 1.1) : Colours.palette.m3primary
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.normal

                    MaterialIcon {
                        text: "add_circle"
                        font.pointSize: Tokens.font.size.large
                        color: Colours.palette.m3onPrimary
                    }

                    StyledText {
                        text: qsTr("Add threshold")
                        font.pointSize: Tokens.font.size.normal
                        color: Colours.palette.m3onPrimary
                    }
                }
            }
        }

        delegate: StyledRect {
            id: card

            required property int index
            required property int level
            required property string setPowerProfile
            required property string setRefreshRate
            required property string disableAnimations
            required property string disableBlur
            required property string disableRounding
            required property string disableShadows

            property bool editing: false

            width: ListView.view.width
            Layout.fillWidth: true
            implicitHeight: (editing ? cardCol.implicitHeight : headerRow.implicitHeight) + Tokens.padding.large * 2
            radius: Tokens.rounding.normal
            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
            opacity: root.enabled ? 1 : 0.4

            Behavior on implicitHeight {
                Anim {}
            }

            ColumnLayout {
                id: cardCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.normal

                RowLayout {
                    id: headerRow

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: card.level + qsTr("% Battery")
                        font.pointSize: Tokens.font.size.normal
                        font.weight: Font.Medium
                    }

                    IconTextButton {
                        icon: card.editing ? "check" : "edit"
                        text: card.editing ? qsTr("Done") : qsTr("Edit")
                        onClicked: card.editing = !card.editing
                    }

                    IconButton {
                        icon: "delete"
                        onClicked: root.removeAt(card.index)
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: card.editing
                    visible: active && opacity > 0
                    opacity: card.editing ? 1 : 0

                    sourceComponent: ColumnLayout {
                        spacing: Tokens.spacing.normal

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: levelRow.implicitHeight + Tokens.padding.large * 2
                            radius: Tokens.rounding.normal
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                            RowLayout {
                                id: levelRow

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Tokens.padding.large
                                spacing: Tokens.spacing.normal

                                StyledText {
                                    Layout.fillWidth: true
                                    text: qsTr("Battery level")
                                }

                                CustomSpinBox {
                                    min: 5
                                    max: 95
                                    step: 1
                                    value: card.level
                                    onValueModified: v => {
                                        if (v !== card.level)
                                            root.updateField(card.index, "level", Math.round(v));
                                    }
                                }
                            }
                        }

                        PowerProfileSelector {
                            Layout.fillWidth: true
                            value: card.setPowerProfile
                            showUnchanged: true
                            onProfileChanged: v => root.updateField(card.index, "setPowerProfile", v)
                        }

                        RefreshRateSelector {
                            Layout.fillWidth: true
                            value: card.setRefreshRate
                            showUnchanged: true
                            onRateChanged: v => root.updateField(card.index, "setRefreshRate", v)
                        }

                        TriStateRow {
                            label: qsTr("Animations")
                            value: card.disableAnimations
                            onTriStateValueChanged: v => root.updateField(card.index, "disableAnimations", v)
                        }

                        TriStateRow {
                            label: qsTr("Blur")
                            value: card.disableBlur
                            onTriStateValueChanged: v => root.updateField(card.index, "disableBlur", v)
                        }

                        TriStateRow {
                            label: qsTr("Rounding")
                            value: card.disableRounding
                            onTriStateValueChanged: v => root.updateField(card.index, "disableRounding", v)
                        }

                        TriStateRow {
                            label: qsTr("Shadows")
                            value: card.disableShadows
                            onTriStateValueChanged: v => root.updateField(card.index, "disableShadows", v)
                        }
                    }

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }
}
