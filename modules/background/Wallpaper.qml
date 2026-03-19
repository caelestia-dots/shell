pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.components.filedialog
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Item {
    id: root

    property string source: Wallpapers.current
    property Image current: one
    property string transitionType: Config.background.wallpaperTransition ?? "fade"
    property string activeTransitionType: "fade"
    property real transitionProgress: 0
    property real wipeDirection: 0
    property real discCenterX: 0.5
    property real discCenterY: 0.5
    property real stripesCount: 16
    property real stripesAngle: 0
    readonly property bool transitioning: transitionAnimation.running
    property string pendingWallpaper: ""
    readonly property var availableTransitions: ["fade", "wipe", "disc", "stripes"]

    anchors.fill: parent

    function getScheduledWallpaper() {
        try {
            if (!root.enabled) return "";
            
            const tbw = Config.background.timeBasedWallpaper;
            if (tbw !== true) return "";
            
            const schedule = Config.background.wallpaperSchedule;
            if (!schedule || schedule.length === 0) return "";
            
            const now = new Date();
            const currentMinutes = now.getHours() * 60 + now.getMinutes();
            
            for (let i = 0; i < schedule.length; i++) {
                const entry = schedule[i];
                if (!entry || !entry.startTime || !entry.wallpaper) continue;
                
                const timeParts = entry.startTime.split(":");
                if (timeParts.length !== 2) continue;
                
                const startMinutes = parseInt(timeParts[0]) * 60 + parseInt(timeParts[1]);
                if (isNaN(startMinutes)) continue;
                
                let endMinutes = 24 * 60;
                if (i < schedule.length - 1) {
                    const nextEntry = schedule[i + 1];
                    if (nextEntry && nextEntry.startTime) {
                        const nextParts = nextEntry.startTime.split(":");
                        if (nextParts.length === 2) {
                            const nextMinutes = parseInt(nextParts[0]) * 60 + parseInt(nextParts[1]);
                            if (!isNaN(nextMinutes)) {
                                endMinutes = nextMinutes;
                            }
                        }
                    }
                }
                
                if (startMinutes <= currentMinutes && currentMinutes < endMinutes) {
                    return entry.wallpaper;
                }
            }
            if (schedule.length > 0 && schedule[0].wallpaper) {
                return schedule[0].wallpaper;
            }
            
            return "";
        } catch (e) {
            console.error("Error in getScheduledWallpaper:", e);
            return "";
        }
    }

    function setWallpaperWithTransition(newSource) {
        if (newSource === one.path) {
            return;
        }

        if (transitioning) {
            transitionAnimation.stop();
            transitionProgress = 0;
            const newCurrentSource = two.path;
            one.path = newCurrentSource;
            Qt.callLater(() => {
                two.path = "";
                Qt.callLater(() => {
                    two.path = newSource;
                    transitionAnimation.start();
                });
            });
            return;
        }

        two.path = newSource;
        transitionAnimation.start();
    }

    function changeWallpaper() {
        if (transitionType === "random") {
            const index = Math.floor(Math.random() * availableTransitions.length);
            activeTransitionType = availableTransitions[index];
        } else {
            activeTransitionType = transitionType;
        }

        if (activeTransitionType === "wipe")
            wipeDirection = Math.random() * 4;
        else if (activeTransitionType === "disc") {
            discCenterX = Math.random();
            discCenterY = Math.random();
        } else if (activeTransitionType === "stripes") {
            stripesCount = Math.round(Math.random() * 20 + 4);
            stripesAngle = Math.random() * 360;
        }
        setWallpaperWithTransition(pendingWallpaper);
    }

    onSourceChanged: {
        if (!source) {
            current = null;
        } else if (!one.path) {
            one.path = source;
            transitionProgress = 0;
        } else if (source === one.path) {
            debounceTimer.stop();
            initialDelayTimer.stop();
            pendingWallpaper = "";
        } else {
            pendingWallpaper = source;
            if (transitioning || debounceTimer.running) {
                debounceTimer.restart();
            } else if (initialDelayTimer.running) {
                initialDelayTimer.restart();
            } else {
                initialDelayTimer.start();
            }
        }
    }

    Timer {
        id: initialDelayTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (pendingWallpaper && pendingWallpaper !== one.path && pendingWallpaper === source) {
                changeWallpaper();
            }
        }
    }

    Timer {
        id: debounceTimer
        interval: 1100
        repeat: false
        onTriggered: {
            if (pendingWallpaper && pendingWallpaper !== one.path && pendingWallpaper === source) {
                changeWallpaper();
            }
        }
    }

    Timer {
        id: autoRandomTimer
        interval: 300000
        running: false
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            Quickshell.execDetached(["caelestia", "wallpaper", "--random"]);
        }
    }

    Timer {
        id: timeBasedTimer
        interval: 60000
        running: false
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            if (Config.background && Config.background.timeBasedWallpaper === true) {
                const scheduledWallpaper = getScheduledWallpaper();
                
                if (scheduledWallpaper) {
                    // Expand ~ to home directory
                    let expandedPath = scheduledWallpaper;
                    if (scheduledWallpaper.startsWith("~/")) {
                        expandedPath = Quickshell.env("HOME") + scheduledWallpaper.substring(1);
                    }
                    
                    if (expandedPath !== one.path) {
                        console.log("Time-based wallpaper change:", expandedPath);
                        Quickshell.execDetached(["caelestia", "wallpaper", "-f", expandedPath]);
                    }
                }
            }
        }
    }
    
    Timer {
        id: minuteAlignTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            // Check schedule immediately when aligned to minute
            if (Config.background && Config.background.timeBasedWallpaper === true) {
                const scheduledWallpaper = getScheduledWallpaper();
                
                if (scheduledWallpaper) {
                    let expandedPath = scheduledWallpaper;
                    if (scheduledWallpaper.startsWith("~/")) {
                        expandedPath = Quickshell.env("HOME") + scheduledWallpaper.substring(1);
                    }
                    
                    if (expandedPath !== one.path) {
                        console.log("Time-based wallpaper change (startup):", expandedPath);
                        Quickshell.execDetached(["caelestia", "wallpaper", "-f", expandedPath]);
                    }
                }
            }
            timeBasedTimer.running = true;
        }
    }
    
    Component.onCompleted: {
        if (source)
            Qt.callLater(() => { one.path = source; });
        
        Qt.callLater(() => {
            try {
                debounceTimer.interval = (Config.background.transitionDuration ?? 1000) + 100;
                autoRandomTimer.interval = (Config.background.autoRandomInterval ?? 300) * 1000;
                
                const arw = Config.background.autoRandomWallpaper ?? false;
                const tbw = Config.background.timeBasedWallpaper ?? false;
                
                if (arw && !tbw) {
                    autoRandomTimer.running = true;
                }
                
                if (tbw) {
                    const scheduledWallpaper = getScheduledWallpaper();
                    if (scheduledWallpaper) {
                        let expandedPath = scheduledWallpaper;
                        if (scheduledWallpaper.startsWith("~/")) {
                            expandedPath = Quickshell.env("HOME") + scheduledWallpaper.substring(1);
                        }
                        
                        if (expandedPath !== one.path) {
                            Quickshell.execDetached(["caelestia", "wallpaper", "-f", expandedPath]);
                        }
                    }
                    
                    const now = new Date();
                    const secondsUntilNextMinute = 60 - now.getSeconds();
                    const msUntilNextMinute = secondsUntilNextMinute * 1000 - now.getMilliseconds();
                    
                    minuteAlignTimer.interval = msUntilNextMinute;
                    minuteAlignTimer.start();
                }
            } catch (e) {
                console.error("Error setting up timers:", e);
            }
        });
    }

    Loader {
        anchors.fill: parent

        active: !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Appearance.spacing.large

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.extraLarge * 5
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.extraLarge * 2
                        font.bold: true
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: selectWallText.implicitHeight + Appearance.padding.small * 2

                        radius: Appearance.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Image files")
                            filters: Images.validImageExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary

                            function onClicked(): void {
                                dialog.open();
                            }
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font.pointSize: Appearance.font.size.large
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: shaderLoader
        anchors.fill: parent
        active: true

        sourceComponent: {
            switch (root.activeTransitionType) {
            case "wipe":
                return wipeShaderComponent;
            case "disc":
                return discShaderComponent;
            case "stripes":
                return stripesShaderComponent;
            case "fade":
            default:
                return fadeShaderComponent;
            }
        }
    }

    Component {
        id: fadeShaderComponent
        ShaderEffect {
            anchors.fill: parent

            property variant source1: one
            property variant source2: two
            property real progress: root.transitionProgress
            property real fillMode: 1.0
            property vector4d fillColor: Qt.vector4d(0, 0, 0, 1)
            property real imageWidth1: source1.sourceSize.width || source1.implicitWidth
            property real imageHeight1: source1.sourceSize.height || source1.implicitHeight
            property real imageWidth2: source2.sourceSize.width || source2.implicitWidth
            property real imageHeight2: source2.sourceSize.height || source2.implicitHeight
            property real screenWidth: width
            property real screenHeight: height

            fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/wp_fade.frag.qsb")
        }
    }

    Component {
        id: wipeShaderComponent
        ShaderEffect {
            anchors.fill: parent

            property variant source1: one
            property variant source2: two
            property real progress: root.transitionProgress
            property real smoothness: 0.05
            property real direction: root.wipeDirection
            property real fillMode: 1.0
            property vector4d fillColor: Qt.vector4d(0, 0, 0, 1)
            property real imageWidth1: source1.sourceSize.width || source1.implicitWidth
            property real imageHeight1: source1.sourceSize.height || source1.implicitHeight
            property real imageWidth2: source2.sourceSize.width || source2.implicitWidth
            property real imageHeight2: source2.sourceSize.height || source2.implicitHeight
            property real screenWidth: width
            property real screenHeight: height

            fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/wp_wipe.frag.qsb")
        }
    }

    Component {
        id: discShaderComponent
        ShaderEffect {
            anchors.fill: parent

            property variant source1: one
            property variant source2: two
            property real progress: root.transitionProgress
            property real smoothness: 0.05
            property real aspectRatio: width / height
            property real centerX: root.discCenterX
            property real centerY: root.discCenterY
            property real fillMode: 1.0
            property vector4d fillColor: Qt.vector4d(0, 0, 0, 1)
            property real imageWidth1: source1.sourceSize.width || source1.implicitWidth
            property real imageHeight1: source1.sourceSize.height || source1.implicitHeight
            property real imageWidth2: source2.sourceSize.width || source2.implicitWidth
            property real imageHeight2: source2.sourceSize.height || source2.implicitHeight
            property real screenWidth: width
            property real screenHeight: height

            fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/wp_disc.frag.qsb")
        }
    }

    Component {
        id: stripesShaderComponent
        ShaderEffect {
            anchors.fill: parent

            property variant source1: one
            property variant source2: two
            property real progress: root.transitionProgress
            property real smoothness: 0.05
            property real aspectRatio: width / height
            property real stripeCount: root.stripesCount
            property real angle: root.stripesAngle
            property real fillMode: 1.0
            property vector4d fillColor: Qt.vector4d(0, 0, 0, 1)
            property real imageWidth1: source1.sourceSize.width || source1.implicitWidth
            property real imageHeight1: source1.sourceSize.height || source1.implicitHeight
            property real imageWidth2: source2.sourceSize.width || source2.implicitWidth
            property real imageHeight2: source2.sourceSize.height || source2.implicitHeight
            property real screenWidth: width
            property real screenHeight: height

            fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/assets/shaders/wp_stripes.frag.qsb")
        }
    }

    NumberAnimation {
        id: transitionAnimation
        target: root
        property: "transitionProgress"
        from: 0.0
        to: 1.0
        duration: Config.background.transitionDuration ?? 1000
        easing.type: Easing.InOutCubic
        onFinished: {
            one.path = two.path;
            Qt.callLater(() => {
                two.path = "";
            });
        }
    }

    Img {
        id: one
    }

    Img {
        id: two
    }

    component Img: CachingImage {
        id: img

        anchors.fill: parent
        visible: false
        smooth: true
        cache: false
        asynchronous: true
    }
}
