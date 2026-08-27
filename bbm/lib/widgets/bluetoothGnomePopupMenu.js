'use strict';
import GObject from 'gi://GObject';
import St from 'gi://St';
import {Spinner} from 'resource:///org/gnome/shell/ui/animation.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

export const BluetoothGnomePopupMenuItem = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_BluetoothGnomePopupMenuItem',
}, class BluetoothGnomePopupMenuItem extends PopupMenu.PopupBaseMenuItem {
    _init(manager) {
        super._init({
            style_class: 'bt-device-item',
        });
        this._manager = manager;
        this._toggle = manager.toggle;
        this._client = this._toggle._bluetoothToggle._client;
        this._gIcon = manager.gIcon;
        this._device = manager.device;
        this._iconType = manager.deviceIcon;

        this._icon = new St.Icon({
            style_class: 'popup-menu-icon',
        });
        this._icon.set_gicon(this._gIcon(`bbm-${this._iconType}-symbolic.svg`));
        this.add_child(this._icon);

        this._label = new St.Label({
            x_expand: true,
        });
        this.add_child(this._label);

        this._subtitle = new St.Label({
            style_class: 'device-subtitle',
        });
        this.add_child(this._subtitle);

        this._spinner = new Spinner(16, {hideOnStop: true});
        this.add_child(this._spinner);

        this._spinner.bind_property('visible',
            this._subtitle, 'visible',
            GObject.BindingFlags.SYNC_CREATE |
            GObject.BindingFlags.INVERT_BOOLEAN);

        this._device.bind_property('connectable',
            this, 'visible',
            GObject.BindingFlags.SYNC_CREATE);

        this._device.bind_property('alias',
            this._label, 'text',
            GObject.BindingFlags.SYNC_CREATE);
        this._device.bind_property_full('connected',
            this._subtitle, 'text',
            GObject.BindingFlags.SYNC_CREATE,
            (bind, source) => [true, source ? _('Disconnect') : _('Connect')],
            null);

        this.connect('destroy', () => (this._spinner = null));
        this.connect('activate', () => this._toggleConnected().catch(logError));
        this._device.connectObject(
            'notify::alias', () => this._updateAccessibleName(),
            'notify::connected', () => this._updateAccessibleName(),
            this);
        this._updateAccessibleName();
    }

    async _toggleConnected() {
        this._spinner.play();
        await this._client.toggleDevice(this._device);
        this._spinner?.stop();
    }

    _updateAccessibleName() {
        this.accessible_name = this._device.connected
            // Translators: %s is a device name like "MyPhone"
            ? _('Disconnect %s').format(this._device.alias)
            // Translators: %s is a device name like "MyPhone"
            : _('Connect to %s').format(this._device.alias);
    }

    updateProperties(_qsLevelEnabled, deviceIcon) {
        if (this._iconType !== deviceIcon) {
            this._iconType = deviceIcon;
            this._icon?.set_gicon(this._gIcon(`bbm-${this._iconType}-symbolic.svg`));
        }
    }
});

