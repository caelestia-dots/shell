pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.modules.nexus.components.common

ColumnLayout {
    id: root

    required property string titleText
    required property string profileKey
    required property var cfg

    Layout.fillWidth: true
    spacing: Tokens.spacing.normal

    StyledText {
        text: root.titleText
        font.pointSize: Tokens.font.size.normal
        font.weight: Font.Medium
    }

    RefreshRateSelector {
        Layout.fillWidth: true
        opacity: root.enabled ? 1 : 0.4
        value: root.cfg?.setRefreshRate ?? ""
        showRestore: true
        showUnchanged: false
        onRateChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm.profileBehaviors)
                pm.profileBehaviors = {};
            if (!pm.profileBehaviors[root.profileKey])
                pm.profileBehaviors[root.profileKey] = {};
            pm.profileBehaviors[root.profileKey].setRefreshRate = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }

    TriStateRow {
        opacity: root.enabled ? 1 : 0.4
        label: qsTr("Animations")
        value: root.cfg?.disableAnimations ?? ""
        onTriStateValueChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm.profileBehaviors)
                pm.profileBehaviors = {};
            if (!pm.profileBehaviors[root.profileKey])
                pm.profileBehaviors[root.profileKey] = {};
            pm.profileBehaviors[root.profileKey].disableAnimations = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }

    TriStateRow {
        opacity: root.enabled ? 1 : 0.4
        label: qsTr("Blur")
        value: root.cfg?.disableBlur ?? ""
        onTriStateValueChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm.profileBehaviors)
                pm.profileBehaviors = {};
            if (!pm.profileBehaviors[root.profileKey])
                pm.profileBehaviors[root.profileKey] = {};
            pm.profileBehaviors[root.profileKey].disableBlur = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }

    TriStateRow {
        opacity: root.enabled ? 1 : 0.4
        label: qsTr("Rounding")
        value: root.cfg?.disableRounding ?? ""
        onTriStateValueChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm.profileBehaviors)
                pm.profileBehaviors = {};
            if (!pm.profileBehaviors[root.profileKey])
                pm.profileBehaviors[root.profileKey] = {};
            pm.profileBehaviors[root.profileKey].disableRounding = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }

    TriStateRow {
        opacity: root.enabled ? 1 : 0.4
        label: qsTr("Shadows")
        value: root.cfg?.disableShadows ?? ""
        onTriStateValueChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm.profileBehaviors)
                pm.profileBehaviors = {};
            if (!pm.profileBehaviors[root.profileKey])
                pm.profileBehaviors[root.profileKey] = {};
            pm.profileBehaviors[root.profileKey].disableShadows = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }
}
