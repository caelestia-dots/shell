pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components
import qs.components.controls

RowLayout {
    id: root

    required property Annotation annotation

    signal saved
    signal copied
    signal cancelled

    spacing: Tokens.spacing.medium

    ButtonRow {
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: root.annotation.tools

            ToolbarButton {
                required property var modelData

                isToggle: true
                checked: root.annotation.document.tool === modelData.tool
                icon: modelData.icon
                onClicked: root.annotation.document.tool = modelData.tool
            }
        }
    }

    Separator {}

    ButtonRow {
        spacing: Tokens.spacing.extraSmall

        ToolbarButton {
            disabled: !root.annotation.document.canUndo
            icon: "undo"
            onClicked: root.annotation.document.undo()
        }

        ToolbarButton {
            disabled: !root.annotation.document.canRedo
            icon: "redo"
            onClicked: root.annotation.document.redo()
        }
    }

    Separator {}

    ButtonRow {
        spacing: Tokens.spacing.extraSmall

        ToolbarButton {
            icon: "close"
            onClicked: root.cancelled()
        }

        IconTextButton {
            shapeMorph: true
            isRound: true
            horizontalPadding: Tokens.padding.largeIncreased
            icon: "content_copy"
            text: Tr.tr("Copy")
            onClicked: root.copied()
        }

        IconTextButton {
            shapeMorph: true
            isRound: true
            horizontalPadding: Tokens.padding.largeIncreased
            icon: "check"
            text: Tr.tr("Save")
            onClicked: root.saved()
        }
    }

    component Separator: StyledRect {
        Layout.fillHeight: true
        Layout.topMargin: Tokens.padding.large
        Layout.bottomMargin: Tokens.padding.large
        implicitWidth: 1
        color: Qt.alpha(Colours.palette.onSecondaryContainer, 0.3)
    }
}
