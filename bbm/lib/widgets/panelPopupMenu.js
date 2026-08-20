'use strict';
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Config from 'resource:///org/gnome/shell/misc/config.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import {PopupMenuWidgetBox} from './popupMenuWidget.js';

const [major] = Config.PACKAGE_VERSION.split('.');
const shellVersion = Number.parseInt(major);
const boxLayoutProps = shellVersion >= 48
    ? {orientation: Clutter.Orientation.VERTICAL} : {vertical: true};

export const PanelPopupMenu = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_PanelPopupMenu',
}, class PanelPopupMenu extends PopupMenu.PopupBaseMenuItem {
    _init(settings, gIcon, path, alias, widgetInfo, dataHandler, menu, showPinButton) {
        super._init();
        this._settings = settings;
        this._gIcon = gIcon;
        this._path = path;
        this._alias = alias;
        this._widgetInfo = widgetInfo;
        this._dataHandler = dataHandler;
        this._showPinButton = showPinButton;
        this._menu = menu || null;
        this._isOpen = false;
        this.add_style_class_name('bbm-submenu bbm-panel-popupmenuitem');

        const themeNode = this.peek_theme_node();
        if (themeNode === null) {
            this.connectObject('style-changed', () => {
                const isStaged = this.get_stage();
                if (isStaged) {
                    this.disconnectObject(this);
                    this._finalizeWidget(this.peek_theme_node());
                }
            }, this);
        } else {
            this._finalizeWidget(themeNode);
        }
    }

    _finalizeWidget(themeNode) {
        const colorInfo = {
            isDarkMode: this._widgetInfo.isDarkMode,
            accentColor: this._widgetInfo.accentColor,
            foregroundColor: themeNode.get_foreground_color(),
        };

        this._vBox = new St.BoxLayout({...boxLayoutProps, x_expand: true});
        this.add_child(this._vBox);

        this._hBox = new St.BoxLayout({x_expand: true});
        this._vBox.add_child(this._hBox);

        this._icon = new St.Icon({
            style_class: 'popup-menu-icon bbm-panel-icon',
            gicon: this._gIcon(`bbm-${this._dataHandler.getConfig().commonIcon}-symbolic.svg`),
        });
        this._hBox.add_child(this._icon);

        this._label = new St.Label({
            text: this._alias, style_class: 'bbm-bt-widget',
            y_align: Clutter.ActorAlign.CENTER,
        });
        this._hBox.add_child(this._label);

        const expander = new St.Bin({x_expand: true, style: 'min-width: 18px'});
        this._hBox.add_child(expander);

        this._triangle =
             new St.Icon({icon_name: 'pan-down-symbolic', style_class: 'bbm-panel-expand-icon'});

        this._hBox.add_child(this._triangle);

        const headerButtons = {pin: this._showPinButton, btPair: false, collapse: true};

        this._popupItemBox = new PopupMenuWidgetBox(this._settings, this._gIcon, this._path,
            this._alias, this._widgetInfo, colorInfo, headerButtons, this._dataHandler);

        this._popupItemBox.visible = false;
        this._vBox.add_child(this._popupItemBox);

        this._updateAccesibleName();

        if (this._menu) {
            this._menu.connectObject('open-state-changed', (o, isOpen) => {
                if (!isOpen && this._menu._bbmOpenSubmenu) {
                    this._menu._bbmOpenSubmenu._toggleSubMenuBox(false, false, false);
                    this._menu._bbmOpenSubmenu = null;
                }
            }, this);
        }

        this._popupItemBox.collapseButton.connectObject('clicked', () => {
            if (this._isOpen)
                this._toggleSubMenuBox(false, true, true);
        }, this._popupItemBox);

        this.activate = __ => {
            if (!this._isOpen)
                this._toggleSubMenuBox(true, true, false);
        };

        this.connectObject(
            'enter-event', () => {
                this.add_style_pseudo_class('focus');
            },
            'leave-event', () => {
                this.remove_style_pseudo_class('focus');
            },
            this
        );
    }

    updatePinButton() {
        this._popupItemBox?.updatePinButton();
    }

    updateAlias(alias) {
        this._alias = alias;
        this._popupItemBox?.updateAlias?.(alias);
        this._updateAccesibleName();
    }

    _updateAccesibleName() {
        this.accessible_name = `${this._alias} ${_('Expand submenu')}`;
    }

    vfunc_key_press_event(event) {
        const symbol = event.get_key_symbol();
        if (symbol  === Clutter.KEY_space && !this._isOpen) {
            this._toggleSubMenuBox(true, true, true);
            return Clutter.EVENT_STOP;
        } else if (symbol === Clutter.KEY_space &&
                        this._popupItemBox.collapseButton.has_key_focus() && this._isOpen) {
            this._toggleSubMenuBox(false, true, true);
            return Clutter.EVENT_STOP;
        }
        return Clutter.EVENT_PROPAGATE;
    }

    _toggleSubMenuBox(open, animate, keyGrabCall, doneCallback = null) {
        if (open) {
            const openNow = () => {
                this.active = true;
                this.grab_key_focus();
                this.add_style_class_name('open');
                this._hBox.hide();
                this._popupItemBox.opacity = 0;
                this._popupItemBox.visible = true;
                const [, naturalHeight] = this._popupItemBox.get_preferred_height(-1);
                this._popupItemBox.height = 0;
                const duration = animate ? 200 : 0;
                this.set_can_focus(false);

                this._popupItemBox.ease({
                    height: naturalHeight,
                    opacity: 255,
                    duration,
                    mode: Clutter.AnimationMode.EASE_OUT_QUAD,
                    onComplete: () => {
                        this._popupItemBox.set_height(-1);
                        if (keyGrabCall)
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
        this.remove_style_class_name('open');

        const duration = animate ? 100 : 0;
        this._hBox.show();

        this._popupItemBox.ease({
            height: 0,
            opacity: 0,
            duration,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            onComplete: () => {
                this._popupItemBox.visible = false;
                this._popupItemBox.set_height(-1);
                this._isOpen = false;
                this.set_can_focus(true);
                if (keyGrabCall)
                    this.grab_key_focus();
                if (this._menu && this._menu._bbmOpenSubmenu === this)
                    this._menu._bbmOpenSubmenu = null;
                if (doneCallback)
                    doneCallback();
            },
        });
    }
});

