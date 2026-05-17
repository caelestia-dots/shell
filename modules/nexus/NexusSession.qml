pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.nexus

QtObject {
    id: root

    required property var nexusRoot

    property string activeCategory: "appearance"
    property bool sidebarCollapsed: true
    property string expandedCategory: ""
    property string flyoutCategory: ""
    property string searchQuery: ""
    property string forcedTab: ""
    property string activeConfig: "global"
    property bool searchPopoutOpen: false
    property bool configPopoutOpen: false

    readonly property var activeCategoryConfig: NexusRegistry.getById(activeCategory)
    property string _savedExpandedCategory: ""

    function setCategory(id) {
        activeCategory = id;
        forcedTab = "";
    }

    function setSearchNavigate(category, tab) {
        activeCategory = category;
        forcedTab = tab;
        searchQuery = "";
    }

    function consumeForcedTab() {
        const tab = forcedTab;
        forcedTab = "";
        return tab;
    }

    function toggleSidebar() {
        if (!sidebarCollapsed) {
            _savedExpandedCategory = expandedCategory;
            expandedCategory = "";
            sidebarCollapsed = true;
        } else {
            sidebarCollapsed = false;
            flyoutCategory = "";
            searchPopoutOpen = false;
            configPopoutOpen = false;
            expandedCategory = _savedExpandedCategory;
        }
    }
}
