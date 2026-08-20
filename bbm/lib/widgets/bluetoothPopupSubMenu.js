'use strict';
import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Config from 'resource:///org/gnome/shell/misc/config.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import {PopupMenuWidgetBox} from './popupMenuWidget.js';
import {Tooltip} from './tooltip.js';

const [major] = Config.PACKAGE_VERSION.split('.');
const shellVersion = Number.parseInt(major);
const boxLayoutProps = shellVersion >= 48
    ? {orientation: Clutter.Orientation.VERTICAL} : {vertical: true};

export const BluetoothPopupSubMenuItem = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_BluetoothPopupSubMenuItem',
}, class BluetoothPopupSubMenuItem extends PopupMenu.PopupBaseMenuItem {
    _init(manager) {
        super._init({style_class: 'bt-device-item bbm-submenu', can_focus: false});
        this._manager = manager;
        this._toggle = manager.toggle;
        this._settings = manager.settings;
        this._client = this._toggle._bluetoothToggle._client;
        this._gIcon = manager.gIcon;
        this._connectedColor = this._toggle.connectedColor;
        this._disconnectedColor = null;
        this._device = manager.device;
        this._iconType = manager.deviceIcon;
        this._widgetInfo = manager.widgetInfo;
        this._qsLevelEnabled = manager.qsLevelEnabled;
        this._dataHandler = null;

        this._menu = this._toggle._bluetoothToggle._deviceSection || null;
        this._isOpen = false;

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
        const fgColor = themeNode.get_foreground_color();
        this._colorInfo = {
            accentColor: this._widgetInfo.accentColor,
            foregroundColor: fgColor,
        };

        this._disconnectedColor = fgColor;

        const showTooltips = this._settings.get_boolean('enable-tooltip');
        if (showTooltips)
            this._tooltip = new Tooltip(this);

        this._vBox = new St.BoxLayout({...boxLayoutProps, x_expand: true});
        this.add_child(this._vBox);

        this._hBox = new St.BoxLayout({x_expand: true});
        this._vBox.add_child(this._hBox);

        this._icon = new St.Icon({style_class: 'popup-menu-icon'});

        this._icon.set_gicon(this._gIcon(`bbm-${this._iconType}-symbolic.svg`));
        this._hBox.add_child(this._icon);

        this._label = new St.Label({
            style_class: 'bbm-bt-widget',
            y_align: Clutter.ActorAlign.CENTER,
        });
        this._hBox.add_child(this._label);

        const expander = new St.Bin({style_class: 'popup-menu-item-expander', x_expand: true});
        this._hBox.add_child(expander);

        this._triangle =
                new St.Icon({icon_name: 'pan-down-symbolic', style_class: 'bbm-header-icon'});

        this._triangleButton = new St.Button({
            style_class: 'button bbm-header-button',
            can_focus: true, y_align: Clutter.ActorAlign.CENTER, child: this._triangle,
        });
        this._updateTriangleButtonAccesibleName();

        this._triangleBin = new St.Bin({
            style_class: 'bbm-header-bin',
            y_align: Clutter.ActorAlign.CENTER, child: this._triangleButton,
        });

        this._triangleBin.visible = false;
        this._hBox.add_child(this._triangleBin);

        this._pairIcon = new St.Icon({style_class: 'bbm-header-icon'});
        this._pairButton = new St.Button({
            style_class: 'button bbm-header-button',
            can_focus: true, y_align: Clutter.ActorAlign.CENTER, child: this._pairIcon,
        });
        this._updatePairButtonAccesibleName();

        const pairBin = new St.Bin({
            style_class: 'bbm-header-bin',
            y_align: Clutter.ActorAlign.CENTER, child: this._pairButton,
        });

        this._hBox.add_child(pairBin);

        this._device.bind_property('connectable',
            this, 'visible',
            GObject.BindingFlags.SYNC_CREATE);

        this._device.bind_property('alias',
            this._label, 'text',
            GObject.BindingFlags.SYNC_CREATE);

        this._assignPairingIcon(false);

        if (this._manager._dataHandler)
            this.setDataHandler(this._manager._dataHandler);

        this.activate = __ => {};

        this._triangleButton.connectObject('clicked', () => {
            const expandFocused = this._triangleButton.has_key_focus();
            const nextFocus = expandFocused ? this._popupItemBox.collapseButton : null;
            this._toggleSubMenuBox(true, true, nextFocus);
        }, this);

        this._pairButton.connectObject('clicked', () => {
            if (this._device.connected && this._isOpen)
                this._toggleSubMenuBox(false, true, null);

            this._toggleConnected().catch(logError);
        }, this);

        if (this._menu) {
            this._menu.connectObject('open-state-changed', (o, isOpen) => {
                if (!isOpen && this._menu._bbmOpenSubmenu) {
                    this._menu._bbmOpenSubmenu._toggleSubMenuBox(false, false, null);
                    this._menu._bbmOpenSubmenu = null;
                }
            }, this);
        }

        this._device.connectObject(
            'notify::connected', () => {
                this._assignPairingIcon(false);
                if (!this._device.connected && this._dataHandler) {
                    this._toggleSubMenuBox(false, false, null);
                    this._triangleBin.visible = false;
                    this._dataHandler = null;
                    this._removePopupItemBox();
                }
                this._updatePairButtonAccesibleName();
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
            this._tooltip?.destroy();
            this._tooltip = null;
        }, this);
    }

    updateProperties(qsLevelEnabled, deviceIcon) {
        if (this._qsLevelEnabled !== qsLevelEnabled) {
            this._qsLevelEnabled = qsLevelEnabled;
            this.setDataHandler(this._dataHandler);
        }

        if (deviceIcon && this._iconType !== deviceIcon) {
            this._iconType = deviceIcon;
            if (this._icon)
                this._icon.set_gicon(this._gIcon(`bbm-${this._iconType}-symbolic.svg`));
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

            const connected = this._device.connected;
            this._iconChangeTimerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 300, () => {
                const gioIcon = connected
                    ? this._gIcon(`bbm-bluetooth-disconnecting-${this._counter}-symbolic.svg`)
                    : this._gIcon(`bbm-bluetooth-connecting-${this._counter}-symbolic.svg`);

                const style = connected ? `color: ${this._connectedColor};`
                    : `color: ${this._disconnectedColor};`;

                this._pairIcon?.set_gicon(gioIcon);
                this._pairIcon?.set_style(style);
                this._popupItemBox?.btPairButton?.icon?.set_gicon(gioIcon);
                this._popupItemBox?.btPairButton?.icon?.set_style(style);

                this._counter = this._counter <= 1 ? 4 : this._counter - 1;
                return GLib.SOURCE_CONTINUE;
            });
        } else {
            if (this._iconChangeTimerId)
                GLib.source_remove(this._iconChangeTimerId);
            this._iconChangeTimerId = null;

            const connected = this._device.connected;
            const gioIcon = connected ? this._gIcon('bbm-bluetooth-connected-symbolic.svg')
                : this._gIcon('bbm-bluetooth-disconnecting-1-symbolic.svg');

            const style = connected ? `color: ${this._connectedColor};`
                : `color: ${this._disconnectedColor};`;

            this._pairIcon?.set_gicon(gioIcon);
            this._pairIcon?.set_style(style);
            this._popupItemBox?.btPairButton?.icon?.set_gicon(gioIcon);
            this._popupItemBox?.btPairButton?.icon?.set_style(style);
        }
    }

    _addPopupItemBox(dataHandler) {
        if (this._popupItemBox)
            return;

        const headerButtons = {pin: false, btPair: true, collapse: true};
        this._popupItemBox = new PopupMenuWidgetBox(this._settings, this._gIcon,
            this._device.get_object_path(), this._device.alias, this._manager.widgetInfo,
            this._colorInfo, headerButtons, dataHandler);
        this._popupItemBox.visible = false;
        this._vBox.add_child(this._popupItemBox);

        this._popupItemBox.collapseButton.connectObject('clicked', () => {
            if (this._isOpen) {
                const expandFocused = this._popupItemBox.collapseButton.has_key_focus();
                const nextFocus = expandFocused ? this._triangleButton : null;
                this._toggleSubMenuBox(false, true, nextFocus);
            }
        }, this._popupItemBox);

        this._popupItemBox.btPairButton.connectObject('clicked', () => {
            if (this._device.connected && this._isOpen) {
                const btPairFocused = this._popupItemBox.btPairButton.has_key_focus();
                const nextFocus = btPairFocused ? this._pairButton : null;
                this._toggleSubMenuBox(false, true, nextFocus);
            }
            this._toggleConnected().catch(logError);
        }, this._popupItemBox);

        this._assignPairingIcon(false);
    }

    _removePopupItemBox() {
        this._popupItemBox?.collapseButton?.disconnectObject(this._popupItemBox);
        this._popupItemBox?.btPairButton?.disconnectObject(this._popupItemBox);
        this._popupItemBox?.destroy();
        this._popupItemBox = null;
    }

    setDataHandler(dataHandler) {
        if (!dataHandler)
            return;
        if (this._triangleButton && this._device.connected && this._qsLevelEnabled) {
            this._triangleBin.visible = true;
            this._addPopupItemBox(dataHandler);
        } else if (this._triangleButton && !this._qsLevelEnabled) {
            this._triangleBin.visible = false;
            this._removePopupItemBox();
        }
        this._dataHandler = dataHandler;
    }

    _updateTriangleButtonAccesibleName() {
        if (this._triangleButton) {
            const btnName = _('Collapse submenu');
            this._triangleButton?.set_accessible_name(`${this._device.alias} ${btnName}`);
            this._tooltip?.attach(this._triangleButton, btnName);
        }
    }

    _updatePairButtonAccesibleName() {
        if (this._pairButton) {
            const status = this._device.connected ? _('Disconnect') : _('Connect');
            this._pairButton?.set_accessible_name(`${this._device.alias} ${status}`);
            this._tooltip?.attach(this._pairButton, status);
        }
    }

    updateAlias(alias) {
        this._popupItemBox?.updateAlias?.(alias);
        this._updateTriangleButtonAccesibleName();
        this._updatePairButtonAccesibleName();
    }

    _toggleSubMenuBox(open, animate, nextGrabCall, doneCallback = null) {
        if (open) {
            const openNow = () => {
                this.active = true;
                this.add_style_class_name('open bbm-bt-open-menu');
                this._hBox.hide();
                this._popupItemBox.opacity = 0;
                this._popupItemBox.visible = true;
                const [, naturalHeight] = this._popupItemBox.get_preferred_height(-1);
                this._popupItemBox.height = 0;
                const duration = animate ? 200 : 0;
                this.set_track_hover(false);

                this._popupItemBox.ease({
                    height: naturalHeight,
                    opacity: 255,
                    duration,
                    mode: Clutter.AnimationMode.EASE_OUT_QUAD,
                    onComplete: () => {
                        this._popupItemBox.set_height(-1);
                        this.set_track_hover(true);
                        if (nextGrabCall)
                            this._popupItemBox.collapseButton.grab_key_focus();
                        if (doneCallback)
                            doneCallback();
                    },
                });

                this._isOpen = true;
                if (this._menu)
                    this._menu._bbmOpenSubmenu = this;
            };

            if (this._menu && this._menu._bbmOpenSubmenu && this._menu._bbmOpenSubmenu !== this) {
                const other = this._menu._bbmOpenSubmenu;
                other._toggleSubMenuBox(false, true, false, () => {
                    openNow();
                });
                return;
            }

            openNow();
            return;
        }

        if (!this._isOpen) {
            if (doneCallback)
                doneCallback();
            return;
        }

        this.active = false;
        this.remove_style_class_name('open bbm-bt-open-menu');

        const duration = animate ? 100 : 0;
        this._hBox.show();
        this.set_track_hover(false);

        this._popupItemBox.ease({
            height: 0,
            opacity: 0,
            duration,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            onComplete: () => {
                this._popupItemBox.visible = false;
                this._popupItemBox.set_height(-1);
                this._isOpen = false;
                if (this._menu && this._menu._bbmOpenSubmenu === this)
                    this._menu._bbmOpenSubmenu = null;
                this.set_track_hover(true);
                if (nextGrabCall)
                    nextGrabCall.grab_key_focus();
                if (doneCallback)
                    doneCallback();
            },
        });
    }
});


