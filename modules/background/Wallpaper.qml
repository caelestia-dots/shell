pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.components.filedialog
import qs.services
import qs.config
import qs.utils
import QtQuick

Item {
    id: root

    // Current wallpaper path (managed by Caelestia)
    property string source: Wallpapers.current

    // Expose the currently visible image item (for visualiser/shaders)
    readonly property Item current: activeSlot?.activeChild

    // Track which slot is currently active
    property Item activeSlot: one

    anchors.fill: parent

    // When the source changes, update the "other" slot to enable a crossfade.
    onSourceChanged: {
        if (!source) {
            activeSlot = null;
        } else {
            // Update the inactive slot
            const nextSlot = (activeSlot === one) ? two : one;
            nextSlot.loadAndBecomeActive(source);
        }
    }

    // Empty-state UI (unchanged)
    Loader {
        anchors.fill: parent
        active: !root.source
        asynchronous: true

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
                            function onClicked(): void { dialog.open(); }
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

    // Two slots that we crossfade between
    Img { id: one }
    Img { id: two }

    // ----------------------------------------------------------------------
    // Img: persistent dual-renderer (static + gif), no Loader, no reparenting
    // ----------------------------------------------------------------------
    component Img: Item {
        id: img
        anchors.fill: parent

        // Path we want this slot to display
        property string path: ""

        // Determine renderer
        readonly property bool isGif: path && path.toLowerCase().endsWith(".gif")

        // The child that is currently visible (either staticImg or gifImg)
        readonly property Item activeChild: isGif ? gifImg : staticImg

        // Load new wallpaper and become active when ready
        function loadAndBecomeActive(newPath: string): void {
            path = newPath;
            
            if (isGif) {
                staticImg.visible = false;
                staticImg.path = "";
                
                gifImg.source = newPath;
                gifImg.visible = true;
            } else {
                gifImg.visible = false;
                gifImg.playing = false;
                gifImg.source = "";
                
                staticImg.path = newPath;
                staticImg.visible = true;
            }
            
            // Check if already ready (sync/cached load)
            checkAndActivate();
        }

        // Check if ready and activate this slot
        function checkAndActivate(): void {
            if (activeChild.status !== Image.Ready) return;
            
            // Start GIF playback
            if (isGif) {
                gifImg.currentFrame = 0;
                gifImg.playing = true;
            }
            
            // Make this slot active
            root.activeSlot = img;
        }

        // Crossfade/scale state lives on the slot wrapper
        opacity: 0
        scale: Wallpapers.showPreview ? 1 : 0.8

        // --- Static renderer (persistent) ---
        CachingImage {
            id: staticImg
            anchors.fill: parent
            visible: false

            onStatusChanged: {
                if (status === Image.Ready && visible) {
                    img.checkAndActivate();
                }
            }
        }

        // --- GIF renderer (persistent AnimatedImage) ---
        AnimatedImage {
            id: gifImg
            anchors.fill: parent
            visible: false
            cache: false
            asynchronous: false
            playing: false
            fillMode: Image.PreserveAspectCrop

            onStatusChanged: {
                if (status === Image.Ready && visible) {
                    img.checkAndActivate();
                }
            }

            onVisibleChanged: {
                if (!visible) playing = false;
            }
        }

        // Animate *this slot* (not the child), to avoid touching decoder items
        states: State {
            name: "visible"
            when: root.activeSlot === img
            PropertyChanges { target: img; opacity: 1; scale: 1 }
        }

        transitions: [
            Transition {
                to: "visible"
                ParallelAnimation {
                    NumberAnimation {
                        target: img
                        property: "opacity"
                        duration: Appearance.anim.durations.large
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                    NumberAnimation {
                        target: img
                        property: "scale"
                        duration: Appearance.anim.durations.large
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            },
            Transition {
                from: "visible"; to: ""
                ParallelAnimation {
                    NumberAnimation {
                        target: img
                        property: "opacity"
                        duration: Appearance.anim.durations.large
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                    NumberAnimation {
                        target: img
                        property: "scale"
                        duration: Appearance.anim.durations.large
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }
        ]

        // Initialize once at creation
        Component.onCompleted: {
            if (root.source && root.activeSlot === img) {
                loadAndBecomeActive(root.source);
            }
        }
    }
}