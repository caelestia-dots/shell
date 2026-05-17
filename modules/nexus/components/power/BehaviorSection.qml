pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.components.common

ColumnLayout {
    id: root

    required property string titleText
    required property string section
    required property var cfg
    property bool showEvaluateThresholds: false

    Layout.fillWidth: true
    spacing: Tokens.spacing.normal

    StyledText {
        text: root.titleText
        font.pointSize: Tokens.font.size.normal
        font.weight: Font.Medium
    }

    PowerProfileSelector {
        Layout.fillWidth: true
        opacity: root.enabled ? 1 : 0.4
        value: root.cfg?.setPowerProfile ?? ""
        showRestore: true
        showUnchanged: true
        onProfileChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm[root.section])
                pm[root.section] = {};
            pm[root.section].setPowerProfile = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }

    RefreshRateSelector {
        Layout.fillWidth: true
        opacity: root.enabled ? 1 : 0.4
        value: root.cfg?.setRefreshRate ?? ""
        showRestore: true
        showUnchanged: true
        onRateChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm[root.section])
                pm[root.section] = {};
            pm[root.section].setRefreshRate = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }

    TriStateRow {
        opacity: root.enabled ? 1 : 0.4
        label: qsTr("Animations")
        value: root.cfg?.disableAnimations ?? ""
        onTriStateValueChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm[root.section])
                pm[root.section] = {};
            pm[root.section].disableAnimations = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }

    TriStateRow {
        opacity: root.enabled ? 1 : 0.4
        label: qsTr("Blur")
        value: root.cfg?.disableBlur ?? ""
        onTriStateValueChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm[root.section])
                pm[root.section] = {};
            pm[root.section].disableBlur = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }

    TriStateRow {
        opacity: root.enabled ? 1 : 0.4
        label: qsTr("Rounding")
        value: root.cfg?.disableRounding ?? ""
        onTriStateValueChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm[root.section])
                pm[root.section] = {};
            pm[root.section].disableRounding = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }

    TriStateRow {
        opacity: root.enabled ? 1 : 0.4
        label: qsTr("Shadows")
        value: root.cfg?.disableShadows ?? ""
        onTriStateValueChanged: v => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm[root.section])
                pm[root.section] = {};
            pm[root.section].disableShadows = v;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }

    SwitchRow {
        visible: root.showEvaluateThresholds
        opacity: root.enabled ? 1 : 0.4
        label: qsTr("Evaluate battery thresholds")
        checked: root.cfg?.evaluateThresholds ?? true
        onToggled: c => {
            const pm = JSON.parse(JSON.stringify(GlobalConfig.general.battery.powerManagement || {}));
            if (!pm[root.section])
                pm[root.section] = {};
            pm[root.section].evaluateThresholds = c;
            GlobalConfig.general.battery.powerManagement = pm;
        }
    }
}
