'use strict';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

export const BluetoothPopupMenuItem = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_BluetoothPopupMenuItem',
}, class BluetoothPopupMenuItem extends PopupMenu.PopupBaseMenuItem {
    _init(manager) {
        super._init({
            style_class: 'bt-device-item',
        });
        this._manager = manager;
        this._toggle = manager.toggle;
        this._settings = manager.settings;
        this._client = this._toggle._bluetoothToggle._client;
        this._gIcon = manager.gIcon;
        this._showBatteryPercentage = this._toggle.showBatteryPercentage;
        this._showBatteryIcon = this._toggle.showBatteryIcon;
        this._swapIconText = this._toggle.swapIconText;
        this._connectedColor = this._toggle.connectedColor;
        this._disconnectedColor = null;
        this._device = manager.device;
        this._iconType = manager.deviceIcon;
        this._qsLevelEnabled = manager.qsLevelEnabled;

        const themeNode = this.peek_theme_node();
        if (themeNode === null) {
            this._backgroundStyleChangeId = this.connect('style-changed', () => {
                const node = this.peek_theme_node();
                if (node !== null) {
                    if (this._backgroundStyleChangeId)
                        this.disconnect(this._backgroundStyleChangeId);
                    this._backgroundStyleChangeId = null;
                    this._buildUI(node);
                }
            });
        } else {
            this._buildUI(themeNode);
        }
    }

    _buildUI(themeNode) {
        this._disconnectedColor = themeNode.get_foreground_color();
        this._icon = new St.Icon({
            style_class: 'popup-menu-icon',
        });
        this._icon.set_gicon(this._gIcon(`bbm-${this._iconType}-symbolic.svg`));
        this.add_child(this._icon);

        this._label = new St.Label({
            x_expand: true,
        });
        this.add_child(this._label);

        if (this._swapIconText) {
            this._displayBatteryLevelIcon();
            this._displayBatteryLevelTextPercentage();
        } else {
            this._displayBatteryLevelTextPercentage();
            this._displayBatteryLevelIcon();
        }

        this._pairIcon = new St.Icon({
            style_class: 'popup-menu-icon bbm-bt-pair-widget',
        });
        this.add_child(this._pairIcon);

        this._device.bind_property('connectable',
            this, 'visible',
            GObject.BindingFlags.SYNC_CREATE);

        this._device.bind_property('alias',
            this._label, 'text',
            GObject.BindingFlags.SYNC_CREATE);

        this._device.bind_property_full('connected',
            this, 'accessible_name',
            GObject.BindingFlags.SYNC_CREATE,
            (bind, source) => [true, source ? _('Disconnect') : _('Connect')],
            null);

        this._assignPairingIcon(false);

        this.activate = __ => {
            this._toggleConnected().catch(logError);
        };

        this._device.connectObject(
            'notify::connected', () => {
                this._assignPairingIcon(false);
            },
            this
        );

        this.connectObject('destroy', () => {
            if (this._iconChangeTimerId)
                GLib.source_remove(this._iconChangeTimerId);
            this._iconChangeTimerId = null;
            if (this._backgroundStyleChangeId)
                this.disconnect(this._backgroundStyleChangeId);
            this._backgroundStyleChangeId = null;
            if (this._labelStyleChangeId && this._batteryPercentageLabel)
                this._batteryPercentageLabel.disconnect(this._labelStyleChangeId);
            this._labelStyleChangeId = null;
        }, this);
    }

    updateProperties(qsLevelEnabled, deviceIcon) {
        this._qsLevelEnabled = qsLevelEnabled;
        if (this._showBatteryIcon && this._batteryIcon) {
            this._batteryIcon.visible =
                this._qsLevelEnabled && this._manager.batteryPercentage > 0;
        }
        if (this._showBatteryPercentage && this._batteryPercentageLabel) {
            this._batteryPercentageLabel.visible =
                this._qsLevelEnabled && this._manager.batteryPercentage > 0;
        }
        if (this._iconType !== deviceIcon) {
            this._iconType = deviceIcon;
            this._icon?.set_gicon(this._gIcon(`bbm-${this._iconType}-symbolic.svg`));
        }
    }

    _displayBatteryLevelTextPercentage() {
        if (this._showBatteryPercentage) {
            this._batteryPercentageLabel = new St.Label({text: '100%'});
            this.add_child(this._batteryPercentageLabel);
            if (this._batteryPercentageLabel.get_stage()) {
                this._bindLabel();
            } else {
                this._labelStyleChangeId = this._batteryPercentageLabel.connect(
                    'style-changed', () => {
                        const isStaged = this.get_stage();
                        if (isStaged) {
                            if (this._labelStyleChangeId)
                                this._batteryPercentageLabel.disconnect(this._labelStyleChangeId);
                            this._labelStyleChangeId = null;
                            this._bindLabel();
                        }
                    }
                );
            }
        }
    }

    _bindLabel() {
        if (this._swapIconText) {
            this._batteryPercentageLabel
                        .set_width(this._batteryPercentageLabel.get_width());
            this._batteryPercentageLabel.style_class = 'bbm-bt-percentage-label';
        }
        this._batteryPercentageLabel.text = '';

        this._manager.bind_property_full('batteryPercentage',
            this._batteryPercentageLabel, 'visible',
            GObject.BindingFlags.SYNC_CREATE,
            (bind, source) => [true, this._qsLevelEnabled && source > 0], null);

        this._manager.bind_property_full('batteryPercentage',
            this._batteryPercentageLabel, 'text',
            GObject.BindingFlags.SYNC_CREATE,
            (bind, source) => [true, `${source}%`], null);
    }

    _displayBatteryLevelIcon() {
        if (this._showBatteryIcon) {
            this._batteryIcon = new St.Icon({
                style_class: 'popup-menu-icon',
            });
            this.add_child(this._batteryIcon);

            this._manager.bind_property_full('batteryPercentage',
                this._batteryIcon, 'visible',
                GObject.BindingFlags.SYNC_CREATE,
                (bind, source) => [true, this._qsLevelEnabled && source > 0], null);

            this._manager.bind_property_full('batteryPercentage',
                this._batteryIcon, 'icon-name',
                GObject.BindingFlags.SYNC_CREATE,
                (bind, source) => [true, source <= 0 ? ''
                    : `battery-level-${10 * Math.floor(source / 10)}-symbolic`],
                null);
        }
    }

    async _toggleConnected() {
        this._assignPairingIcon(true);
        await this._client.toggleDevice(this._device);
        this._assignPairingIcon(false);
    }

    _assignPairingIcon(toggleActivated) {
        if (toggleActivated) {
            if (this._iconChangeTimerId)
                GLib.source_remove(this._iconChangeTimerId);
            this._counter = 4;
            if (!this._device.connected)
                this._pairIcon?.set_style(`color: ${this._connectedColor};`);
            else
                this._pairIcon?.set_style(`color: ${this._disconnectedColor};`);

            const connected = this._device.connected;
            this._iconChangeTimerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 300, () => {
                this._pairIcon?.set_gicon(connected
                    ? this._gIcon(`bbm-bluetooth-disconnecting-${this._counter}-symbolic.svg`)
                    : this._gIcon(`bbm-bluetooth-connecting-${this._counter}-symbolic.svg`));
                this._counter = this._counter <= 1 ? 4 : this._counter - 1;
                return GLib.SOURCE_CONTINUE;
            });
        } else {
            if (this._iconChangeTimerId)
                GLib.source_remove(this._iconChangeTimerId);
            this._iconChangeTimerId = null;
            if (this._device.connected) {
                this._pairIcon?.set_gicon(this._gIcon('bbm-bluetooth-connected-symbolic.svg'));
                this._pairIcon?.set_style(`color: ${this._connectedColor};`);
            } else {
                this._pairIcon?.set_gicon(
                    this._gIcon('bbm-bluetooth-disconnecting-1-symbolic.svg'));
                this._pairIcon?.set_style(`color: ${this._disconnectedColor};`);
            }
        }
    }
});


