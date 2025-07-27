import qs.widgets
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: root
    
    signal sessionRequested(string username, string password, string session)
    
    property string usernameBuffer: ""
    property string passwordBuffer: ""
    property string selectedSession: "hyprland" // Default session
    property var availableSessions: []
    property string errorMessage: ""
    property bool isAuthenticating: false
    
    function reset(): void {
        usernameBuffer = "";
        passwordBuffer = "";
        errorMessage = "";
        isAuthenticating = false;
        usernameField.focus = true;
    }
    
    spacing: Appearance.spacing.large * 2
    
    Component.onCompleted: {
        // Set initial username to current user or empty
        usernameBuffer = Quickshell.env("USER") || "";
        // Sessions are loaded by SessionDetector
        availableSessions = sessionDetector.sessions;
        selectedSession = sessionDetector.defaultSession;
    }
    
    SessionDetector {
        id: sessionDetector
        
        onSessionsChanged: {
            root.availableSessions = sessions;
            if (!root.selectedSession || !sessions.find(s => s.id === root.selectedSession)) {
                root.selectedSession = defaultSession;
            }
        }
    }
    
    function authenticate(): void {
        if (isAuthenticating || !usernameBuffer || !passwordBuffer) return;
        
        isAuthenticating = true;
        errorMessage = "";
        
        // Use GreetdClient for authentication
        greetdClient.authenticate(usernameBuffer, passwordBuffer, selectedSession);
    }
    
    GreetdClient {
        id: greetdClient
        
        onAuthenticationSucceeded: {
            root.isAuthenticating = false;
            root.sessionRequested(root.usernameBuffer, root.passwordBuffer, root.selectedSession);
        }
        
        onAuthenticationFailed: message => {
            root.isAuthenticating = false;
            root.errorMessage = message || qsTr("Authentication failed");
            root.passwordBuffer = "";
            passwordField.focus = true;
            
            // Clear error after 3 seconds
            errorTimer.restart();
        }
    }
    
    Timer {
        id: errorTimer
        interval: 3000
        onTriggered: root.errorMessage = ""
    }
    
    // User info row
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Appearance.padding.large * 3
        Layout.maximumWidth: Config.lock.sizes.inputWidth - Appearance.rounding.large * 2
        
        spacing: Appearance.spacing.large
        
        StyledClippingRect {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Config.lock.sizes.faceSize
            implicitHeight: Config.lock.sizes.faceSize
            
            radius: Appearance.rounding.large
            color: Colours.palette.m3surfaceContainer
            
            MaterialIcon {
                anchors.centerIn: parent
                
                text: "person"
                fill: 1
                grade: 200
                font.pointSize: Config.lock.sizes.faceSize / 2
            }
            
            CachingImage {
                anchors.fill: parent
                path: usernameBuffer ? `${Paths.stringify(Paths.home)}/../${usernameBuffer}/.face` : ""
                visible: usernameBuffer !== ""
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.small
            
            StyledText {
                Layout.fillWidth: true
                text: qsTr("Welcome to %1").arg(Quickshell.env("HOSTNAME") || "System")
                font.pointSize: Appearance.font.size.extraLarge
                font.weight: 500
                elide: Text.ElideRight
            }
            
            StyledText {
                Layout.fillWidth: true
                text: errorMessage || qsTr("Please log in")
                color: errorMessage ? Colours.palette.m3error : Colours.palette.m3tertiary
                font.pointSize: Appearance.font.size.large
                elide: Text.ElideRight
            }
        }
    }
    
    // Username field
    StyledRect {
        id: usernameField
        
        Layout.fillWidth: true
        Layout.preferredWidth: Config.lock.sizes.inputWidth
        Layout.preferredHeight: Appearance.font.size.normal + Appearance.padding.large * 2
        
        focus: true
        color: Colours.palette.m3surfaceContainer
        radius: Appearance.rounding.small
        
        Keys.onPressed: event => {
            if (isAuthenticating) return;
            
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Tab) {
                passwordField.focus = true;
            } else if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier) {
                    root.usernameBuffer = "";
                } else {
                    root.usernameBuffer = root.usernameBuffer.slice(0, -1);
                }
            } else if (event.text && event.text.length === 1) {
                root.usernameBuffer += event.text;
            }
        }
        
        StyledText {
            anchors.centerIn: parent
            
            text: root.usernameBuffer || qsTr("Username")
            color: root.usernameBuffer ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.larger
        }
    }
    
    // Password field
    StyledRect {
        id: passwordField
        
        Layout.fillWidth: true
        Layout.preferredWidth: Config.lock.sizes.inputWidth
        Layout.preferredHeight: Appearance.font.size.normal + Appearance.padding.large * 2
        
        color: Colours.palette.m3surfaceContainer
        radius: Appearance.rounding.small
        clip: true
        
        Keys.onPressed: event => {
            if (isAuthenticating) return;
            
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                root.authenticate();
            } else if (event.key === Qt.Key_Tab) {
                sessionDropdown.focus = true;
            } else if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier) {
                    charList.implicitWidth = charList.implicitWidth; // Break binding
                    root.passwordBuffer = "";
                } else {
                    root.passwordBuffer = root.passwordBuffer.slice(0, -1);
                }
            } else if (event.text && event.text.length === 1) {
                charList.bindImWidth();
                root.passwordBuffer += event.text;
            }
        }
        
        StyledText {
            id: passwordPlaceholder
            
            anchors.centerIn: parent
            
            text: isAuthenticating ? qsTr("Authenticating...") : qsTr("Password")
            color: isAuthenticating ? Colours.palette.m3secondary : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.larger
            
            opacity: root.passwordBuffer ? 0 : 1
            
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }
        
        ListView {
            id: charList
            
            function bindImWidth(): void {
                imWidthBehavior.enabled = false;
                implicitWidth = Qt.binding(() => Math.min(count * (Appearance.font.size.normal + spacing) - spacing, Config.lock.sizes.inputWidth - Appearance.rounding.large * 2 - Appearance.padding.large * 5));
                imWidthBehavior.enabled = true;
            }
            
            anchors.centerIn: parent
            
            implicitWidth: Math.min(count * (Appearance.font.size.normal + spacing) - spacing, Config.lock.sizes.inputWidth - Appearance.rounding.large * 2 - Appearance.padding.large * 5)
            implicitHeight: Appearance.font.size.normal
            
            orientation: Qt.Horizontal
            spacing: Appearance.spacing.small / 2
            interactive: false
            
            model: ScriptModel {
                values: root.passwordBuffer.split("")
            }
            
            delegate: StyledRect {
                id: ch
                
                implicitWidth: Appearance.font.size.normal
                implicitHeight: Appearance.font.size.normal
                
                color: Colours.palette.m3onSurface
                radius: Appearance.rounding.full
                
                opacity: 0
                scale: 0.5
                Component.onCompleted: {
                    opacity = 1;
                    scale = 1;
                }
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }
            
            Behavior on implicitWidth {
                id: imWidthBehavior
                
                NumberAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }
    }
    
    // Session dropdown
    StyledRect {
        id: sessionDropdown
        
        Layout.fillWidth: true
        Layout.preferredWidth: Config.lock.sizes.inputWidth
        Layout.preferredHeight: Appearance.font.size.normal + Appearance.padding.large * 2
        
        color: Colours.palette.m3surfaceContainer
        radius: Appearance.rounding.small
        
        property bool expanded: false
        
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                sessionDropdown.expanded = !sessionDropdown.expanded;
            } else if (event.key === Qt.Key_Tab) {
                usernameField.focus = true;
            } else if (event.key === Qt.Key_Escape && sessionDropdown.expanded) {
                sessionDropdown.expanded = false;
            }
        }
        
        StateLayer {
            radius: parent.radius
            color: Colours.palette.m3onSurface
            
            function onClicked(): void {
                sessionDropdown.expanded = !sessionDropdown.expanded;
            }
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            
            StyledText {
                Layout.fillWidth: true
                text: {
                    const session = root.availableSessions.find(s => s.id === root.selectedSession);
                    return session ? session.name : root.selectedSession;
                }
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.larger
                elide: Text.ElideRight
            }
            
            MaterialIcon {
                text: sessionDropdown.expanded ? "expand_less" : "expand_more"
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.larger
            }
        }
        
        // Dropdown menu
        StyledRect {
            anchors.top: parent.bottom
            anchors.topMargin: Appearance.spacing.small
            anchors.left: parent.left
            anchors.right: parent.right
            
            implicitHeight: sessionList.contentHeight
            
            visible: sessionDropdown.expanded
            color: Colours.palette.m3surfaceContainer
            radius: Appearance.rounding.small
            clip: true
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.5)
            }
            
            ListView {
                id: sessionList
                
                anchors.fill: parent
                
                model: root.availableSessions
                interactive: contentHeight > height
                
                delegate: ItemDelegate {
                    width: parent.width
                    height: Appearance.font.size.normal + Appearance.padding.large * 2
                    
                    background: StateLayer {
                        color: Colours.palette.m3onSurface
                        
                        function onClicked(): void {
                            root.selectedSession = modelData.id;
                            sessionDropdown.expanded = false;
                        }
                    }
                    
                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.larger
                    }
                }
            }
        }
    }
}