'use strict';
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {ngettext} from 'resource:///org/gnome/shell/extensions/extension.js';

import {EnhancedDeviceSupportManager} from './enhancedDeviceSupportManager.js';
import {WidgetManagerBluez} from './widgetManagerBluez.js';
import {WidgetManagerEnhanced} from './widgetManagerEnhanced.js';
import {PanelButtonSingleDevice} from './panelButtonSingleDevice.js';
import {PanelButtonMultiDevice} from './panelButtonMultiDevice.js';
import {UpowerClient} from './upower/upowerDevice.js';
import {supportedIcons} from './widgets/iconGroups.js';
import {
    isDarkMode, adjustColorLuminanceToRgba, getAccentColor, hexToColor
} from './widgets/colorHelpers.js';

const QuickSettingsMenu = Main.panel.statusArea.quickSettings;

export const BluetoothBatteryMeter = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_BluetoothToggle',
}, class BluetoothBatteryMeter extends GObject.Object {
    _init(settings, extensionPath, extuuid) {
        super._init();
        this.settings = settings;
        this.extPath = extensionPath;
        this._extuuid = extuuid;

        this._idleTimerId = GLib.idle_add(GLib.PRIORITY_LOW, () => {
            if (!Main.panel.statusArea.quickSettings._bluetooth &&
                Main.panel.statusArea.quickSettings._bluetooth.quickSettingsItems[0]
                    ._box.get_first_child().get_stage())
                return GLib.SOURCE_CONTINUE;

            this._bluetoothToggle = Main.panel.statusArea.quickSettings
                ._bluetooth.quickSettingsItems[0];
            this._startBluetoothToggle();
            this._idleTimerId = null;
            return GLib.SOURCE_REMOVE;
        });
    }

    _startBluetoothToggle() {
        this._syncRunning = false;
        this._syncPending = false;
        this._deviceItems = new Map();
        this.deviceList = new Map();
        this.connectedColor = '#8fbbf0';
        this._indicatorBox = null;
        this._pullDevicesFromGsetting();
        this.gIcon = iconName => Gio.icon_new_for_string(
            `${this.extPath}/icons/hicolor/scalable/actions/${iconName}`);
        this.modifyQuickSettings = this.settings.get_boolean('modify-quick-settings');
        this.usePopupInQuickSettings = this.settings.get_boolean('popup-in-quick-settings');
        this.showBatteryPercentage = this.settings.get_boolean('enable-battery-level-text');
        this.showBatteryIcon = this.settings.get_boolean('enable-battery-level-icon');
        this.swapIconText = this.settings.get_boolean('swap-icon-text');
        this._sortDevicesByHistory = this.settings.get_boolean('sort-devices-by-history');
        this._hideBluetoothIndicator = this.settings.get_int('hide-bluetooth-indicator');
        this._indicatorType = this.settings.get_int('indicator-type');
        this._panelSingleIndicator = this.settings.get_boolean('panel-button-single-indicator');
        this._enableMultimodeIndicator = this.settings.get_boolean('enable-multi-indicator-mode');
        this._enableHoverMode = this.settings.get_boolean('enable-on-hover-mode');

        this.widgetInfo = {
            extPath: this.extPath,
            isUnlockSession: Main.sessionMode.currentMode === 'unlock-dialog',
            disableLevelInIcon: this.settings.get_boolean('disable-level-in-icon'),
            indicatorWithText: this.settings.get_boolean('enable-battery-indicator-text'),
            levelIndicatorType: this.settings.get_int('level-indicator-type'),
            levelBarPosition: this.settings.get_int('level-bar-position'),
            levelIndicatorColor: this.settings.get_int('level-indicator-color'),
            levelIndicatorCustomColors: this.settings.get_strv('level-indicator-custom-colors'),
            circleWidgetColor: this.settings.get_int('circle-widget-color'),
            circleWidgetCustomColors: this.settings.get_strv('circle-widget-custom-colors'),
            accentColor: hexToColor('#3584e4'),
        };

        this.airpodsEnabled = this.settings.get_boolean('enable-airpods-device');
        this.sonyEnabled = this.settings.get_boolean('enable-sony-device');
        this.galaxyBudsEnabled = this.settings.get_boolean('enable-galaxy-buds-device');
        this.nothingBudsEnabled = this.settings.get_boolean('enable-nothing-buds-device');
        this.googleBudsEnabled = this.settings.get_boolean('enable-google-buds-device');
        this.boseBudsEnabled = this.settings.get_boolean('enable-bose-buds-device');
        this.redmiBudsEnabled = this.settings.get_boolean('enable-redmi-buds-device');
        this.senhBudsEnabled = this.settings.get_boolean('enable-senh-buds-device');
        this.gfpsEnabled = this.settings.get_boolean('enable-gfps-device');
        this.gattBasEnabled = this.settings.get_boolean('enable-gattbas-device');

        this._updateColors();

        this._originalSync = this._bluetoothToggle._sync;
        this._bluetoothToggle._sync = () => {};
        this._bluetoothToggle._sync = () => {
            this.sync();
        };
        this._originalRemoveDevice = this._bluetoothToggle._removeDevice;
        this._bluetoothToggle._removeDevice = path => {
            this._removeDevice(path);
        };
        this._originalOnActiveChanged = this._bluetoothToggle._onActiveChanged;
        this._bluetoothToggle._onActiveChanged = () => {
            this._onActiveChanged();
        };
        this._originalReorderDeviceItems = this._bluetoothToggle._reorderDeviceItems;
        this._bluetoothToggle._reorderDeviceItems = () => {
            this._reorderDeviceItems();
        };

        this._originalBluetoothIndicatorSync = QuickSettingsMenu._bluetooth._sync;
        QuickSettingsMenu._bluetooth._sync = () => {};

        this._bluetoothToggle._deviceItems.forEach(item => {
            item.destroy();
        });
        this._bluetoothToggle._deviceItems.clear();

        this._themeContext = St.ThemeContext.get_for_stage(global.stage);
        this._themeContext.connectObject('changed', () => {
            this._updateColors();
            this._onActiveChanged();
        }, this);

        this.settings.connectObject(
            'changed::modify-quick-settings', () => {
                this.modifyQuickSettings =
                    this.settings.get_boolean('modify-quick-settings');
                this._onActiveChanged();
            },
            'changed::popup-in-quick-settings', () => {
                this.usePopupInQuickSettings =
                    this.settings.get_boolean('popup-in-quick-settings');
                this._onActiveChanged();
            },
            'changed::enable-battery-level-text', () => {
                this.showBatteryPercentage =
                    this.settings.get_boolean('enable-battery-level-text');
                this._onActiveChanged();
            },
            'changed::enable-battery-level-icon', () => {
                this.showBatteryIcon = this.settings.get_boolean('enable-battery-level-icon');
                this._onActiveChanged();
            },
            'changed::swap-icon-text', () => {
                this.swapIconText = this.settings.get_boolean('swap-icon-text');
                this._onActiveChanged();
            },
            'changed::sort-devices-by-history', () => {
                this._sortDevicesByHistory = this.settings.get_boolean('sort-devices-by-history');
                this._onActiveChanged();
            },
            'changed::hide-bluetooth-indicator', () => {
                this._hideBluetoothIndicator = this.settings.get_int('hide-bluetooth-indicator');
                this._onActiveChanged();
            },
            'changed::indicator-type', () => {
                this._indicatorType = this.settings.get_int('indicator-type');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::panel-button-single-indicator', () => {
                this._panelSingleIndicator =
                    this.settings.get_boolean('panel-button-single-indicator');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::enable-multi-indicator-mode', () => {
                this._enableMultimodeIndicator =
                    this.settings.get_boolean('enable-multi-indicator-mode');
                this._onActiveChanged();
            },
            'changed::enable-on-hover-mode', () => {
                this._enableHoverMode = this.settings.get_boolean('enable-on-hover-mode');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::enable-tooltip', () => {
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::disable-level-in-icon', () => {
                this.widgetInfo.disableLevelInIcon =
                    this.settings.get_boolean('disable-level-in-icon');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::enable-battery-indicator-text', () => {
                this.widgetInfo.indicatorWithText =
                    this.settings.get_boolean('enable-battery-indicator-text');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::level-indicator-type', () => {
                this.widgetInfo.levelIndicatorType =
                    this.settings.get_int('level-indicator-type');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::level-bar-position', () => {
                this.widgetInfo.levelBarPosition =
                    this.settings.get_int('level-bar-position');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::level-indicator-color', () => {
                this.widgetInfo.levelIndicatorColor =
                    this.settings.get_int('level-indicator-color');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::level-indicator-custom-colors', () => {
                this.widgetInfo.levelIndicatorCustomColors =
                    this.settings.get_strv('level-indicator-custom-colors');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::circle-widget-color', () => {
                this.widgetInfo.circleWidgetColor = this.settings.get_int('circle-widget-color');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::circle-widget-custom-colors', () => {
                this.widgetInfo.circleWidgetCustomColors =
                    this.settings.get_strv('circle-widget-custom-colors');
                this._onActiveChanged();
                this._reloadUpowerIndicator();
            },
            'changed::enable-upower-level-icon', () => {
                this._upowerEnabled = this.settings.get_boolean('enable-upower-level-icon');
                this._reloadUpowerIndicator();
            },
            'changed::enable-airpods-device', () => {
                this.airpodsEnabled = this.settings.get_boolean('enable-airpods-device');
                this._setEnhancedDeviceMode();
                this._onActiveChanged();
            },
            'changed::enable-sony-device', () => {
                this.sonyEnabled = this.settings.get_boolean('enable-sony-device');
                this._setEnhancedDeviceMode();
                this._onActiveChanged();
            },
            'changed::enable-galaxy-buds-device', () => {
                this.galaxyBudsEnabled = this.settings.get_boolean('enable-galaxy-buds-device');
                this._setEnhancedDeviceMode();
                this._onActiveChanged();
            },
            'changed::enable-nothing-buds-device', () => {
                this.nothingBudsEnabled = this.settings.get_boolean('enable-nothing-buds-device');
                this._setEnhancedDeviceMode();
                this._onActiveChanged();
            },
            'changed::enable-google-buds-device', () => {
                this.googleBudsEnabled = this.settings.get_boolean('enable-google-buds-device');
                this._setEnhancedDeviceMode();
                this._onActiveChanged();
            },
            'changed::enable-bose-buds-device', () => {
                this.boseBudsEnabled = this.settings.get_boolean('enable-bose-buds-device');
                this._setEnhancedDeviceMode();
                this._onActiveChanged();
            },
            'changed::enable-redmi-buds-device', () => {
                this.redmiBudsEnabled = this.settings.get_boolean('enable-redmi-buds-device');
                this._setEnhancedDeviceMode();
                this._onActiveChanged();
            },
            'changed::enable-senh-buds-device', () => {
                this.senhBudsEnabled = this.settings.get_boolean('enable-senh-buds-device');
                this._setEnhancedDeviceMode();
                this._onActiveChanged();
            },

            'changed::enable-gfps-device', () => {
                this.gfpsEnabled = this.settings.get_boolean('enable-gfps-device');
                this._setEnhancedDeviceMode();
                this._onActiveChanged();
            },
            'changed::enable-gattbas-device', () => {
                this.gattBasEnabled = this.settings.get_boolean('enable-gattbas-device');
                this._setEnhancedDeviceMode();
                this._onActiveChanged();
            },
            this
        );
        this._setEnhancedDeviceMode();
        this._connectSettingsSignal(true);
        this._onActiveChanged();

        Main.sessionMode.connectObject(
            'updated', session => {
                this.widgetInfo.isUnlockSession = session.currentMode === 'unlock-dialog';
                this._onActiveChanged();
            },
            this
        );

        this._upowerEnabled = this.settings.get_boolean('enable-upower-level-icon');
        this._reloadUpowerIndicator();

        this.sync();
    }

    _reloadUpowerIndicator() {
        if (this._upowerEnabled) {
            this._upowerClient?.destroy();
            this._upowerClient = new UpowerClient(this);
        } else {
            this._upowerClient?.destroy();
            this._upowerClient = null;
        }
    }

    _connectSettingsSignal(connect) {
        if (connect) {
            this._settingSignalId = this.settings.connect('changed::device-list', () => {
                this._pullDevicesFromGsetting();
                this.sync();
            });
        } else if (this._settingSignalId) {
            this.settings.disconnect(this._settingSignalId);
            this._settingSignalId = null;
        }
    }

    _reorderDeviceItems() {
        const devices = this._sortDevicesByHistory ? this._getRecencySortedDevices()
            : this._bluetoothToggle._getSortedDevices();
        for (const [i, dev] of devices.entries()) {
            const item = this._deviceItems.get(dev.get_object_path());
            if (!item)
                continue;

            this._bluetoothToggle._deviceSection.moveMenuItem(item.popupMenuItem, i);
        }
    }

    _removeDevice(path) {
        if (this.deviceList.has(path)) {
            const props = this.deviceList.get(path);
            props.paired = false;
            this.deviceList.set(path, props);
            this.pushDevicesToGsetting();
        }
        this._deviceItems.get(path)?.destroy();
        this._deviceItems.delete(path);
        this._updateDeviceVisibility();
    }

    _updateDeviceVisibility() {
        this._bluetoothToggle._deviceSection.actor.visible =
            [...this._deviceItems.values()].some(item => item.popupMenuItem.visible);
    }

    _onActiveChanged() {
        this._bluetoothToggle._updatePlaceholder();
        this._deviceItems.forEach(item => item.destroy());
        this._deviceItems.clear();
        this._updateIndicatorSettings();
        this.sync();
        // Rebuild UPower indicators in case the indicator box was just torn down.
        this._reloadUpowerIndicator();
    }

    _getRecencySortedDevices() {
        const devices = this._bluetoothToggle._getSortedDevices();
        const connectedDevices = [];
        const disconnectedDevices = [];

        devices.forEach(device => {
            const path = device.get_object_path();
            const props = this.deviceList.get(path);
            if (device.connected) {
                connectedDevices.push({
                    device,
                    time: props?.connectedTime || 0,
                });
            } else {
                disconnectedDevices.push({
                    device,
                    time: props?.disconnectedTime || 0,
                });
            }
        });
        connectedDevices.sort((a, b) => b.time - a.time);
        disconnectedDevices.sort((a, b) => b.time - a.time);
        return [...connectedDevices.map(item => item.device),
            ...disconnectedDevices.map(item => item.device)];
    }

    _pullDevicesFromGsetting() {
        this.deviceList.clear();
        const deviceList = this.settings.get_strv('device-list');
        if (deviceList.length !== 0) {
            for (const jsonString of deviceList) {
                const item = JSON.parse(jsonString);
                const path = item.path;
                const props = {
                    'icon': item['icon'],
                    'alias': item['alias'],
                    'paired': item['paired'],
                    'batteryReported': item['battery-reported'],
                    'qsLevelEnabled': item['qs-level'],
                    'indicatorMode': item['indicator-mode'],
                    'isEnhancedDevice': item['enhanced-device'],
                    'connectedTime': item['connected-time'] || 0,
                    'disconnectedTime': item['disconnected-time'] || 0,
                };
                this.deviceList.set(path, props);
            }
        }
    }

    pushDevicesToGsetting() {
        const deviceList = [];
        for (const [path, props] of this.deviceList) {
            const item = {
                path,
                'icon': props.icon,
                'alias': props.alias,
                'paired': props.paired,
                'battery-reported': props.batteryReported,
                'qs-level': props.qsLevelEnabled,
                'indicator-mode': props.indicatorMode,
                'enhanced-device': props.isEnhancedDevice,
                'connected-time': props.connectedTime,
                'disconnected-time': props.disconnectedTime,
            };
            deviceList.push(JSON.stringify(item));
        }
        this._connectSettingsSignal(false);
        this.settings.set_strv('device-list', deviceList);
        this._connectSettingsSignal(true);
        this.sync();
    }

    _addNewDeviceToList(device, reported, type) {
        const battReported = reported || type;
        const currentTime = GLib.DateTime.new_now_utc().to_unix();
        const path = device.get_object_path();
        const props = {
            icon: device.icon,
            alias: device.alias,
            paired: device.paired,
            batteryReported: battReported,
            qsLevelEnabled: battReported,
            indicatorMode: battReported ? 2 : 0,
            isEnhancedDevice: type,
            connectedTime: currentTime,
            disconnectedTime: currentTime,
        };
        this.deviceList.set(path, props);
        this.delayedUpdateDeviceGsettings();
    }

    delayedUpdateDeviceGsettings() {
        if (this._delayedTimerId)
            GLib.source_remove(this._delayedTimerId);
        this._delayedTimerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
            this.pushDevicesToGsetting();
            this._delayedTimerId = null;
            return GLib.SOURCE_REMOVE;
        });
    }

    sync() {
        if (this._syncRunning) {
            this._syncPending = true;
            return;
        }

        this._syncRunning = true;

        do {
            this._syncPending = false;
            this._sync();
        } while (this._syncPending);

        this._syncRunning = false;
    }

    _sync() {
        const devices = this._sortDevicesByHistory ? this._getRecencySortedDevices()
            : this._bluetoothToggle._getSortedDevices();

        for (const dev of devices) {
            const path = dev.get_object_path();
            if (this._deviceItems.has(path)) {
                const deviceWidgetManager = this._deviceItems.get(path);
                if (this.enhancedDeviceManager) {
                    const enhancedProps = this.enhancedDeviceManager?.onDeviceSync(path,
                        dev.connected, dev.icon, dev.alias);

                    if (deviceWidgetManager.type && enhancedProps?.dataHandler)
                        deviceWidgetManager.setDataHandler(enhancedProps.dataHandler);
                }
                deviceWidgetManager.update();
                continue;
            }

            const enhancedDeviceProps = this.enhancedDeviceManager?.onDeviceSync(
                path, dev.connected, dev.icon, dev.alias);

            if (this.enhancedDeviceManager && enhancedDeviceProps &&
                    enhancedDeviceProps.pendingDetection)
                continue;

            const enhanceDeviceType = enhancedDeviceProps ? enhancedDeviceProps.type : null;

            let props = {};
            let deviceIcon;
            if (this.deviceList.has(path)) {
                let updateGsettingPairedList = false;
                props = this.deviceList.get(path);
                if (props.alias !== dev.alias) {
                    props.alias = dev.alias;
                    updateGsettingPairedList = true;
                }
                if (props.paired !== dev.paired) {
                    props.paired = dev.paired;
                    updateGsettingPairedList = true;
                }
                if (!props.batteryReported && dev.battery_percentage > 0) {
                    props.batteryReported = true;
                    props.qsLevelEnabled = true;
                    props.indicatorMode = 2;
                    updateGsettingPairedList = true;
                }
                if (!props.isEnhancedDevice && enhanceDeviceType) {
                    props.isEnhancedDevice = enhanceDeviceType;
                    props.qsLevelEnabled = true;
                    props.indicatorMode = 2;
                    updateGsettingPairedList = true;
                }
                if (updateGsettingPairedList) {
                    this.deviceList.set(path, props);
                    this.delayedUpdateDeviceGsettings();
                }
                deviceIcon = props.icon;
            } else {
                deviceIcon = supportedIcons.includes(dev.icon) ? dev.icon : 'bluetooth';
                this._addNewDeviceToList(dev, dev.battery_percentage > 0, enhanceDeviceType);
            }

            const qsLevelEnabled = props.batteryReported || props.isEnhancedDevice
                ? this.deviceList.get(path).qsLevelEnabled : false;

            let item;
            if (this.enhancedDeviceManager && enhanceDeviceType) {
                item = new WidgetManagerEnhanced(this, dev, qsLevelEnabled, props.indicatorMode,
                    deviceIcon, enhancedDeviceProps);
            } else {
                item = new WidgetManagerBluez(this, dev, props.batteryReported, qsLevelEnabled,
                    props.indicatorMode, deviceIcon);
            }

            item.popupMenuItem.connect('notify::visible', () => this._updateDeviceVisibility());
            this._bluetoothToggle._deviceSection.addMenuItem(item.popupMenuItem);
            this._deviceItems.set(path, item);
        }

        const connectedDevices = devices.filter(dev => dev.connected);
        const nConnected = connectedDevices.length;

        if (nConnected > 1) {
            this._bluetoothToggle.subtitle =
                ngettext('%d Connected', '%d Connected', nConnected).format(nConnected);
        } else if (nConnected === 1) {
            this._bluetoothToggle.subtitle = connectedDevices[0].alias;
        } else {
            this._bluetoothToggle.subtitle = null;
        }

        this._updateDeviceVisibility();

        if (this._hideBluetoothIndicator === 2) {
            let indicatorCount = 0;

            this._deviceItems.forEach(item => {
                if (item.indicator !== null && item.indicator !== undefined)
                    indicatorCount++;
            });

            QuickSettingsMenu._bluetooth._indicator.visible = indicatorCount < 1 && nConnected > 0;
        } else if (this._hideBluetoothIndicator === 1) {
            QuickSettingsMenu._bluetooth._indicator.visible = false;
        } else {
            QuickSettingsMenu._bluetooth._indicator.visible = nConnected > 0;
        }

        this.enhancedDeviceManager?.updateEnhancedDevicesInstance();
    }

    _addIndicatorBoxLayout() {
        this._indicatorBox = new St.BoxLayout({
            x_align: Clutter.ActorAlign.CENTER,
            style_class: 'panel-status-indicators-box',
        });
        if (this._enablePanelButton && !this._panelSingleIndicator && this.panelButton) {
            this.panelButton.add_child(this._indicatorBox);
        } else if (this.enableIndicator) {
            this._indicatorBox.quickSettingsItems = [];
            Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicatorBox);
        }

        this._indicatorBox.connectObject('child-removed', () => {
            if (this._indicatorBox.get_n_children() === 0)
                this._removeIndicatorBoxLayout();
        },
        this
        );
    }

    _removeIndicatorBoxLayout() {
        this._indicatorBox?.disconnectObject(this);
        this._indicatorBox?.destroy();
        this._indicatorBox = null;
    }

    addIndicatorWidget(widget) {
        if (!this._indicatorBox)
            this._addIndicatorBoxLayout();
        this._indicatorBox.add_child(widget);
    }

    _setEnhancedDeviceMode() {
        this.enhancedDeviceManager?.destroy();
        this.enhancedDeviceManager = null;
        const enableEnhancedDeviceMode = [
            this.airpodsEnabled,
            this.sonyEnabled,
            this.galaxyBudsEnabled,
            this.nothingBudsEnabled,
            this.googleBudsEnabled,
            this.boseBudsEnabled,
            this.redmiBudsEnabled,
            this.senhBudsEnabled,
            this.gfpsEnabled,
            this.gattBasEnabled,
        ].some(Boolean);
        if (enableEnhancedDeviceMode && !this.enhancedDeviceManager)
            this.enhancedDeviceManager = new EnhancedDeviceSupportManager(this);
    }

    _updateIndicatorSettings() {
        this.enableIndicator = this._indicatorType === 1;
        this._enablePanelButton = this._indicatorType === 2;
        this.indicatorEnabled =
                this.enableIndicator || this._enablePanelButton && !this._panelSingleIndicator;
        this.multimodeIndicatorEnabled =
                this.indicatorEnabled && this._enableMultimodeIndicator;
        this.hoverModeEnabled = this.enableIndicator && this._enableHoverMode;

        // Tear down the shared indicator box before it gets destroyed as a side
        // effect of the panel button being destroyed below.
        this._removeIndicatorBoxLayout();

        this.panelButton?.destroy();
        this.panelButton = null;

        if (!this.widgetInfo.isUnlockSession && this._enablePanelButton && !this.panelButton) {
            if (this._panelSingleIndicator) {
                this.panelButton = new PanelButtonSingleDevice(
                    this.settings, this.gIcon, this.widgetInfo);
            } else {
                this.panelButton = new PanelButtonMultiDevice(
                    this.settings, this.gIcon, this.widgetInfo);
            }
            Main.panel.addToStatusArea(this._extuuid, this.panelButton);
        }
    }

    _updateColors() {
        const accentColor = getAccentColor();
        const qsBox = Main.panel.statusArea.quickSettings.menu.box;
        if (!qsBox)
            return;
        const panelBackgroundRGB = qsBox.get_theme_node().get_background_color();
        this.widgetInfo.accentColor = accentColor;
        const luminanceFactor = isDarkMode(panelBackgroundRGB) ? 15 : -5;
        this.connectedColor = adjustColorLuminanceToRgba(accentColor, luminanceFactor);
    }

    destroy() {
        this._syncRunning = false;
        this._syncPending = false;
        if (this._idleTimerId)
            GLib.source_remove(this._idleTimerId);
        this._idleTimerId = null;
        if (this._originalSync)
            this._bluetoothToggle._sync = () => {};
        if (this._originalReorderDeviceItems)
            this._bluetoothToggle._reorderDeviceItems = () => {};
        if (this._originalRemoveDevice)
            this._bluetoothToggle._removeDevice = () => {};
        if (this._delayedTimerId)
            GLib.source_remove(this._delayedTimerId);
        this._delayedTimerId = null;
        if (this._themeContext)
            this._themeContext.disconnectObject(this);
        if (this.settings)
            this.settings.disconnectObject(this);
        Main.sessionMode.disconnectObject(this);
        this._connectSettingsSignal(false);
        this._upowerClient?.destroy();
        this._upowerClient = null;
        if (this._deviceItems) {
            this._deviceItems.forEach(item => item.destroy());
            this._deviceItems.clear();
        }
        this.enhancedDeviceManager?.destroy();
        this.enhancedDeviceManager = null;
        this.panelButton?.destroy();
        this.panelButton = null;
        this._deviceItems = null;
        this.deviceList = null;
        this._removeIndicatorBoxLayout();
        this._themeContext = null;
        this.settings = null;
        if (this._bluetoothToggle && this._originalRemoveDevice)
            this._bluetoothToggle._removeDevice = this._originalRemoveDevice;
        this._originalRemoveDevice = null;
        if (this._bluetoothToggle && this._originalReorderDeviceItems)
            this._bluetoothToggle._reorderDeviceItems = this._originalReorderDeviceItems;
        this._originalReorderDeviceItems = null;
        if (this._bluetoothToggle && this._originalSync)
            this._bluetoothToggle._sync = this._originalSync;
        this._originalSync = null;
        if (this._bluetoothToggle && this._originalOnActiveChanged)
            this._bluetoothToggle._onActiveChanged = this._originalOnActiveChanged;
        this._originalOnActiveChanged = null;
        if (QuickSettingsMenu._bluetooth && this._originalBluetoothIndicatorSync)
            QuickSettingsMenu._bluetooth._sync = this._originalBluetoothIndicatorSync;
        this._originalBluetoothIndicatorSync = null;
        this._bluetoothToggle?._onActiveChanged();
    }
});

