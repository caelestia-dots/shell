pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Material 3 text field — outlined and filled variants.
//
// Implements the M3 spec: floating label, leading/trailing icons, password
// visibility toggle, supporting text, error state with error text and error
// icon, prefix/suffix, optional character counter, hover/focus state layer, and
// the M3 disabled treatment (all elements onSurface @ 38%).
//
// Variant defaults to Outlined and can be overridden per-instance via `variant`.
Item {
    id: root

    enum Variant {
        Outlined,
        Filled
    }

    property int variant: M3TextField.Variant.Outlined

    property alias text: field.text
    property string label: ""
    property string placeholder: ""
    property string supportingText: ""
    property string errorText: ""
    property bool isError: false
    property string leadingIcon: ""
    // Custom trailing icon (overrides the auto password/error icon if set).
    property string trailingIcon: ""
    property bool password: false
    property string prefixText: ""
    property string suffixText: ""
    property int maxLength: 0 // 0 = no limit / no counter
    property var validator: null
    property int inputMethodHints: Qt.ImhNone
    // Background colour behind the field; used to notch the outlined border
    // behind the floating label. Override on non-m3surface backgrounds.
    property color notchColour: Colours.palette.m3surface

    readonly property alias field: field
    readonly property bool hasContent: field.text.length > 0
    readonly property bool focused: field.activeFocus
    readonly property bool floating: focused || hasContent || prefixText.length > 0
    readonly property bool outlined: variant === M3TextField.Variant.Outlined

    // M3 disabled treatment: everything onSurface @ 38%.
    readonly property real disabledOpacity: 0.38

    // State-dependent colours (active path; disabled handled via opacity).
    readonly property color accent: !root.enabled ? Colours.palette.m3onSurface : (isError ? Colours.palette.m3error : (focused ? Colours.palette.m3primary : Colours.palette.m3outline))
    readonly property color labelColour: !root.enabled ? Colours.palette.m3onSurface : (isError ? Colours.palette.m3error : (focused ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant))
    readonly property color iconColour: !root.enabled ? Colours.palette.m3onSurface : (isError ? Colours.palette.m3error : (focused ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant))
    readonly property color supportColour: !root.enabled ? Colours.palette.m3onSurface : (isError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant)

    // Which trailing glyph: explicit > password toggle > error icon.
    readonly property string effectiveTrailingIcon: root.trailingIcon.length > 0 ? root.trailingIcon : (root.password ? (field.echoMode === TextInput.Password ? "visibility" : "visibility_off") : (root.isError ? "error" : ""))
    readonly property bool trailingInteractive: root.password && root.trailingIcon.length === 0

    signal accepted

    function forceFieldFocus(): void {
        field.forceActiveFocus();
    }

    implicitWidth: 240
    implicitHeight: 56 + (supportRow.visible ? supportRow.implicitHeight + Tokens.spacing.extraSmall : 0)

    // ---- Filled container ----------------------------------------------------
    StyledRect {
        id: filledBg

        visible: !root.outlined
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: 56

        topLeftRadius: Tokens.rounding.small
        topRightRadius: Tokens.rounding.small
        color: root.enabled ? (root.focused ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 1) : Colours.palette.m3surfaceContainerHigh) : Colours.palette.m3onSurface
        opacity: root.enabled ? 1 : 0.04 // M3 filled disabled container @ 4%

        StateLayer {
            anchors.fill: parent
            topLeftRadius: Tokens.rounding.small
            topRightRadius: Tokens.rounding.small
            color: root.isError ? Colours.palette.m3error : Colours.palette.m3onSurface
            disabled: !root.enabled
            onClicked: field.forceActiveFocus()
        }

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            implicitHeight: root.focused || root.isError ? 2 : 1
            color: root.accent
            opacity: root.enabled ? 1 : root.disabledOpacity

            Behavior on implicitHeight {
                Anim {
                    type: Anim.StandardSmall
                }
            }
            Behavior on color {
                CAnim {}
            }
        }

        Behavior on color {
            CAnim {}
        }
    }

    // ---- Outlined container --------------------------------------------------
    StyledRect {
        id: outline

        visible: root.outlined
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: 56

        color: "transparent"
        radius: Tokens.rounding.small
        border.width: root.focused || root.isError ? 2 : 1
        border.color: root.accent
        opacity: root.enabled ? 1 : root.disabledOpacity

        StateLayer {
            anchors.fill: parent
            anchors.margins: outline.border.width
            radius: Tokens.rounding.small
            color: root.isError ? Colours.palette.m3error : Colours.palette.m3onSurface
            disabled: !root.enabled
            onClicked: field.forceActiveFocus()
        }

        Behavior on border.color {
            CAnim {}
        }
        Behavior on border.width {
            Anim {
                type: Anim.StandardSmall
            }
        }
    }

    // Notch: hides the outline segment behind the floating label.
    Rectangle {
        visible: root.outlined && root.floating && root.label.length > 0
        color: root.notchColour
        opacity: root.enabled ? 1 : root.disabledOpacity
        x: labelText.x - Tokens.spacing.extraSmall / 2
        y: 0
        width: labelText.width + Tokens.spacing.extraSmall
        height: outline.border.width
    }

    // ---- Floating label ------------------------------------------------------
    StyledText {
        id: labelText

        visible: root.label.length > 0
        text: root.label
        color: root.labelColour
        opacity: root.enabled ? 1 : root.disabledOpacity

        x: root.floating ? (Tokens.padding.medium + Tokens.spacing.extraSmall / 2) : (leading.visible ? leading.x + leading.width + Tokens.spacing.small : Tokens.padding.medium)
        y: root.floating ? (root.outlined ? -height / 2 : Tokens.padding.extraSmall) : (56 - height) / 2

        font: root.floating ? Tokens.font.label.small : Tokens.font.body.medium

        Behavior on x {
            Anim {
                type: Anim.StandardSmall
            }
        }
        Behavior on y {
            Anim {
                type: Anim.StandardSmall
            }
        }
        Behavior on color {
            CAnim {}
        }
    }

    // ---- Leading icon --------------------------------------------------------
    MaterialIcon {
        id: leading

        visible: root.leadingIcon.length > 0
        text: root.leadingIcon
        color: root.iconColour
        opacity: root.enabled ? 1 : root.disabledOpacity
        fontStyle: Tokens.font.icon.medium

        anchors.left: parent.left
        anchors.leftMargin: Tokens.padding.medium
        anchors.top: parent.top
        anchors.topMargin: (56 - height) / 2

        Behavior on color {
            CAnim {}
        }
    }

    // ---- Trailing icon (password toggle / error / custom) --------------------
    MaterialIcon {
        id: trailing

        visible: root.effectiveTrailingIcon.length > 0
        text: root.effectiveTrailingIcon
        color: root.isError ? Colours.palette.m3error : (root.enabled ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface)
        opacity: root.enabled ? 1 : root.disabledOpacity
        fontStyle: Tokens.font.icon.medium

        anchors.right: parent.right
        anchors.rightMargin: Tokens.padding.medium
        anchors.top: parent.top
        anchors.topMargin: (56 - height) / 2

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Tokens.padding.small
            enabled: root.trailingInteractive && root.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: field.echoMode = field.echoMode === TextInput.Password ? TextInput.Normal : TextInput.Password
        }
    }

    // ---- Prefix --------------------------------------------------------------
    StyledText {
        id: prefix

        visible: root.prefixText.length > 0 && root.floating
        text: root.prefixText
        color: root.enabled ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
        opacity: root.enabled ? 1 : root.disabledOpacity
        font: Tokens.font.body.medium
        verticalAlignment: Text.AlignVCenter

        anchors.left: leading.visible ? leading.right : parent.left
        anchors.leftMargin: leading.visible ? Tokens.spacing.small : Tokens.padding.medium
        anchors.top: parent.top
        anchors.topMargin: root.floating && !root.outlined ? Tokens.font.label.small.pointSize + Tokens.padding.extraSmall : 0
        height: 56
    }

    // ---- Suffix --------------------------------------------------------------
    StyledText {
        id: suffix

        visible: root.suffixText.length > 0 && root.floating
        text: root.suffixText
        color: root.enabled ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
        opacity: root.enabled ? 1 : root.disabledOpacity
        font: Tokens.font.body.medium
        verticalAlignment: Text.AlignVCenter

        anchors.right: trailing.visible ? trailing.left : parent.right
        anchors.rightMargin: trailing.visible ? Tokens.spacing.small : Tokens.padding.medium
        anchors.top: parent.top
        anchors.topMargin: root.floating && !root.outlined ? Tokens.font.label.small.pointSize + Tokens.padding.extraSmall : 0
        height: 56
    }

    // ---- Input ---------------------------------------------------------------
    StyledTextField {
        id: field

        anchors.top: parent.top
        anchors.left: prefix.visible ? prefix.right : (leading.visible ? leading.right : parent.left)
        anchors.right: suffix.visible ? suffix.left : (trailing.visible ? trailing.left : parent.right)
        anchors.leftMargin: prefix.visible ? Tokens.spacing.extraSmall : (leading.visible ? Tokens.spacing.small : Tokens.padding.medium)
        anchors.rightMargin: suffix.visible ? Tokens.spacing.extraSmall : (trailing.visible ? Tokens.spacing.small : Tokens.padding.medium)
        height: 56

        verticalAlignment: TextInput.AlignVCenter
        topPadding: root.floating && !root.outlined ? Tokens.font.label.small.pointSize + Tokens.padding.extraSmall : 0

        echoMode: root.password ? TextInput.Password : TextInput.Normal
        placeholderText: root.focused ? root.placeholder : ""
        color: Colours.palette.m3onSurface
        opacity: root.enabled ? 1 : root.disabledOpacity
        validator: root.validator
        inputMethodHints: root.inputMethodHints
        enabled: root.enabled
        maximumLength: root.maxLength > 0 ? root.maxLength : 32767
        font: Tokens.font.body.medium

        onAccepted: root.accepted()
        onTextEdited: if (root.isError)
            root.isError = false
    }

    // ---- Supporting / error text + counter -----------------------------------
    Item {
        id: supportRow

        visible: (root.isError && root.errorText.length > 0) || root.supportingText.length > 0 || root.maxLength > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 56 + Tokens.spacing.extraSmall
        implicitHeight: Math.max(supportText.implicitHeight, counter.implicitHeight)

        StyledText {
            id: supportText

            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.medium
            anchors.right: counter.visible ? counter.left : parent.right
            anchors.rightMargin: Tokens.spacing.small

            text: root.isError && root.errorText.length > 0 ? root.errorText : root.supportingText
            color: root.supportColour
            opacity: root.enabled ? 1 : root.disabledOpacity
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        StyledText {
            id: counter

            visible: root.maxLength > 0
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.medium

            text: `${root.text.length}/${root.maxLength}`
            color: root.supportColour
            opacity: root.enabled ? 1 : root.disabledOpacity
            font: Tokens.font.label.small
        }
    }
}
