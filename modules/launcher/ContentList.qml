pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils

Item {
    id: root

    required property var content
    required property DrawerVisibilities visibilities
    required property var panels
    required property real maxHeight
    required property StyledTextField search
    required property int padding
    required property int rounding

    readonly property string activeViewId: {
        const text = search.text;
        const prefix = Config.launcher.actionPrefix;
        if (text.startsWith(`${prefix}wallpaper `))
            return "wallpapers";
        if (text.startsWith(`${prefix}clipboard `))
            return "clipboard";
        if (text.startsWith(`${prefix}emoji `))
            return "emoji";
        return "apps";
    }

    readonly property bool showWallpapers: activeViewId === "wallpapers"
    readonly property bool showClipboard: activeViewId === "clipboard"
    readonly property bool showEmoji: activeViewId === "emoji"

    property string _renderedViewId: "apps"
    property bool _heightFrozen: false
    property real _frozenHeight: 0

    readonly property var _viewLoaders: ({
            "apps": appList,
            "wallpapers": wallpaperList,
            "clipboard": clipboardList,
            "emoji": emojiList
        })

    readonly property var currentList: _viewLoaders[_renderedViewId]?.item ?? null

    readonly property var _emptyData: ({
            "apps": {
                icon: "manage_search",
                title: qsTr("No results"),
                subtitle: qsTr("Try searching for something else")
            },
            "wallpapers": {
                icon: "wallpaper_slideshow",
                title: qsTr("No wallpapers found"),
                subtitle: Wallpapers.list.length === 0 ? qsTr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : qsTr("Try searching for something else")
            },
            "clipboard": {
                icon: "content_paste",
                title: qsTr("No clipboard history"),
                subtitle: qsTr("Copy something to populate clipboard history")
            },
            "emoji": {
                icon: "sentiment_satisfied",
                title: qsTr("No emojis found"),
                subtitle: qsTr("Try searching for an emoji")
            }
        })

    readonly property real _viewHeight: {
        const loader = _viewLoaders[_renderedViewId];
        if (!loader || !loader.item)
            return empty.implicitHeight;
        const h = loader.item.implicitHeight;
        return h > 0 ? h : empty.implicitHeight;
    }

    readonly property real _viewWidth: {
        if (_renderedViewId === "wallpapers") {
            const loader = _viewLoaders["wallpapers"];
            return Math.max(Config.launcher.sizes.itemWidth * 1.2, loader?.implicitWidth ?? 0);
        }
        return Config.launcher.sizes.itemWidth;
    }

    clip: true
    implicitWidth: _viewWidth
    implicitHeight: _heightFrozen ? _frozenHeight : (_renderedViewId === "wallpapers" ? Config.launcher.sizes.wallpaperHeight : Math.min(maxHeight, _viewHeight))

    onActiveViewIdChanged: {
        if (activeViewId === _renderedViewId)
            return;

        const loader = _viewLoaders[activeViewId];
        if (loader && !loader.active)
            loader.active = true;

        if (content.skipTransitions || !visibilities.launcher) {
            if (viewTransition.running)
                viewTransition.stop();
            _renderedViewId = activeViewId;
            return;
        }

        _frozenHeight = implicitHeight;
        _heightFrozen = true;

        if (viewTransition.running)
            viewTransition.stop();
        viewTransition.start();
    }

    SequentialAnimation {
        id: viewTransition

        Anim {
            target: root
            property: "opacity"
            from: 1
            to: 0
            duration: Appearance.anim.durations.small
        }

        ScriptAction {
            script: {
                root._renderedViewId = root.activeViewId;
                root._heightFrozen = false;
            }
        }

        Anim {
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: Appearance.anim.durations.small
        }
    }

    Loader {
        id: appList

        active: true
        visible: root._renderedViewId === "apps"

        anchors.fill: parent

        sourceComponent: AppList {
            search: root.search
            visibilities: root.visibilities
        }
    }

    Loader {
        id: wallpaperList

        asynchronous: true
        active: false
        visible: root._renderedViewId === "wallpapers"

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: WallpaperList {
            search: root.search
            visibilities: root.visibilities
            panels: root.panels
            content: root.content
        }
    }

    Loader {
        id: clipboardList

        active: false
        visible: root._renderedViewId === "clipboard"

        anchors.fill: parent

        sourceComponent: ClipboardList {
            search: root.search
            visibilities: root.visibilities
        }
    }

    Loader {
        id: emojiList

        active: false
        visible: root._renderedViewId === "emoji"

        anchors.fill: parent

        sourceComponent: EmojiList {
            search: root.search
            visibilities: root.visibilities
        }
    }

    Row {
        id: empty

        readonly property var emptyInfo: root._emptyData[root._renderedViewId] ?? root._emptyData["apps"]

        visible: root._renderedViewId === root.activeViewId && root._renderedViewId !== "clipboard"
        opacity: (root.currentList?.count === 0 && !viewTransition.running) ? 1 : 0
        scale: (root.currentList?.count === 0 && !viewTransition.running) ? 1 : 0.5

        spacing: Appearance.spacing.normal
        padding: Appearance.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: empty.emptyInfo.icon
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: empty.emptyInfo.title
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: empty.emptyInfo.subtitle
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
            }
        }

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitWidth {
        enabled: root.visibilities.launcher

        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    Behavior on implicitHeight {
        enabled: root.visibilities.launcher && !root.content.skipTransitions

        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }
}
