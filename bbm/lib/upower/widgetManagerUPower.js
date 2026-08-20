'use strict';
import GObject from 'gi://GObject';

import {BluetoothIndicator} from '../widgets/bluetoothIndicator.js';
import {OnHoverMenu} from '../widgets/onHoverMenu.js';
import {createConfig, createProperties, DataHandler} from '../dataHandler.js';

export const WidgetManagerUPower = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_WidgetManagerUPower',
    Properties: {
        'batteryPercentage': GObject.ParamSpec.int('batteryPercentage', '', 'Battery Percentage',
            GObject.ParamFlags.READWRITE, 0, 100, 0),
    },
}, class WidgetManagerUPower extends GObject.Object {
    _init(toggle, path, alias, deviceIcon, percentage) {
        super._init();
        this.toggle = toggle;
        this.settings = toggle.settings;
        this.path = path;
        this.deviceIcon = deviceIcon;
        this.alias = alias;
        this.gIcon = this.toggle.gIcon;
        this.widgetInfo = toggle.widgetInfo;
        this.isUnlockSession = this.widgetInfo.isUnlockSession;
        this.hoverModeEnabled = toggle.hoverModeEnabled;
        this.batteryPercentage = percentage;
        this.indicatorMode = 2;
        this._dconfig = createConfig();
        this._dprops = createProperties();
        this._dconfig.battery1Icon = this.deviceIcon;
        this._dconfig.commonIcon = this.deviceIcon;
        this._dconfig.albumArtIcon = this.deviceIcon;
        this._dprops.computedBatteryLevel = this.batteryPercentage;
        this._dprops.battery1Level = this.batteryPercentage;
        this._dataHandler = new DataHandler(this._dconfig, this._dprops);
        this._updateUI();
    }

    updatePercentage(percentage) {
        this.batteryPercentage = percentage;
    }

    _updateUI() {
        if (this.toggle.panelButton && !this.isUnlockSession && !this._popupMenuWidgetItem) {
            this._popupMenuWidgetItem =
                    this.toggle.panelButton.addDevice(this.path, this.alias, this._dataHandler);
        }

        this._startIndicator();
    }

    _startIndicator() {
        if (this.indicator || !this.deviceIcon)
            return;
        this.indicator = new BluetoothIndicator(this);
        this.toggle.addIndicatorWidget(this.indicator);

        if (this.hoverModeEnabled && !this.isUnlockSession && !this._onHoverMenu) {
            this._onHoverMenu = new OnHoverMenu(this.indicator, this.settings, this.gIcon,
                this.path, this.alias, this.widgetInfo, this._dataHandler);
        }
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
        this._destroyOnDisconnect();
        this.settings = null;
        this.toggle = null;
        this._device = null;
    }
});
