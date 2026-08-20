'use strict';
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import Pango from 'gi://Pango';
import St from 'gi://St';
import * as QuickSettings from 'resource:///org/gnome/shell/ui/quickSettings.js';

import {IndicatorIconWidget} from './indicatorIconWidget.js';

export const BluetoothIndicator = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_BluetoothIndicator',
}, class BluetoothIndicator extends QuickSettings.SystemIndicator {
    _init(manager) {
        super._init();
        this._manager = manager;
        this._settings = manager.settings;
        this._indicatorMode = manager.indicatorMode;
        this._gIcon = manager.gIcon;
        this._deviceIcon = manager.deviceIcon;
        this._widgetInfo = manager.widgetInfo;
        this._iconSize = null;

        this._disableLevelInIcon = this._widgetInfo.disableLevelInIcon;
        this._indicatorWithText = this._widgetInfo.indicatorWithText;

        if (this._disableLevelInIcon)
            this._iconWithoutBatteryLevel();
        else
            this._iconWithBatteryLevel();
    }

    _iconWithoutBatteryLevel() {
        this._indicator = new St.Icon();
        this._indicator.gicon =  this._gIcon(`bbm-${this._deviceIcon}-symbolic.svg`);
        this._indicator.style_class = 'system-status-icon';
        this.add_child(this._indicator);

        this._manager.bind_property_full('batteryPercentage',
            this._indicator, 'visible',
            GObject.BindingFlags.SYNC_CREATE,
            (bind, source) => [true, !(source <= 0)], null);

        this._syncIndicatorsVisible();

        this._indicator.connectObject('notify::visible', () =>
            this._syncIndicatorsVisible(), this);

        if (this._indicatorWithText)
            this._addTextToIndicator();
    }

    _iconWithBatteryLevel() {
        this._indicator = new St.Bin();
        this._indicator.style_class = 'system-status-icon';
        this.add_child(this._indicator);
        this._syncIndicatorsVisible();

        this._indicator.connectObject('notify::visible', () =>
            this._syncIndicatorsVisible(), this);

        this._levelWidget = new IndicatorIconWidget(this._settings, this._indicator,
            this._indicatorMode, this._deviceIcon, this._widgetInfo);

        this._indicator.set_child(this._levelWidget);

        const themenode = this._indicator.peek_theme_node();
        if (themenode === null) {
            this._indicatorStyleChangeId = this._indicator.connect('style-changed', () => {
                const node = this._indicator.peek_theme_node();
                if (node !== null) {
                    if (this._indicatorStyleChangeId)
                        this._indicator.disconnect(this._indicatorStyleChangeId);
                    this._indicatorStyleChangeId = null;
                    this._getWidgetSize(node);
                }
            });
        } else {
            this._getWidgetSize(themenode);
        }

        this.connectObject(
            'destroy', () => {
                if (this._indicatorStyleChangeId)
                    this._indicator.disconnect(this._indicatorStyleChangeId);
                this._indicatorStyleChangeId = null;
                this._indicator?.destroy();
            },
            this
        );


        if (this._indicatorMode === 1) {
            this._indicator.visible = true;
        } else {
            this._manager.bind_property_full('batteryPercentage',
                this._indicator, 'visible',
                GObject.BindingFlags.SYNC_CREATE,
                (bind, source) => [true, !(source <= 0)], null);
        }

        this._manager.connectObject(
            'notify::batteryPercentage', () => {
                this._levelWidget?.updateValues(this._manager.batteryPercentage);
            },
            this
        );

        this._levelWidget.updateValues(this._manager.batteryPercentage);

        if (this._indicatorWithText && this._indicatorMode === 2)
            this._addTextToIndicator();
    }

    _getWidgetSize(themeNode) {
        const [found, iconSize] = themeNode.lookup_length('icon-size', false);
        if (found)
            this._levelWidget.setIconSize(iconSize);
    }

    _addTextToIndicator() {
        this._percentageLabel = new St.Label({
            y_expand: true,
            y_align: Clutter.ActorAlign.CENTER,
        });
        const clutterText = this._percentageLabel.get_clutter_text();
        clutterText.ellipsize = Pango.EllipsizeMode.NONE;
        this.add_child(this._percentageLabel);
        this.add_style_class_name('power-status');
        const formatter = new Intl.NumberFormat(undefined, {style: 'percent'});
        this._percentageLabel.visible = false;

        this._manager.bind_property_full('batteryPercentage',
            this._percentageLabel, 'text',
            GObject.BindingFlags.SYNC_CREATE,
            (bind, source) => [true, formatter.format(source / 100)], null);

        this._manager.bind_property_full('batteryPercentage',
            this._percentageLabel, 'visible',
            GObject.BindingFlags.SYNC_CREATE,
            (bind, source) => [true, source > 0], null);
    }

    updateProperties(indicatorMode, deviceIcon) {
        this._indicatorMode = indicatorMode;
        this._deviceIcon = deviceIcon;
        if (this._disableLevelInIcon)
            this._indicator.gicon =  this._gIcon(`bbm-${deviceIcon}-symbolic.svg`);
        else
            this._levelWidget?.updateProperties(indicatorMode, deviceIcon);
    }
});
