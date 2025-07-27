pragma ComponentBehavior: Bound

import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Effects

ShellRoot {
    id: root
    
    signal sessionStarted()
    
    function reset(): void {
        greetdInput.reset();
    }
    
    anchors.fill: parent
    color: "transparent"
    
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
    
    Backgrounds {
        id: backgrounds
        
        weatherWidth: weather.implicitWidth
        buttonsWidth: buttons.nonAnimWidth ?? 0
        buttonsHeight: buttons.nonAnimHeight ?? 0
        statusWidth: status.nonAnimWidth ?? 0
        statusHeight: status.nonAnimHeight ?? 0
        isNormal: root.width > Config.lock.sizes.smallScreenWidth
        isLarge: root.width > Config.lock.sizes.largeScreenWidth
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
        }
    }
    
    Clock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: -backgrounds.clockBottom
    }
    
    GreetdInput {
        id: greetdInput
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: -backgrounds.inputTop
        
        onSessionRequested: (username, password, session) => {
            // This will be handled by the greetd authentication process
            root.sessionStarted();
        }
    }
    
    WeatherInfo {
        id: weather
        
        anchors.top: parent.bottom
        anchors.right: parent.left
        anchors.topMargin: -backgrounds.weatherTop
        anchors.rightMargin: -backgrounds.weatherRight
    }
    
    Buttons {
        id: buttons
        
        anchors.top: parent.bottom
        anchors.left: parent.right
        anchors.topMargin: -backgrounds.buttonsTop
        anchors.leftMargin: -backgrounds.buttonsLeft
        
        visible: root.width > Config.lock.sizes.largeScreenWidth
    }
    
    Status {
        id: status
        
        anchors.bottom: parent.top
        anchors.left: parent.right
        anchors.bottomMargin: -backgrounds.statusBottom
        anchors.leftMargin: -backgrounds.statusLeft
        
        showNotifs: false // No notifications on login screen
    }
}