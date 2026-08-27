'use strict';
import GObject from 'gi://GObject';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import {PanelPopupMenu} from './widgets/panelPopupMenu.js';

export const PanelButtonMultiDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_PanelButtonMultiDevice',
}, class PanelButtonMultiDevice extends PanelMenu.Button {
    constructor(settings, gIcon, widgetInfo) {
        super(0.5, _('Bluetooth Battery Meter'));
        this._settings = settings;
        this._gIcon = gIcon;
        this._widgetInfo = widgetInfo;
        this._deviceMap = new Map();
        this._lastSelectedPath = '';
        this.visible = false;
        this._battInfoMenu = new PopupMenu.PopupMenuItem(_('Bluetooth Battery Meter'),
            {reactive: false, can_focus: false,  style_class: 'bbm-panel-title-label'});
        this._battInfoMenu.label.x_expand = true;
        this.menu.addMenuItem(this._battInfoMenu);
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());


        this.connectObject('destroy', () => this._deviceMap.clear(), this);
    }

    addDevice(path, alias, dataHandler) {
        let item = null;
        if (this._deviceMap.has(path))
            return item;

        item =  new PanelPopupMenu(this._settings, this._gIcon, path, alias,
            this._widgetInfo, dataHandler, this.menu, false);
        this.menu.addMenuItem(item);
        this._deviceMap.set(path, {item, dataHandler});
        this.visible = this._deviceMap.size > 0;
        return item;
    }

    removeDevice(path) {
        if (this._deviceMap.has(path)) {
            const deviceProps = this._deviceMap.get(path);
            deviceProps.item.destroy();
            deviceProps.item = null;
            this._deviceMap.delete(path);
        }
        this.visible = this._deviceMap.size > 0;
    }
});


