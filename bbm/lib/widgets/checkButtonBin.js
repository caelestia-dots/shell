'use strict';
import Atk from 'gi://Atk';
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Config from 'resource:///org/gnome/shell/misc/config.js';

import {adjustColorLuminanceToRgba, colorToRgba, colorGreyOpacity} from './colorHelpers.js';

import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

const [major] = Config.PACKAGE_VERSION.split('.');
const shellVersion = Number.parseInt(major);
const buttonMask = shellVersion >= 51 ? St.ButtonMask.PRIMARY : St.ButtonMask.ONE;
const boxLayoutProps = shellVersion >= 48
    ? {orientation: Clutter.Orientation.VERTICAL} : {vertical: true};

const CheckButton = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_CheckButton',
}, class CheckButton extends St.BoxLayout {
    _init(gIcon, styleInfo, checkBtnTitle, initialChecked) {
        super._init({...boxLayoutProps, x_expand: true});

        this._gIcon = gIcon;
        this._styleInfo = styleInfo;

        this._checkBoxLabel = new St.Label({
            style_class: 'bbm-subtitle-label',
            x_align: Clutter.ActorAlign.FILL,
            y_align: Clutter.ActorAlign.CENTER,
            x_expand: true,
        });
        this._checkBoxLabel.text = checkBtnTitle;
        this.add_child(this._checkBoxLabel);

        this._focusBin = new St.Bin({
            x_expand: true,
            style_class: 'button bbm-checkbtn-bin',
        });
        this.add_child(this._focusBin);

        this.checkButton = new St.Button({
            style_class: 'bbm-checkbtn',
            reactive: true,
            can_focus: true,
            track_hover: true,
            button_mask: buttonMask,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER,
            accessible_role: Atk.Role.CHECK_BOX,
            accessible_name: checkBtnTitle,
        });

        this._bin = new St.Bin({
            style_class: 'bbm-checkbtn-box',
            y_align: Clutter.ActorAlign.CENTER,
            x_align: Clutter.ActorAlign.CENTER,
        });
        this.checkButton.child = this._bin;

        this._icon = new St.Icon({
            gicon: this._gIcon('bbm-check-symbolic.svg'),
            style_class: 'bbm-checkbtn-icon',
            y_align: Clutter.ActorAlign.CENTER,
            x_align: Clutter.ActorAlign.CENTER,
        });
        this._bin.set_child(this._icon);

        this.checkButton.checked = initialChecked;

        this.updateStyle();
        this.checkButton.connectObject(
            'clicked', () => {
                this.checkButton.checked = !this.checkButton.checked;

                this.updateStyle();
            },
            'notify::hover', () => {
                this.updateStyle();
            },
            'key-focus-in', () => {
                this.updateStyle();
            },
            'key-focus-out', () => {
                this.updateStyle();
            },
            this
        );

        this._focusBin.set_child(this.checkButton);
    }

    updateStyle() {
        let iconStyle = '';
        let boxStyle = '';

        if (this.checkButton.checked && this.checkButton.hover) {
            iconStyle = this._styleInfo.iconHoverCheckedStyle;
            boxStyle =
            `${this._styleInfo.borderHoverStyle} ${
                this._styleInfo.boxHoverCheckedStyle}`;
        } else if (this.checkButton.checked) {
            iconStyle = this._styleInfo.iconCheckedStyle;
            boxStyle =
            `${this._styleInfo.borderCheckedStyle} ${
                this._styleInfo.boxCheckedStyle}`;
        } else if (this.checkButton.hover) {
            iconStyle = this._styleInfo.iconStyle;
            boxStyle =
            `${this._styleInfo.borderHoverStyle} ${
                this._styleInfo.boxStyle}`;
        } else {
            iconStyle = this._styleInfo.iconStyle;
            boxStyle =
            `${this._styleInfo.borderStyle} ${
                this._styleInfo.boxStyle}`;
        }

        if (this.checkButton.has_key_focus())
            this._focusBin.add_style_pseudo_class('focus');
        else
            this._focusBin.remove_style_pseudo_class('focus');


        this._icon.set_style(iconStyle);
        this._bin.set_style(boxStyle);
    }
});

export const CheckButtonBin = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_CheckButtonBin',
}, class CheckButtonBin extends St.BoxLayout {
    _init(gIcon, colorInfo, dataHandler, id) {
        super._init({
            x_expand: true, style_class: 'bbm-box-checkbtn',
        });

        const accentColor = colorInfo.accentColor;
        const accentRgba = colorToRgba(accentColor);
        const fgColor = colorInfo.foregroundColor;
        const fgRgba = colorToRgba(fgColor);

        const hoverAccentColor = adjustColorLuminanceToRgba(accentColor, 5);
        const hoverAccentFgColor = adjustColorLuminanceToRgba(fgColor, 5);

        const borderStyle = `border: 2px solid ${colorGreyOpacity(0.50)};`;
        const borderHoverStyle = `border: 2px solid ${colorGreyOpacity(0.70)};`;
        const borderCheckedStyle = 'border: 2px solid transparent;';

        const boxStyle = 'background-color: transparent;';
        const boxCheckedStyle = `background-color: ${accentRgba};`;
        const boxHoverCheckedStyle = `background-color: ${hoverAccentColor};`;

        const iconStyle = 'color: transparent;';
        const iconCheckedStyle = `color: ${fgRgba};`;
        const iconHoverCheckedStyle = `color: ${hoverAccentFgColor};`;

        const styleInfo = {
            borderStyle, borderHoverStyle, borderCheckedStyle,
            boxStyle, boxCheckedStyle, boxHoverCheckedStyle,
            iconStyle, iconCheckedStyle, iconHoverCheckedStyle,
        };

        const vBox = new St.BoxLayout({
            ...boxLayoutProps, x_expand: true,
            x_align: Clutter.ActorAlign.FILL,
        });
        this.add_child(vBox);

        const checkLabels = dataHandler.config[`box${id}CheckButton`];
        this._buttons = [];

        checkLabels.forEach((label, i) => {
            const btnIndex = i + 1;
            const state = dataHandler.getProps()[`box${id}CheckButton${btnIndex}State`];
            const btn = new CheckButton(gIcon, styleInfo, label, state > 0);
            vBox.add_child(btn);
            this._buttons.push(btn);

            btn.checkButton.connectObject('clicked', () => {
                const checked = btn.checkButton.checked ? 1 : 0;
                dataHandler.emitUIAction(`box${id}CheckButton${btnIndex}State`, checked);
            }, this);
        });

        dataHandler.connectObject('properties-changed', () => {
            this._buttons.forEach((btn, idx) => {
                const state = dataHandler.getProps()[`box${id}CheckButton${idx + 1}State`];
                btn.checkButton.checked = state > 0;
                btn.updateStyle();
            });
        }, this);
    }
});
