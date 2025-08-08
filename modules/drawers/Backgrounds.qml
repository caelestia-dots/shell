import qs.services
import qs.config
import qs.modules.osd as Osd
import qs.modules.notifications as Notifications
import qs.modules.session as Session
import qs.modules.launcher as Launcher
import qs.modules.dashboard as Dashboard
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities as Utilities
import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property Panels panels
    required property Item bar

    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.leftMargin: bar.implicitWidth
    preferredRendererType: Shape.CurveRenderer

    Osd.Background {
        wrapper: root.panels.osd

        startX: root.width - root.panels.session.width
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Notifications.Background {
        wrapper: root.panels.notifications

        startX: root.width
        startY: 0
    }

    Session.Background {
        wrapper: root.panels.session

        startX: root.width
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Launcher.Background {
        wrapper: root.panels.launcher

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: root.height
    }

    Dashboard.Background {
        wrapper: root.panels.dashboard

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: 0
    }

    BarPopouts.Background {
        wrapper: root.panels.popouts
        invertBottomRounding: wrapper.y + wrapper.height + 1 >= root.height

        startX: wrapper.x
        startY: wrapper.y - rounding * sideRounding
    }

    Utilities.Background {
        wrapper: root.panels.utilities

        startX: root.width
        startY: root.height
    }
}
