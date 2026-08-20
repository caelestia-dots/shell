'use strict';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

import {BluetoothIndicator} from './widgets/bluetoothIndicator.js';
import {BluetoothGnomePopupMenuItem} from './widgets/bluetoothGnomePopupMenu.js';
import {BluetoothPopupMenuItem} from './widgets/bluetoothPopupMenu.js';
import {BluetoothPopupSubMenuItem} from './widgets/bluetoothPopupSubMenu.js';
import {OnHoverMenu} from './widgets/onHoverMenu.js';
import {MultimodeIndicator} from './widgets/multimodeIndicator.js';

export const WidgetManagerEnhanced = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_WidgetManagerEnhanced',
    Properties: {
        'batteryPercentage': GObject.ParamSpec.int('batteryPercentage', '', 'Battery Percentage',
            GObject.ParamFlags.READWRITE, 0, 100, 0),
    },
}, class WidgetManagerEnhanced extends GObject.Object {
    _init(toggle, device, qsLevelEnabled, indicatorMode, deviceIcon, enhancedDeviceProps) {
        super._init();
        this.widgetManagerEnhanced = true;
        this.toggle = toggle;
        this.settings = toggle.settings;
        this.path = device.get_object_path();
        this.device = device;
        this.deviceIcon = deviceIcon;
        this.alias = device.alias;
        this.gIcon = toggle.gIcon;
        this.type = enhancedDeviceProps?.type;
        this._dataHandler = enhancedDeviceProps?.dataHandler;
        this.widgetInfo = toggle.widgetInfo;
        this._enableMultimodeIndicator = toggle.multimodeIndicatorEnabled;
        this.hoverModeEnabled = toggle.hoverModeEnabled;
        this.isUnlockSession = this.widgetInfo.isUnlockSession;
        this.qsLevelEnabled = qsLevelEnabled;
        this.indicatorMode = indicatorMode;
        this._client = toggle._bluetoothToggle._client;

        if (this._dataHandler)
            this._updateUI();

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

    setDataHandler(dataHandler) {
        if (!this._dataHandler && dataHandler) {
            this._dataHandler = dataHandler;
            this._setDevIcon();
            this._updateUI();
            this.popupMenuItem?.setDataHandler?.(dataHandler);
        }
    }

    _setDevIcon() {
        if (this._dataHandler) {
            const extIcon = this._dataHandler.getConfig().commonIcon;
            if (this.deviceIcon !== extIcon) {
                this.deviceIcon = extIcon;
                this.popupMenuItem?.updateProperties(this.qsLevelEnabled, this.deviceIcon);
                const props = this.toggle.deviceList.get(this.path);
                this.toggle.deviceList.set(this.path, {...props, icon: extIcon});
                this.toggle.delayedUpdateDeviceGsettings();
            }
        }
    }

    update() {
        const props = this.toggle.deviceList.get(this.path);
        if (!props)
            return;

        const qsChanged = this.qsLevelEnabled !== props.qsLevelEnabled;
        const indicatorChanged = this.indicatorMode !== props.indicatorMode;

        if (qsChanged) {
            this.qsLevelEnabled = props.qsLevelEnabled;
            this.popupMenuItem?.updateProperties(this.qsLevelEnabled, this.deviceIcon);
        }

        if (indicatorChanged) {
            this.indicatorMode = props.indicatorMode;
            this.indicator?.updateProperties(this.indicatorMode, this.deviceIcon);
            this._destroyIndicator();

            if (this.indicatorMode !== 0)
                this._startIndicator();
        }
    }


    _aliasUpdated(alias) {
        if (this._onHoverMenu)
            this._onHoverMenu.updateAlias(alias);
        if (this._enableMultimodeIndicator)
            this.indicator?.updateAlias(alias);
        if (this.toggle.panelButton)
            this._popupMenuWidgetItem?.updateAlias(alias);
        this.popupMenuItem?.updateAlias?.(alias);
    }

    _updateUI() {
        if (this._dataHandler && this.device.connected) {
            this._dataHandler.connectObject(
                'configuration-changed', () => {
                    if (this.type) {
                        this._setDevIcon();
                        this.indicator?.updateProperties(this.indicatorMode, this.deviceIcon);
                    }
                },
                'properties-changed', () => {
                    const battProps = this._dataHandler.getProps();
                    this.batteryPercentage  = battProps.computedBatteryLevel;
                },
                this
            );

            const battProps = this._dataHandler.getProps();
            this.batteryPercentage  = battProps.computedBatteryLevel;

            if (this.toggle.panelButton && !this.isUnlockSession) {
                this._popupMenuWidgetItem =
                    this.toggle.panelButton.addDevice(this.path, this.alias, this._dataHandler);
            }

            this._startIndicator();
        }
    }

    _startIndicator() {
        if (!this.device.connected || this.indicator || !this.deviceIcon || !this._dataHandler)
            return;

        if (!this.toggle.indicatorEnabled || this.indicatorMode === 0)
            return;

        if (this._enableMultimodeIndicator && this.indicatorMode === 2) {
            this.indicator = new MultimodeIndicator(this, this._dataHandler);
            return;
        }

        this.indicator = new BluetoothIndicator(this);
        this.toggle.addIndicatorWidget(this.indicator);

        if (this.hoverModeEnabled && !this.isUnlockSession && !this._onHoverMenu) {
            this._onHoverMenu = new OnHoverMenu(this.indicator, this.settings, this.gIcon,
                this.path, this.alias, this.widgetInfo, this._dataHandler);
        }
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
        this._dataHandler?.disconnectObject(this);
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
