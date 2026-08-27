'use strict';
import Atk from 'gi://Atk';
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Config from 'resource:///org/gnome/shell/misc/config.js';

import {adjustColorLuminanceToRgba, colorToRgba, colorGreyOpacity} from './colorHelpers.js';

const [major] = Config.PACKAGE_VERSION.split('.');
const shellVersion = Number.parseInt(major);
const buttonMask = shellVersion >= 51 ? St.ButtonMask.PRIMARY : St.ButtonMask.ONE;
const boxLayoutProps = shellVersion >= 48
    ? {orientation: Clutter.Orientation.VERTICAL} : {vertical: true};

const RadioButton = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_RadioButton',
}, class RadioButton extends St.Bin {
    _init(gIcon, styleInfo, length, radioBtnTitle, grpTitle, initialChecked) {
        super._init({x_expand: true, style_class: 'button bbm-radiobtn-bin'});
        this._styleInfo = styleInfo;

        const box = new St.BoxLayout({
            ...boxLayoutProps, x_expand: true,
            style_class: `bbm-radio${length}btn-box`,
        });

        this.set_child(box);

        this._radioBoxLabel = new St.Label({
            style_class: 'bbm-radiobtn-label',
            x_align: Clutter.ActorAlign.FILL,
        });
        this._radioBoxLabel.text = radioBtnTitle;

        this.radioButton = new St.Button({
            style_class: 'bbm-radiobtn',
            reactive: true,
            can_focus: true,
            track_hover: true,
            button_mask: buttonMask,
            y_align: Clutter.ActorAlign.CENTER,
            x_align: Clutter.ActorAlign.CENTER,
            accessible_role: Atk.Role.RADIO_BUTTON,
            accessible_name: `${grpTitle} ${radioBtnTitle}`,
        });

        this._bin = new St.Bin({
            style_class: 'bbm-radiobtn-box',
            y_align: Clutter.ActorAlign.CENTER,
            x_align: Clutter.ActorAlign.CENTER,
        });
        this.radioButton.child = this._bin;

        this._icon = new St.Icon({
            gicon: gIcon('bbm-radio-symbolic.svg'),
            style_class: 'bbm-radiobtn-icon',
            y_align: Clutter.ActorAlign.CENTER,
            x_align: Clutter.ActorAlign.CENTER,
        });
        this._bin.set_child(this._icon);

        this.radioButton.checked = initialChecked;

        this.updateStyle();
        this.radioButton.connectObject(
            'clicked', () => {
                this.radioButton.checked = !this.radioButton.checked;
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

        box.add_child(this.radioButton);
        box.add_child(this._radioBoxLabel);
    }

    updateStyle() {
        let iconStyle = '';
        let boxStyle = '';

        if (this.radioButton.checked && this.radioButton.hover) {
            iconStyle = this._styleInfo.iconHoverCheckedStyle;
            boxStyle =
            `${this._styleInfo.borderCheckedStyle} ${
                this._styleInfo.boxHoverCheckedStyle}`;
        } else if (this.radioButton.checked) {
            iconStyle = this._styleInfo.iconCheckedStyle;
            boxStyle =
            `${this._styleInfo.borderCheckedStyle} ${
                this._styleInfo.boxCheckedStyle}`;
        } else if (this.radioButton.hover) {
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

        if (this.radioButton.has_key_focus())
            this.add_style_pseudo_class('focus');
        else
            this.remove_style_pseudo_class('focus');


        this._icon.set_style(iconStyle);
        this._bin.set_style(boxStyle);
    }
});

export const RadioButtonBin = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_RadioButtonBin',
}, class RadioButtonBin extends St.BoxLayout {
    _init(gIcon, colorInfo, dataHandler, id) {
        super._init({
            ...boxLayoutProps, x_expand: true, style_class: 'bbm-box',
            x_align: Clutter.ActorAlign.FILL,
        });
        this._gIcon = gIcon;
        this._colorInfo = colorInfo;
        this._dataHandler = dataHandler;
        this._radioButtons = [];
        const config = dataHandler.getConfig();
        const buttons = config[`box${id}RadioButton`];

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

        const title = config[`box${id}RadioTitle`];
        this._radioBoxTitleLabel = new St.Label({
            style_class: 'bbm-subtitle-label',
            x_align: Clutter.ActorAlign.FILL,
        });
        this._radioBoxTitleLabel.text = title;
        this.add_child(this._radioBoxTitleLabel);


        const hBox = new St.BoxLayout({x_align: Clutter.ActorAlign.FILL});

        buttons.forEach((label, i) => {
            const btnIndex = i + 1;
            const state = this._dataHandler.getProps()[`box${id}RadioButtonState`];
            const initialChecked = state === btnIndex;
            const btn =
                new RadioButton(gIcon, styleInfo, buttons.length, label, title, initialChecked);
            this._radioButtons.push(btn);
            hBox.add_child(btn);

            btn.radioButton.connectObject('clicked', () => {
                this._radioButtons.forEach((b, j) => {
                    b.radioButton.checked = j === i;
                });
                this._radioButtons.forEach(b => b.updateStyle());

                this._dataHandler.emitUIAction(`box${id}RadioButtonState`, btnIndex);
            }, this);
        });


        this._dataHandler.connectObject('properties-changed', () => {
            const state = this._dataHandler.getProps()[`box${id}RadioButtonState`];
            this._radioButtons.forEach((btn, idx) => {
                btn.radioButton.checked = state > 0 && idx + 1 === state;
                btn.updateStyle();
            });
        }, this);

        this.add_child(hBox);
    }
});

