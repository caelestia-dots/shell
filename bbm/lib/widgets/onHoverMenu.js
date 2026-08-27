'use strict';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import {PopupMenuWidget} from './popupMenuWidget.js';

export const OnHoverMenu = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_OnHoverMenu',
}, class OnHoverMenu extends GObject.Object {
    _init(box, settings, gIcon, path, alias, widgetInfo, dataHandler) {
        super._init();
        this._box = box;
        this._menu = new PopupMenu.PopupMenu(this._box, 0.0, St.Side.BOTTOM, 0);
        Main.uiGroup.add_child(this._menu.actor);
        this._menuManager = new PopupMenu.PopupMenuManager(this._box);
        this._menuManager.addMenu(this._menu);
        this._menu.actor.hide();
        this._popupItem =  new PopupMenuWidget(
            settings, gIcon, path, alias, widgetInfo, dataHandler);
        this._menu.addMenuItem(this._popupItem);
        this._delayValue = settings.get_int('on-hover-delay');
        settings.connectObject(
            'changed::on-hover-delay', () => {
                this._delayValue = settings.get_int('on-hover-delay');
            },
            this
        );

        this._hoverTimeoutId = null;
        this._enterId = null;
        this._leaveId = null;

        this._connectHoverSignals();

        this._menu.connectObject(
            'open-state-changed', (menu, open) => {
                if (!open)
                    this._connectHoverSignals();
            },
            this
        );
    }

    _connectHoverSignals() {
        if (!this._enterId)
            this._enterId = this._box.connect('enter-event', this._onEnter.bind(this));

        if (!this._leaveId)
            this._leaveId = this._box.connect('leave-event', this._onLeave.bind(this));
    }

    _disconnectHoverSignals() {
        if (this._enterId) {
            this._box.disconnect(this._enterId);
            this._enterId = null;
        }
        if (this._leaveId) {
            this._box.disconnect(this._leaveId);
            this._leaveId = null;
        }
    }

    _onEnter() {
        if (this._hoverTimeoutId || this._menu.isOpen)
            return;

        this._hoverTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, this._delayValue, () => {
            this._menu.open();
            this._disconnectHoverSignals();
            this._hoverTimeoutId = null;
            return GLib.SOURCE_REMOVE;
        });
    }

    _onLeave() {
        if (this._hoverTimeoutId) {
            GLib.source_remove(this._hoverTimeoutId);
            this._hoverTimeoutId = null;
        }
    }

    updateAlias(alias) {
        this._popupItem?.updateAlias(alias);
    }

    destroy() {
        if (this._hoverTimeoutId) {
            GLib.source_remove(this._hoverTimeoutId);
            this._hoverTimeoutId = null;
        }
        this._disconnectHoverSignals();

        if (this._menuManager && this._menu)
            this._menuManager.removeMenu(this._menu);

        if (this._menu.actor) {
            Main.uiGroup.remove_child(this._menu.actor);
            this._menu.destroy();
        }
        this._menuManager = null;
        this._menu = null;
    }
});


