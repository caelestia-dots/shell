pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session
    property bool showHeader: true
    property int pendingSwitchIndex: -1

    spacing: Appearance.spacing.normal

    Connections {
        target: VPN
        function onConnectedChanged() {
            if (!VPN.connected && root.pendingSwitchIndex >= 0) {
                const targetIndex = root.pendingSwitchIndex;
                root.pendingSwitchIndex = -1;
                
                const providers = [];
                for (let i = 0; i < Config.utilities.vpn.provider.length; i++) {
                    const p = Config.utilities.vpn.provider[i];
                    if (typeof p === "object") {
                        const newProvider = {
                            name: p.name,
                            displayName: p.displayName,
                            interface: p.interface,
                            enabled: (i === targetIndex)
                        };
                        providers.push(newProvider);
                    } else {
                        providers.push(p);
                    }
                }
                Config.utilities.vpn.provider = providers;
                Config.save();
                
                Qt.callLater(function() {
                    VPN.toggle();
                });
            }
        }
    }

    TextButton {
        Layout.fillWidth: true
        text: qsTr("+ Add VPN Provider")
        inactiveColour: Colours.palette.m3primaryContainer
        inactiveOnColour: Colours.palette.m3onPrimaryContainer

        onClicked: {
            vpnDialog.showProviderSelection();
        }
    }

    ListView {
        id: listView

        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight

        interactive: false
        spacing: Appearance.spacing.smaller

        model: ScriptModel {
            values: Config.utilities.vpn.provider.map((provider, index) => {
                const isObject = typeof provider === "object";
                const name = isObject ? (provider.name || "custom") : String(provider);
                const displayName = isObject ? (provider.displayName || name) : name;
                const iface = isObject ? (provider.interface || "") : "";
                const enabled = isObject ? (provider.enabled === true) : false;
                
                return {
                    index: index,
                    name: name,
                    displayName: displayName,
                    interface: iface,
                    provider: provider,
                    enabled: enabled
                };
            })
        }

        delegate: Component {
            StyledRect {
                required property var modelData
                required property int index

                width: ListView.view ? ListView.view.width : undefined

                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (root.session && root.session.vpn && root.session.vpn.active === modelData) ? Colours.tPalette.m3surfaceContainer.a : 0)
                radius: Appearance.rounding.normal

                StateLayer {
                    function onClicked(): void {
                        if (root.session && root.session.vpn) {
                            root.session.vpn.active = modelData;
                        }
                    }
                }

                RowLayout {
                    id: rowLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.normal

                    spacing: Appearance.spacing.normal

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: icon.implicitHeight + Appearance.padding.normal * 2

                        radius: Appearance.rounding.normal
                        color: modelData.enabled && VPN.connected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                        MaterialIcon {
                            id: icon

                            anchors.centerIn: parent
                            text: modelData.enabled && VPN.connected ? "vpn_key" : "vpn_key_off"
                            font.pointSize: Appearance.font.size.large
                            fill: modelData.enabled && VPN.connected ? 1 : 0
                            color: modelData.enabled && VPN.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1

                            text: modelData.displayName || qsTr("Unknown")
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.smaller

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    if (modelData.enabled && VPN.connected) return qsTr("Connected");
                                    if (modelData.enabled && VPN.connecting) return qsTr("Connecting...");
                                    if (modelData.enabled) return qsTr("Enabled");
                                    return qsTr("Disabled");
                                }
                                color: modelData.enabled ? (VPN.connected ? Colours.palette.m3primary : Colours.palette.m3onSurface) : Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.small
                                font.weight: modelData.enabled && VPN.connected ? 500 : 400
                                elide: Text.ElideRight
                            }
                        }
                    }

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: connectIcon.implicitHeight + Appearance.padding.smaller * 2

                        radius: Appearance.rounding.full
                        color: Qt.alpha(Colours.palette.m3primaryContainer, VPN.connected && modelData.enabled ? 1 : 0)

                        StateLayer {
                            enabled: !VPN.connecting
                            function onClicked(): void {
                                const clickedIndex = modelData.index;

                                if (modelData.enabled) {
                                    VPN.toggle();
                                } else {
                                    if (VPN.connected) {
                                        root.pendingSwitchIndex = clickedIndex;
                                        VPN.toggle();
                                    } else {
                                        const providers = [];
                                        for (let i = 0; i < Config.utilities.vpn.provider.length; i++) {
                                            const p = Config.utilities.vpn.provider[i];
                                            if (typeof p === "object") {
                                                const newProvider = {
                                                    name: p.name,
                                                    displayName: p.displayName,
                                                    interface: p.interface,
                                                    enabled: (i === clickedIndex)
                                                };
                                                providers.push(newProvider);
                                            } else {
                                                providers.push(p);
                                            }
                                        }
                                        Config.utilities.vpn.provider = providers;
                                        Config.save();

                                        Qt.callLater(function() {
                                            VPN.toggle();
                                        });
                                    }
                                }
                            }
                        }

                        MaterialIcon {
                            id: connectIcon

                            anchors.centerIn: parent
                            text: VPN.connected && modelData.enabled ? "link_off" : "link"
                            color: VPN.connected && modelData.enabled ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        }
                    }

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: deleteIcon.implicitHeight + Appearance.padding.smaller * 2

                        radius: Appearance.rounding.full
                        color: "transparent"

                        StateLayer {
                            function onClicked(): void {
                                const providers = [];
                                for (let i = 0; i < Config.utilities.vpn.provider.length; i++) {
                                    if (i !== modelData.index) {
                                        providers.push(Config.utilities.vpn.provider[i]);
                                    }
                                }
                                Config.utilities.vpn.provider = providers;
                                Config.save();
                            }
                        }

                        MaterialIcon {
                            id: deleteIcon

                            anchors.centerIn: parent
                            text: "delete"
                            color: Colours.palette.m3onSurface
                        }
                    }
                }

                implicitHeight: rowLayout.implicitHeight + Appearance.padding.normal * 2
            }
        }
    }
    
    Popup {
        id: vpnDialog

        property string currentState: "selection"
        property int editIndex: -1
        property string providerName: ""
        property string displayName: ""
        property string interfaceName: ""
        property bool isClosing: false

        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        implicitWidth: Math.min(400, parent.width - Appearance.padding.large * 2)
        padding: Appearance.padding.large

        modal: true
        closePolicy: Popup.NoAutoClose

        opacity: 0
        scale: 0.7

        function showProviderSelection(): void {
            currentState = "selection";
            isClosing = false;
            open();
        }

        function closeWithAnimation(): void {
            if (isClosing) return;
            isClosing = true;
            closeAnim.start();
        }

        function showAddForm(providerType: string, defaultDisplayName: string): void {
            editIndex = -1;
            providerName = providerType;
            displayName = defaultDisplayName;
            interfaceName = "";

            if (currentState === "selection") {
                transitionToForm.start();
            } else {
                currentState = "form";
                isClosing = false;
                open();
            }
        }

        function showEditForm(index: int): void {
            const provider = Config.utilities.vpn.provider[index];
            const isObject = typeof provider === "object";

            editIndex = index;
            providerName = isObject ? (provider.name || "custom") : String(provider);
            displayName = isObject ? (provider.displayName || providerName) : providerName;
            interfaceName = isObject ? (provider.interface || "") : "";

            currentState = "form";
            isClosing = false;
            open();
        }

        Keys.onEscapePressed: event => {
            event.accepted = true;
            closeWithAnimation();
        }

        Overlay.modal: MouseArea {
            onClicked: vpnDialog.closeWithAnimation()
        }

        onAboutToShow: {
            opacity = 0;
            scale = 0.7;
            isClosing = false;
        }

        onOpened: {
            openAnim.start();
        }

        onClosed: {
            currentState = "selection";
            isClosing = false;
        }

        ParallelAnimation {
            id: openAnim
            NumberAnimation {
                target: vpnDialog
                property: "opacity"
                to: 1
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
            NumberAnimation {
                target: vpnDialog
                property: "scale"
                to: 1
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        ParallelAnimation {
            id: closeAnim
            NumberAnimation {
                target: vpnDialog
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
            NumberAnimation {
                target: vpnDialog
                property: "scale"
                to: 0.7
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
            onFinished: {
                vpnDialog.close();
            }
        }

        SequentialAnimation {
            id: transitionToForm

            ParallelAnimation {
                NumberAnimation {
                    target: selectionContent
                    property: "opacity"
                    to: 0
                    duration: Appearance.anim.durations.small
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            ScriptAction {
                script: {
                    vpnDialog.currentState = "form";
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: formContent
                    property: "opacity"
                    to: 1
                    duration: Appearance.anim.durations.small
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
        }

        background: StyledRect {
            color: Colours.palette.m3surfaceContainerHigh
            radius: Appearance.rounding.large

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
        }

        contentItem: Item {
            implicitHeight: vpnDialog.currentState === "selection" ? selectionContent.implicitHeight : formContent.implicitHeight

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            ColumnLayout {
                id: selectionContent
                
                anchors.fill: parent
                spacing: Appearance.spacing.normal
                visible: vpnDialog.currentState === "selection"
                opacity: vpnDialog.currentState === "selection" ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.anim.durations.small
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }
                
                StyledText {
                    text: qsTr("Add VPN Provider")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Choose a provider to add")
                    wrapMode: Text.WordWrap
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                }

                Item { Layout.preferredHeight: Appearance.spacing.small }

                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("NetBird")
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurface
                    onClicked: {
                        const providers = [];
                        for (let i = 0; i < Config.utilities.vpn.provider.length; i++) {
                            providers.push(Config.utilities.vpn.provider[i]);
                        }
                        providers.push({ name: "netbird", displayName: "NetBird", interface: "wt0" });
                        Config.utilities.vpn.provider = providers;
                        Config.save();
                        vpnDialog.closeWithAnimation();
                    }
                }
                
                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Tailscale")
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurface
                    onClicked: {
                        const providers = [];
                        for (let i = 0; i < Config.utilities.vpn.provider.length; i++) {
                            providers.push(Config.utilities.vpn.provider[i]);
                        }
                        providers.push({ name: "tailscale", displayName: "Tailscale", interface: "tailscale0" });
                        Config.utilities.vpn.provider = providers;
                        Config.save();
                        vpnDialog.closeWithAnimation();
                    }
                }
                
                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Cloudflare WARP")
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurface
                    onClicked: {
                        const providers = [];
                        for (let i = 0; i < Config.utilities.vpn.provider.length; i++) {
                            providers.push(Config.utilities.vpn.provider[i]);
                        }
                        providers.push({ name: "warp", displayName: "Cloudflare WARP", interface: "CloudflareWARP" });
                        Config.utilities.vpn.provider = providers;
                        Config.save();
                        vpnDialog.closeWithAnimation();
                    }
                }
                
                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("WireGuard (Custom)")
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurface
                    onClicked: {
                        vpnDialog.showAddForm("wireguard", "WireGuard");
                    }
                }

                Item { Layout.preferredHeight: Appearance.spacing.small }

                TextButton {
                    Layout.fillWidth: true
                    text: qsTr("Cancel")
                    inactiveColour: Colours.palette.m3secondaryContainer
                    inactiveOnColour: Colours.palette.m3onSecondaryContainer
                    onClicked: vpnDialog.closeWithAnimation()
                }
            }

            ColumnLayout {
                id: formContent
                
                anchors.fill: parent
                spacing: Appearance.spacing.normal
                visible: vpnDialog.currentState === "form"
                opacity: vpnDialog.currentState === "form" ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.anim.durations.small
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }
                
                StyledText {
                    text: vpnDialog.editIndex >= 0 ? qsTr("Edit VPN Provider") : qsTr("Add %1 VPN").arg(vpnDialog.displayName)
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }

                TextField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("Display Name")
                    text: vpnDialog.displayName
                    onTextChanged: vpnDialog.displayName = text
                }

                TextField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("Interface (e.g., wg0, torguard)")
                    text: vpnDialog.interfaceName
                    onTextChanged: vpnDialog.interfaceName = text
                }

                Item { Layout.preferredHeight: Appearance.spacing.normal }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Cancel")
                        inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                        inactiveOnColour: Colours.palette.m3onSurface
                        onClicked: vpnDialog.closeWithAnimation()
                    }

                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Save")
                        enabled: vpnDialog.interfaceName.length > 0
                        inactiveColour: Colours.palette.m3primaryContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer

                        onClicked: {
                            const providers = [];
                            const newProvider = {
                                name: vpnDialog.providerName,
                                displayName: vpnDialog.displayName || vpnDialog.interfaceName,
                                interface: vpnDialog.interfaceName
                            };

                            if (vpnDialog.editIndex >= 0) {
                                for (let i = 0; i < Config.utilities.vpn.provider.length; i++) {
                                    if (i === vpnDialog.editIndex) {
                                        providers.push(newProvider);
                                    } else {
                                        providers.push(Config.utilities.vpn.provider[i]);
                                    }
                                }
                            } else {
                                for (let i = 0; i < Config.utilities.vpn.provider.length; i++) {
                                    providers.push(Config.utilities.vpn.provider[i]);
                                }
                                providers.push(newProvider);
                            }
                            
                            Config.utilities.vpn.provider = providers;
                            Config.save();
                            vpnDialog.closeWithAnimation();
                        }
                    }
                }
            }
        }
    }
}
