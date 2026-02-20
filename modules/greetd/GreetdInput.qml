import "./deps/widgets"
import "./deps/services"
import "./deps/config"
import "./deps/utils"
import "./"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

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
    
    spacing: Appearance.spacing.large
    
    SessionDetector {
        id: sessionDetector
    }
    
    Component.onCompleted: {
        // Try to get the last logged-in user from environment
        // This is set in the caelestia-greetd script
        usernameBuffer = Quickshell.env("LAST_USER") || "";
        // Load sessions from SessionDetector
        root.availableSessions = sessionDetector.sessions;
        root.selectedSession = sessionDetector.defaultSession;
        
        // If username is pre-populated, focus on password field
        if (usernameBuffer) {
            passwordField.focus = true;
        } else {
            usernameField.focus = true;
        }
    }
    
    function authenticate(): void {
        if (isAuthenticating || !usernameBuffer || !passwordBuffer) return;
        
        isAuthenticating = true;
        errorMessage = "";
        
        // Use GreetdClient for authentication
        GreetdClient.startAuthentication(usernameBuffer, selectedSession);
    }
    
    Connections {
        target: GreetdClient
        
        function onAuthMessageChanged(): void {
            if (GreetdClient.authMessage && GreetdClient.authMessage.toLowerCase().includes("password")) {
                // Respond with password when prompted
                GreetdClient.respond(root.passwordBuffer);
            }
        }
        
        function onAuthErrorChanged(): void {
            if (GreetdClient.authError) {
                root.isAuthenticating = false;
                root.errorMessage = GreetdClient.authError;
                root.passwordBuffer = "";
                passwordField.focus = true;
                
                // Clear error after 3 seconds
                errorTimer.restart();
            }
        }
        
        function onIsAuthenticatingChanged(): void {
            root.isAuthenticating = GreetdClient.isAuthenticating;
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
        Layout.topMargin: Appearance.padding.large
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
                font.pointSize: Appearance.font.size.large
                font.weight: 500
                elide: Text.ElideRight
            }
            
            StyledText {
                Layout.fillWidth: true
                text: errorMessage || qsTr("Please log in")
                color: errorMessage ? Colours.palette.m3error : Colours.palette.m3tertiary
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
            }
        }
    }
    
    // Username field
    StyledRect {
        id: usernameField
        
        Layout.fillWidth: true
        Layout.preferredWidth: Config.lock.sizes.inputWidth
        Layout.preferredHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
        
        focus: false
        color: Colours.palette.m3surfaceContainer
        radius: Appearance.rounding.small
        border.width: activeFocus ? 2 : 0
        border.color: Colours.palette.m3primary
        
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
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: usernameField.focus = true
        }
        
        StyledText {
            anchors.centerIn: parent
            
            text: root.usernameBuffer || qsTr("Username")
            color: root.usernameBuffer ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.normal
        }
    }
    
    // Password field
    StyledRect {
        id: passwordField
        
        Layout.fillWidth: true
        Layout.preferredWidth: Config.lock.sizes.inputWidth
        Layout.preferredHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
        
        color: Colours.palette.m3surfaceContainer
        radius: Appearance.rounding.small
        clip: true
        border.width: activeFocus ? 2 : 0
        border.color: Colours.palette.m3primary
        
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
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: passwordField.focus = true
        }
        
        StyledText {
            id: passwordPlaceholder
            
            anchors.centerIn: parent
            
            text: isAuthenticating ? qsTr("Authenticating...") : qsTr("Password")
            color: isAuthenticating ? Colours.palette.m3secondary : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.normal
            
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
        Layout.preferredHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
        
        color: Colours.palette.m3surfaceContainer
        radius: Appearance.rounding.small
        border.width: activeFocus ? 2 : 0
        border.color: Colours.palette.m3primary
        
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
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            anchors.verticalCenter: parent.verticalCenter
            
            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: {
                    const session = root.availableSessions.find(s => s.id === root.selectedSession);
                    return session ? session.name : root.selectedSession;
                }
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
            
            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: sessionDropdown.expanded ? "expand_less" : "expand_more"
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal
            }
        }
        
        // Dropdown menu (opens upward)
        StyledRect {
            anchors.bottom: parent.top
            anchors.bottomMargin: Appearance.spacing.small
            anchors.left: parent.left
            anchors.right: parent.right
            
            implicitHeight: Math.min(sessionList.contentHeight, 150) // Limit max height
            
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
                    height: Appearance.font.size.normal + Appearance.padding.normal * 2
                    
                    onClicked: {
                        root.selectedSession = modelData.id;
                        sessionDropdown.expanded = false;
                        sessionDropdown.focus = true;
                    }
                    
                    background: StateLayer {
                        color: Colours.palette.m3onSurface
                    }
                    
                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.normal
                    }
                }
            }
        }
    }
    
    // Login button
    StyledRect {
        id: loginButton
        
        Layout.fillWidth: true
        Layout.preferredWidth: Config.lock.sizes.inputWidth
        Layout.preferredHeight: Appearance.font.size.normal + Appearance.padding.normal * 2
        Layout.topMargin: Appearance.spacing.normal
        
        color: isAuthenticating ? Colours.palette.m3secondaryContainer : Colours.palette.m3primary
        radius: Appearance.rounding.small
        
        enabled: !isAuthenticating && usernameBuffer && passwordBuffer
        opacity: enabled ? 1 : 0.5
        
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
        
        Behavior on color {
            ColorAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
        
        StateLayer {
            radius: parent.radius
            color: Colours.palette.m3onPrimary
            enabled: parent.enabled
            
            function onClicked(): void {
                if (parent.enabled) {
                    root.authenticate();
                }
            }
        }
        
        RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.small
            
            MaterialIcon {
                visible: isAuthenticating
                text: "progress_activity"
                color: Colours.palette.m3onSecondaryContainer
                font.pointSize: Appearance.font.size.normal
                
                RotationAnimation on rotation {
                    running: isAuthenticating
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
            
            StyledText {
                text: isAuthenticating ? qsTr("Logging in...") : qsTr("Log In")
                color: isAuthenticating ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onPrimary
                font.pointSize: Appearance.font.size.normal
                font.weight: 600
            }
        }
    }
}