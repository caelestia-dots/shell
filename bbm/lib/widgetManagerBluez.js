'use strict';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

import {BluetoothIndicator} from './widgets/bluetoothIndicator.js';
import {BluetoothGnomePopupMenuItem} from './widgets/bluetoothGnomePopupMenu.js';
import {BluetoothPopupMenuItem} from './widgets/bluetoothPopupMenu.js';
import {BluetoothPopupSubMenuItem} from './widgets/bluetoothPopupSubMenu.js';
import {OnHoverMenu} from './widgets/onHoverMenu.js';
import {createConfig, createProperties, DataHandler} from './dataHandler.js';

export const WidgetManagerBluez = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_WidgetManagerBluez',
    Properties: {
        'batteryPercentage': GObject.ParamSpec.int('batteryPercentage', '', 'Battery Percentage',
            GObject.ParamFlags.READWRITE, 0, 100, 0),
    },
}, class WidgetManagerBluez extends GObject.Object {
    _init(toggle, device, batteryReported, qsLevelEnabled, indicatorMode, deviceIcon) {
        super._init();
        this.toggle = toggle;
        this.settings = toggle.settings;
        this.path = device.get_object_path();
        this.device = device;
        this.deviceIcon = deviceIcon;
        this.alias = device.alias;
        this.gIcon = toggle.gIcon;
        this.widgetInfo = toggle.widgetInfo;
        this.isUnlockSession = this.widgetInfo.isUnlockSession;
        this.hoverModeEnabled = toggle.hoverModeEnabled;
        this.batteryReported = batteryReported;
        this.qsLevelEnabled = qsLevelEnabled;
        this.indicatorMode = indicatorMode;
        this._client = toggle._bluetoothToggle._client;
        this._config = createConfig();
        this._props = createProperties();

        this._checkLateBluezBatteryReporting();

        if (!this.toggle.modifyQuickSettings)
            this.popupMenuItem = new BluetoothGnomePopupMenuItem(this);
        else if (this.toggle.usePopupInQuickSettings)
            this.popupMenuItem = new BluetoothPopupSubMenuItem(this);
        else
            this.popupMenuItem = new BluetoothPopupMenuItem(this);




        this.device.connectObject(
            'notify::alias', () => this._aliasUpdated(this.alias),
            'notify::connected', () => {
                if (!this.device.connected) {
                    this._destroyOnDisconnect();
                    this.batteryPercentage = 0;
                }
                this._recordTimeEvent();
            },
            this
        );
    }

    _checkLateBluezBatteryReporting() {
        this.device.bind_property('battery_percentage',
            this, 'batteryPercentage',
            GObject.BindingFlags.SYNC_CREATE);
        this.connectObject(
            'notify::batteryPercentage', () => {
                if (!this.batteryReported && this.device.battery_percentage > 0) {
                    const props = this.toggle.deviceList.get(this.path);
                    this.toggle.deviceList.set(this.path, {
                        ...props, batteryReported: true,
                        qsLevelEnabled: true, indicatorMode: 2,
                    });
                    this.batteryReported = true;
                    this.toggle.pushDevicesToGsetting();
                }
                this._updateDataHandler();
            },
            this
        );
        this._updateDataHandler();
    }

    _updateDataHandler() {
        if (!this._dataHandler && this.device.battery_percentage > 0) {
            this._config.battery1Icon = this.deviceIcon;
            this._config.commonIcon = this.deviceIcon;
            this._config.albumArtIcon = this.deviceIcon;
            this._props.computedBatteryLevel = this.batteryPercentage;
            this._props.battery1Level = this.batteryPercentage;
            this._dataHandler = new DataHandler(this._config, this._props);
            this.popupMenuItem?.setDataHandler?.(this._dataHandler);
            this._updateUI();
        } else if (this.device.battery_percentage > 0) {
            this._props.computedBatteryLevel = this.batteryPercentage;
            this._props.battery1Level = this.batteryPercentage;
            this._dataHandler?.setProps(this._props);
        }
        this._updateUI();
    }

    update() {
        if (this.toggle.deviceList.has(this.path)) {
            let qsPropsUpdated = false;
            let indicatorPropsUpdated = false;
            const props = this.toggle.deviceList.get(this.path);
            if (this.qsLevelEnabled !== props.qsLevelEnabled) {
                this.qsLevelEnabled = props.qsLevelEnabled;
                qsPropsUpdated = true;
            }
            if (this.deviceIcon !== props.icon) {
                this.deviceIcon = props.icon;
                this._config.battery1Icon = this.deviceIcon;
                this._config.commonIcon = this.deviceIcon;
                this._config.albumArtIcon = this.deviceIcon;
                this._dataHandler?.setConfig(this._config);
                qsPropsUpdated = true;
                indicatorPropsUpdated = true;
            }
            if (qsPropsUpdated)
                this.popupMenuItem?.updateProperties(this.qsLevelEnabled, this.deviceIcon);

            if (this.indicatorMode !== props.indicatorMode) {
                this.indicatorMode = props.indicatorMode;
                indicatorPropsUpdated = true;
            }
            if (indicatorPropsUpdated)
                this.indicator?.updateProperties(this.indicatorMode, this.deviceIcon);

            if (this.indicatorMode === 0)
                this._destroyIndicator();
            else
                this._updateDataHandler();
        }
    }

    _aliasUpdated(alias) {
        if (this._onHoverMenu)
            this._onHoverMenu.updateAlias(alias);
        if (this.toggle.panelButton)
            this._popupMenuWidgetItem?.updateAlias(alias);
        this.popupMenuItem?.updateAlias?.(alias);
    }

    _updateUI() {
        if (!this.device.connected)
            return;

        if (this._dataHandler) {
            if (this.toggle.panelButton && !this.isUnlockSession && !this._popupMenuWidgetItem) {
                this._popupMenuWidgetItem =
                    this.toggle.panelButton.addDevice(this.path, this.alias, this._dataHandler);
            }

            this._startIndicator();
        } else if (this.toggle.enableIndicator && this.indicatorMode === 1) {
            this._startIndicator();
        }
    }

    _startIndicator() {
        if (!this.device.connected || this.indicator || !this.deviceIcon)
            return;

        if (!this.toggle.indicatorEnabled || this.indicatorMode === 0)
            return;

        this.indicator = new BluetoothIndicator(this);
        this.toggle.addIndicatorWidget(this.indicator);

        if (!this.hoverModeEnabled || this._onHoverMenu)
            return;

        if (this.isUnlockSession || this.indicatorMode !== 2)
            return;

        this._onHoverMenu = new OnHoverMenu(this.indicator, this.settings, this.gIcon,
            this.path, this.alias, this.widgetInfo, this._dataHandler);
    }

    _recordTimeEvent() {
        let stateChanged = false;

        if (this._stateSignalId)
            this._client._client.disconnect(this._stateSignalId);

        this._stateSignalId = this._client._client.connect(
            'notify::default-adapter-state', () => {
                stateChanged = true;
                if (this._eventTimerId) {
                    GLib.Source.remove(this._eventTimerId);
                    this._eventTimerId = null;
                }
                this._client._client.disconnect(this._stateSignalId);
            }
        );

        if (this._eventTimerId)
            GLib.source_remove(this._eventTimerId);

        this._eventTimerId = GLib.timeout_add_seconds(GLib.PRIORITY_LOW, 3, () => {
            if (this.toggle && !stateChanged) {
                const currentTime = GLib.DateTime.new_now_utc().to_unix();
                const props = this.toggle.deviceList.get(this.path);
                if (this.device.connected) {
                    this.toggle.deviceList
                        .set(this.path, {...props, connectedTime: currentTime});
                } else {
                    this.toggle.deviceList
                        .set(this.path, {...props, disconnectedTime: currentTime});
                }
                this.toggle.delayedUpdateDeviceGsettings();
            }

            if (this._stateSignalId)
                this._client._client.disconnect(this._stateSignalId);
            this._stateSignalId = null;
            this._eventTimerId = null;
            return GLib.SOURCE_REMOVE;
        });
    }

    _destroyIndicator() {
        this._onHoverMenu?.destroy();
        this._onHoverMenu = null;
        this.indicator?.destroy();
        this.indicator = null;
    }

    _destroyOnDisconnect() {
        this._dataHandler = null;
        this.toggle?.panelButton?.removeDevice(this.path);
        this._popupMenuWidgetItem = null;
        this._destroyIndicator();
    }

    destroy() {
        if (this._eventTimerId)
            GLib.source_remove(this._eventTimerId);
        this._eventTimerId = null;
        if (this._stateSignalId)
            this._client?._client?.disconnect(this._stateSignalId);
        this._stateSignalId = null;
        this.settings?.disconnectObject(this);
        this.device?.disconnectObject(this);
        this.disconnectObject(this);
        this._destroyOnDisconnect();
        this.popupMenuItem?.destroy();
        this.popupMenuItem = null;
        this._client = null;
        this.settings = null;
        this.toggle = null;
        this.device = null;
    }
});
