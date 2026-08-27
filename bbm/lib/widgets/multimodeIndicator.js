'use strict';
import GObject from 'gi://GObject';
import St from 'gi://St';

import {BluetoothIndicator} from './bluetoothIndicator.js';
import {OnHoverMenu} from './onHoverMenu.js';

const BatteryLevelProxy = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_BatteryLevelProxy',
    Properties: {
        'batteryPercentage': GObject.ParamSpec.int(
            'batteryPercentage', '', 'Battery Percentage',
            GObject.ParamFlags.READWRITE, 0, 100, 0
        ),
    },
}, class BatteryLevelProxy extends GObject.Object {});

export const MultimodeIndicator = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_MultimodeIndicator',
}, class MultimodeIndicator extends GObject.Object {
    _init(manager, dataHandler) {
        super._init();
        this._manager = manager;
        this._dataHandler = dataHandler;
        this._toggle = manager.toggle;
        this._settings = manager.settings;
        this._indicatorMode = manager.indicatorMode;
        this._gIcon = manager.gIcon;
        this._path = manager.path;
        this._alias = manager.alias;
        this._widgetInfo = manager.widgetInfo;
        this._hoverModeEnabled = manager.hoverModeEnabled;
        this._isUnlockSession = manager.isUnlockSession;
        this._config = dataHandler.getConfig();
        this._props = dataHandler.getProps();
        this._updateIndicators();

        this._dataHandler.connectObject(
            'configuration-changed', () => {
                this._config = this._dataHandler.getConfig();
                this._updateIndicators();
            },
            'properties-changed', () => {
                this._props = this._dataHandler.getProps();
                this._updateIndicators();
            },
            this
        );
    }

    _addIndicatorBoxLayout() {
        this._indicatorBox = new St.BoxLayout({
            style_class: 'panel-status-indicators-box',
            reactive: true,
        });
        this._indicatorBox.quickSettingsItems = [];
        this._toggle.addIndicatorWidget(this._indicatorBox);

        if (this._hoverModeEnabled && !this._isUnlockSession && !this._onHoverMenu) {
            this._onHoverMenu = new OnHoverMenu(this._indicatorBox, this._settings, this._gIcon,
                this._path, this._alias, this._widgetInfo, this._dataHandler);
        }

        this._indicatorBox.connectObject('child-removed', () => {
            if (this._indicatorBox.get_n_children() === 0)
                this._removeIndicatorBoxLayout();
        },
        this
        );
    }

    _removeIndicatorBoxLayout() {
        this._onHoverMenu?.destroy();
        this._onHoverMenu = null;
        this._indicatorBox?.disconnectObject(this);
        this._indicatorBox?.destroy();
        this._indicatorBox = null;
    }

    _addIndicatorWidget(widget) {
        if (!this._indicatorBox)
            this._addIndicatorBoxLayout();
        this._indicatorBox.add_child(widget);
    }

    _updateIndicators() {
        if (this._config.battery1Icon && this._props.battery1Level > 0) {
            if (!this._bat1Indicator) {
                this._bat1Proxy = new BatteryLevelProxy();
                this._bat1Proxy.settings = this._settings;
                this._bat1Proxy.gIcon = this._gIcon;
                this._bat1Proxy.widgetInfo = this._widgetInfo;
                this._bat1Proxy.indicatorMode = this._indicatorMode;
                this._bat1Proxy.deviceIcon = this._config.battery1Icon;
                this._bat1Proxy.batteryPercentage = this._props.battery1Level;
                this._bat1Indicator =
                    this._addIndicator(this._bat1Proxy);
                this._addIndicatorWidget(this._bat1Indicator);
            } else {
                this._bat1Proxy.batteryPercentage = this._props.battery1Level;
            }
        } else {
            this._bat1Indicator?.destroy();
            this._bat1Indicator = null;
            this._bat1Proxy = null;
        }

        if (this._config.battery2Icon && this._props.battery2Level > 0) {
            if (!this._bat2Indicator) {
                this._bat2Proxy = new BatteryLevelProxy();
                this._bat2Proxy.settings = this._settings;
                this._bat2Proxy.gIcon = this._gIcon;
                this._bat2Proxy.widgetInfo = this._widgetInfo;
                this._bat2Proxy.indicatorMode = this._indicatorMode;
                this._bat2Proxy.deviceIcon = this._config.battery2Icon;
                this._bat2Proxy.batteryPercentage = this._props.battery2Level;

                this._bat2Indicator =
                    this._addIndicator(this._bat2Proxy);
                this._addIndicatorWidget(this._bat2Indicator);
            } else {
                this._bat2Proxy.batteryPercentage = this._props.battery2Level;
            }
        } else {
            this._bat2Indicator?.destroy();
            this._bat2Indicator = null;
            this._bat2Proxy = null;
        }

        if (this._config.battery3Icon && this._props.battery3Level > 0) {
            if (!this._bat3Indicator) {
                this._bat3Proxy = new BatteryLevelProxy();
                this._bat3Proxy.settings = this._settings;
                this._bat3Proxy.gIcon = this._gIcon;
                this._bat3Proxy.widgetInfo = this._widgetInfo;
                this._bat3Proxy.indicatorMode = this._indicatorMode;
                this._bat3Proxy.deviceIcon = this._config.battery3Icon;
                this._bat3Proxy.batteryPercentage = this._props.battery3Level;

                this._bat3Indicator =
                    this._addIndicator(this._bat3Proxy);
                this._addIndicatorWidget(this._bat3Indicator);
            } else {
                this._bat3Proxy.batteryPercentage = this._props.battery3Level;
            }
        } else {
            this._bat3Indicator?.destroy();
            this._bat3Indicator = null;
            this._bat3Proxy = null;
        }
    }

    _addIndicator(proxy) {
        return new BluetoothIndicator(proxy);
    }

    // eslint-disable-next-line no-unused-vars
    updateProperties(indicatorMode, deviceIcon) {
        this._bat1Indicator?.updateProperties(indicatorMode, this._config.battery1Icon);
        this._bat2Indicator?.updateProperties(indicatorMode, this._config.battery2Icon);
        this._bat3Indicator?.updateProperties(indicatorMode, this._config.battery3Icon);
    }

    updateAlias(alias) {
        this._onHoverMenu?.updateAlias(alias);
    }

    destroy() {
        this._dataHandler.disconnectObject(this);
        this._onHoverMenu?.destroy();
        this._onHoverMenu = null;
        this._bat1Indicator?.destroy();
        this._bat1Indicator = null;
        this._bat2Indicator?.destroy();
        this._bat2Indicator = null;
        this._bat3Indicator?.destroy();
        this._bat3Indicator = null;
        this._indicatorBox?.destroy();
        this._indicatorBox = null;
        this._dataHandler = null;
    }
});

