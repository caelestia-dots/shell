pragma ComponentBehavior: Bound

import "./deps/services"
import "./deps/config"
import Quickshell
import QtQuick
import QtQuick.Effects

Item {
    id: root
    
    signal sessionStarted()
    
    function reset(): void {
        greetdInput.reset();
    }
    
    // Background with blur effect
    Item {
        id: background
        
        anchors.fill: parent
        
        // Wallpaper or solid color background
        Rectangle {
            anchors.fill: parent
            color: Colours.palette.m3surface
        }
        
        // Optional: Add wallpaper support
        Image {
            anchors.fill: parent
            source: Config.paths.wallpaper || ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: source != ""
            
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 0.5
                blurMax: 64
                blurMultiplier: 1
            }
        }
    }
    
    // Hide the original Backgrounds component since we'll use simpler backgrounds
    Backgrounds {
        id: backgrounds
        
        visible: false
        locked: true
        buttonsWidth: 50
        buttonsHeight: 50
        isNormal: root.width > Config.lock.sizes.smallScreenWidth
        isLarge: root.width > Config.lock.sizes.largeScreenWidth
    }
    
    // Clock with background at top
    Item {
        id: clockContainer
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 50
        width: Config.lock.sizes.clockWidth
        height: Config.lock.sizes.clockHeight
        
        Rectangle {
            anchors.fill: parent
            color: Colours.palette.m3surface
            radius: Appearance.rounding.large * 2
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
            }
        }
        
        Clock {
            anchors.centerIn: parent
        }
    }
    
    // Input with background at bottom
    Item {
        id: inputContainer
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 100
        width: Config.lock.sizes.inputWidth
        height: Config.lock.sizes.inputHeight
        
        Rectangle {
            anchors.fill: parent
            color: Colours.palette.m3surface
            radius: Appearance.rounding.large * 2
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
            }
        }
        
        GreetdInput {
            id: greetdInput
            
            anchors.fill: parent
            anchors.margins: 20
            
            onSessionRequested: (username, password, session) => {
                // This will be handled by the greetd authentication process
                root.sessionStarted();
            }
        }
    }
    
    // Power buttons in bottom right
    Buttons {
        id: buttons
        
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 40
        
        visible: root.width > Config.lock.sizes.largeScreenWidth
    }
}