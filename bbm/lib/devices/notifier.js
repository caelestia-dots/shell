'use strict';
import * as MessageTray from 'resource:///org/gnome/shell/ui/messageTray.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import {DeviceTypeAirpods} from './airpods/airpodsDevice.js';
import {DeviceTypeSonyV1, DeviceTypeSonyV2} from './sony/sonyDevice.js';
import {DeviceTypeGalaxyLegacy, DeviceTypeGalaxyBuds} from './galaxyBuds/galaxyBudsDevice.js';
import {DeviceTypeNothingBuds} from './nothingBuds/nothingBudsDevice.js';
import {DeviceTypeGoogleBuds} from './googleBuds/googleBudsDevice.js';
import {DeviceTypeRedmiBuds} from './redmiBuds/redmiBudsDevice.js';
import {DeviceTypeSenhBuds} from './senhBuds/senhBudsDevice.js';
import {DeviceTypeBoseBuds} from './boseBuds/boseBudsDevice.js';
import {DeviceTypeGfps} from './gfps/gfpsDevice.js';

export class Notifier {
    constructor(toggle) {
        this.toggle = toggle;
        this._notification = null;
        this._source = null;
    }

    notifyProfileRegisteredError(type) {
        let label;
        if (type === DeviceTypeAirpods)
            label = _('AirPods / Beats Bluetooth audio devices');
        else if (type === DeviceTypeSonyV1 || type === DeviceTypeSonyV2)
            label = _('Sony Bluetooth audio devices');
        else if (type === DeviceTypeGalaxyLegacy || type === DeviceTypeGalaxyBuds)
            label = _('Samsung Galaxy Bluetooth audio devices');
        else if (type === DeviceTypeNothingBuds)
            label = _('Nothing / CMF Bluetooth audio devices');
        else if (type === DeviceTypeGoogleBuds)
            label = _('Google Pixel Buds Bluetooth audio devices');
        else if (type === DeviceTypeRedmiBuds)
            label = _('Redmi / Xiaomi Bluetooth audio devices');
        else if (type === DeviceTypeSenhBuds)
            label = _('Sennheiser Bluetooth audio devices');
        else if (type === DeviceTypeBoseBuds)
            label = _('Bose Bluetooth audio devices');
        else if (type === DeviceTypeGfps)
            label = _('Google Fast Pair Bluetooth audio devices');
        else
            label = type;

        if (this._notification)
            this._notification.destroy(MessageTray.NotificationDestroyedReason.SOURCE_CLOSED);
        this._notification = null;

        if (!this._source) {
            this._source = new MessageTray.Source({
                title: _('Bluetooth Battery Meter'),
                icon: this.toggle.gIcon('bbm-logo-symbolic.svg'),
            });
        }

        this._source.connectObject('destroy', () => {
            this._source = null;
        }, this._source);

        Main.messageTray.add(this._source);

        const title = _('Could not access advanced features for %s.').format(label);
        const body = _(
            'Another app or session is already using the Bluetooth socket/profile on %s.' +
            ' Close any other apps using this device,' +
            ' then disable and re-enable it in the extension settings.'
        ).format(label);

        this._notification = new MessageTray.Notification({
            source: this._source,
            title,
            body,
            urgency: MessageTray.Urgency.NORMAL,
        });
        this._notification.connectObject('destroy', () => {
            this._notification = null;
        }, this);

        this._source.addNotification(this._notification);
    }

    destroy() {
        if (this._notification)
            this._notification.destroy(MessageTray.NotificationDestroyedReason.SOURCE_CLOSED);
        this._notification = null;

        this._source?.destroy();
        this._source = null;
    }
}
