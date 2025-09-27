import qs.components
import qs.services
import qs.config
import "../services"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var list
    readonly property string text: {
        const fullText = list.search.text.slice(`${Config.launcher.actionPrefix}translate `.length);

        const matchedLanguage = Translator.languages.find(l =>
            fullText.toLowerCase().startsWith(l.name.toLowerCase() + " ")
        );

        if (matchedLanguage) {
            if (Translator.targetLanguage !== matchedLanguage.code) {
                Translator.targetLanguage = matchedLanguage.code;
            }
            return fullText.slice(matchedLanguage.name.length + 1);
        }

        return "";
    }

    function onClicked(): void {
        if (text.length > 0) {
            Translator.translate(text, (result) => {
                if (result.translatedText) {
                    Quickshell.execDetached(["wl-copy", result.translatedText]);
                }
                root.list.visibilities.launcher = false;
            });
        }
    }

    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Appearance.rounding.normal

        function onClicked(): void {
            root.onClicked();
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.padding.larger

        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: "translate"
            font.pointSize: Appearance.font.size.extraLarge
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.small

            StyledText {
                text: root.text.length > 0 ? root.text : qsTr("Type text to translate")
                color: root.text.length > 0 ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideLeft
                Layout.fillWidth: true
            }

            StyledText {
                text: {
                    if (root.text.length === 0) {
                        return "";
                    }
                    if (Translator.isLoading) {
                        return qsTr("Translating...");
                    }
                    if (Translator.error && Translator.error !== "") {
                        return qsTr("Error: %1").arg(Translator.error);
                    }
                    if (Translator.lastTranslation && Translator.lastTranslation !== "") {
                        return qsTr("Translation: %1").arg(Translator.lastTranslation);
                    }
                    return qsTr("Type text to translate");
                }
                color: {
                    if (Translator.isLoading)
                        return Colours.palette.m3onSurfaceVariant;
                    if (Translator.error && Translator.error !== "")
                        return Colours.palette.m3error;
                    if (Translator.lastTranslation && Translator.lastTranslation !== "")
                        return Colours.palette.m3primary;
                    return Colours.palette.m3onSurfaceVariant;
                }
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideLeft
                Layout.fillWidth: true
            }
        }

        StyledRect {
            color: Translator.isLoading ? Colours.palette.m3surfaceContainer : Colours.palette.m3tertiary
            radius: Appearance.rounding.normal
            clip: true

            implicitWidth: Translator.isLoading ?
                (loadingIcon.implicitWidth + Appearance.padding.normal * 2) :
                ((stateLayer.containsMouse ? label.implicitWidth + label.anchors.rightMargin : 0) + icon.implicitWidth + Appearance.padding.normal * 2)
            implicitHeight: Math.max(label.implicitHeight, icon.implicitHeight, loadingIcon.implicitHeight) + Appearance.padding.small * 2

            Layout.alignment: Qt.AlignVCenter

            MaterialIcon {
                id: loadingIcon
                visible: Translator.isLoading
                anchors.centerIn: parent
                text: "sync"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.large

                RotationAnimation on rotation {
                    running: Translator.isLoading
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }

            StateLayer {
                id: stateLayer
                visible: !Translator.isLoading

                color: Colours.palette.m3onTertiary

                function onClicked(): void {
                    if (Translator.lastTranslation && Translator.lastTranslation !== "") {
                        Quickshell.execDetached(["wl-copy", Translator.lastTranslation]);
                        root.list.visibilities.launcher = false;
                    }
                }
            }

            StyledText {
                id: label
                visible: !Translator.isLoading

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: icon.left
                anchors.rightMargin: Appearance.spacing.small

                text: qsTr("Copy")
                color: Colours.palette.m3onTertiary
                font.pointSize: Appearance.font.size.normal

                opacity: stateLayer.containsMouse ? 1 : 0

                Behavior on opacity {
                    Anim {}
                }
            }

            MaterialIcon {
                id: icon
                visible: !Translator.isLoading

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Appearance.padding.normal

                text: "content_copy"
                color: Colours.palette.m3onTertiary
                font.pointSize: Appearance.font.size.large
            }

            Behavior on implicitWidth {
                Anim {
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }
    }

    Timer {
        id: translateTimer
        interval: 500
        repeat: false

        onTriggered: {
            if (root.text.length > 0) {
                Translator.translate(root.text, (result) => {});
            }
        }
    }

    onTextChanged: {
        if (text.length > 0) {
            translateTimer.restart();
        } else {
            translateTimer.stop();
            Translator.lastTranslation = "";
            Translator.error = "";
        }
    }
}
