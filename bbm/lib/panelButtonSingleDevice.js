'use strict';
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import {PanelPopupMenu} from './widgets/panelPopupMenu.js';

export const PanelButtonSingleDevice = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_PanelButtonSingleDevice',
}, class PanelButtonSingleDevice extends PanelMenu.Button {
    constructor(settings, gIcon, widgetInfo) {
        super(0.5, _('Bluetooth Battery Meter'));
        this._settings = settings;
        this._gIcon = gIcon;
        this._widgetInfo = widgetInfo;
        this._deviceMap = new Map();
        this._lastSelectedPath = '';
        this.visible = false;
        this._indicatorBox = new St.BoxLayout();
        this._defaultPath = settings.get_string('default-selected-path');

        this.add_child(this._indicatorBox);
        this._battInfoMenu = new PopupMenu.PopupMenuItem(_('Bluetooth Battery Meter'),
            {reactive: false, can_focus: false,  style_class: 'bbm-panel-title-label'});
        this._battInfoMenu.label.x_expand = true;
        this.menu.addMenuItem(this._battInfoMenu);
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        this._settings.connectObject(
            'changed::default-selected-path', () => {
                this._defaultPath = this._settings.get_string('default-selected-path');
                this._updateGUI(this._defaultPath);
            },
            this
        );
        this._setupWidgets();

        this.connectObject('destroy', () => this._deviceMap.clear(), this);
    }

    _setupWidgets() {
        this._leftLabel = new St.Label({
            text: '...',
            y_align: Clutter.ActorAlign.CENTER,
            style_class: 'power-status',
        });
        this._mulitpleIcon = new St.Icon({
            style_class: 'system-status-icon',
        });
        this._rightLabel = new St.Label({
            text: '...',
            y_align: Clutter.ActorAlign.CENTER,
            style_class: 'power-status',
        });
        this._indicatorBox.add_child(this._leftLabel);
        this._indicatorBox.add_child(this._mulitpleIcon);
        this._indicatorBox.add_child(this._rightLabel);
    }

    addDevice(path, alias, dataHandler) {
        let item = null;
        if (this._deviceMap.has(path))
            return item;

        item =  new PanelPopupMenu(this._settings, this._gIcon, path, alias,
            this._widgetInfo, dataHandler, this.menu, true);
        this.menu.addMenuItem(item);
        this._deviceMap.set(path, {item, dataHandler});
        this._updateGUI(path);
        this.visible = this._deviceMap.size > 0;
        return item;
    }

    removeDevice(path) {
        if (this._deviceMap.has(path)) {
            const deviceProps = this._deviceMap.get(path);
            if (this._dataHandler === deviceProps.dataHandler)
                this._dataHandler.disconnectObject(this);

            deviceProps.item.destroy();
            deviceProps.item = null;
            this._deviceMap.delete(path);
        }

        if (this._deviceMap.size > 0) {
            const randomPath = this._deviceMap.keys().next().value;
            this._updateGUI(randomPath);
            this.visible = true;
        } else {
            this.visible = false;
        }
    }

    _updateWidgets(config, props) {
        const battery1Level = props.battery1Level === 0 ? '...' : `${props.battery1Level}%`;
        const battery2Level = props.battery2Level === 0 ? '...' : `${props.battery2Level}%`;

        let showLeft = false;

        if (config.battery1Icon && config.battery2Icon) {
            showLeft = config.panelButtonLabelFixed || props.battery2Level > 0;
            if (showLeft)
                this._leftLabel.text = battery1Level;
            else
                this._rightLabel.text = battery1Level;
        } else if (config.battery1Icon && !config.battery2Icon) {
            this._rightLabel.text = battery1Level;
        }

        this._leftLabel.visible = showLeft;
        if (showLeft)
            this._rightLabel.text = battery2Level;

        this._mulitpleIcon.gicon = this._gIcon(`bbm-${config.commonIcon}-symbolic.svg`);
    }

    _updateGUI(path) {
        if (this._deviceMap.has(this._defaultPath))
            this._lastSelectedPath = this._defaultPath;
        else
            this._lastSelectedPath = '';

        if (this._lastSelectedPath === '' && this._deviceMap.has(path))
            this._lastSelectedPath = path;

        if (this._deviceMap.has(this._lastSelectedPath)) {
            const dataHandler = this._deviceMap.get(this._lastSelectedPath).dataHandler;
            if (this._dataHandler !== dataHandler) {
                this._dataHandler?.disconnectObject(this);
                this._dataHandler = dataHandler;
                const config = this._dataHandler.getConfig();
                const props = this._dataHandler.getProps();
                this._updateWidgets(config, props);
                for (const {item} of this._deviceMap.values())
                    item?.updatePinButton();

                this._dataHandler.connectObject(
                    'configuration-changed', () => {
                        this._updateWidgets(
                            this._dataHandler.getConfig(), this._dataHandler.getProps());
                    },
                    'properties-changed', () => {
                        this._updateWidgets(
                            this._dataHandler.getConfig(), this._dataHandler.getProps());
                    },
                    this
                );
            }
        }
    }
});

