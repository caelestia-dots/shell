pragma Singleton

import QtQuick
import Quickshell.Services.Greetd

QtObject {
    id: root
    
    property string currentUser: ""
    property string currentSession: ""
    property bool isAuthenticating: false
    property string authMessage: ""
    property string authError: ""
    
    readonly property bool available: Greetd.available
    readonly property var state: Greetd.state
    
    // Internal connections handler
    property Connections greetdConnections: Connections {
        target: Greetd
        
        function onAuthMessage(message: string, error: bool): void {
            if (error) {
                root.authError = message;
                root.authMessage = "";
            } else {
                root.authMessage = message;
                root.authError = "";
            }
        }
        
        function onReadyToLaunch(): void {
            // Launch the session
            Greetd.launch(root.currentSession);
        }
        
        function onAuthFailure(): void {
            root.authError = "Authentication failed";
            root.isAuthenticating = false;
        }
        
        function onError(error: string): void {
            root.authError = error;
            root.isAuthenticating = false;
        }
        
        function onLaunched(): void {
            // Greetd has acknowledged the launch
            // The greeter should exit
            Qt.quit();
        }
    }
    
    function startAuthentication(username: string, session: string): void {
        if (!Greetd.available || isAuthenticating) return;
        
        currentUser = username;
        currentSession = session;
        isAuthenticating = true;
        authMessage = "";
        authError = "";
        
        Greetd.createSession(username);
    }
    
    function respond(password: string): void {
        if (!isAuthenticating) return;
        Greetd.respond(password);
    }
    
    function cancel(): void {
        isAuthenticating = false;
        currentUser = "";
        currentSession = "";
        authMessage = "";
        authError = "";
        // Reset greetd state if needed
        // The proper way depends on the greetd API version
    }
}