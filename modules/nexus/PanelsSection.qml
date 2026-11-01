pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages
import qs.modules.nexus.pages.apps
import qs.modules.nexus.pages.audio
import qs.modules.nexus.pages.bluetooth
import qs.modules.nexus.pages.network
import qs.modules.nexus.pages.panels
import qs.modules.nexus.pages.services
import qs.modules.nexus.pages.wallandstyle
import qs.modules.nexus.pages.panels.taskbar

// Shell
// Panels
StackPage {
    Component {
        PanelsPage {}
    }
    Component {
        DashboardPanel {}
    }
    Component {
        TaskbarPanel {}
    }
    Component {
        LauncherPanel {}
    }
    Component {
        SidebarPanel {}
    }
    Component {
        UtilitiesPanel {}
    }

    // Taskbar component sub-pages
    Component {
        BarWorkspaces {}
    }
    Component {
        BarActiveWindow {}
    }
    Component {
        BarTray {}
    }
    Component {
        BarStatusIcons {}
    }
    Component {
        BarClock {}
    }
}
