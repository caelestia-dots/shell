'use strict';
const {GObject, St, Clutter} = imports.gi;
import {colorToRgba, invertColor} from './colorHelpers.js';

export const LabelIndicators = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_LabelIndicators',
}, class LabelIndicators extends St.BoxLayout {
    _init(colorInfo, dataHandler) {
        super._init({
            style_class: 'bbm-label-indicator-box', x_expand: true,
            x_align: Clutter.ActorAlign.CENTER,
        });

        this._dataHandler = dataHandler;
        const config = dataHandler.getConfig();
        const props = dataHandler.getProps();
        const count = config.labelIndicatorEnabled;
        const widthEm = config.labelWidth ?? 7;
        this._bins = [];

        const invertedColor = invertColor(colorInfo.foregroundColor);

        const createLabelBin = text => {
            const bin = new St.Bin({
                style_class: 'bbm-label-indicator-bin',
                x_expand: false,
                y_expand: true,
                style: `background-color: ${colorToRgba(colorInfo.foregroundColor)
                }; width: ${widthEm}em;`,
            });

            const label = new St.Label({
                style_class: 'bbm-label-indicator-label',
                x_expand: true,
                y_expand: true,
                x_align: Clutter.ActorAlign.CENTER,
                y_align: Clutter.ActorAlign.CENTER,
                style: `color: ${colorToRgba(invertedColor)};`,
            });

            bin.set_child(label);
            bin._label = label;

            if (text && text.length > 0) {
                label.set_text(text);
                bin.show();
            } else {
                bin.hide();
            }

            this.add_child(bin);
            return bin;
        };

        if (count >= 1)
            this._bins.push(createLabelBin(props.labelIndicator1));
        if (count >= 2)
            this._bins.push(createLabelBin(props.labelIndicator2));
        if (count >= 3)
            this._bins.push(createLabelBin(props.labelIndicator3));

        this._updateBoxVisibility();

        this._dataHandler.connectObject('properties-changed', () => this._updateLabels(), this);
    }

    _updateLabels() {
        const props = this._dataHandler.getProps();
        const labels = [
            props.labelIndicator1,
            props.labelIndicator2,
            props.labelIndicator3,
        ];

        for (let i = 0; i < this._bins.length; i++) {
            const bin = this._bins[i];
            const text = labels[i];
            if (text && text.length > 0) {
                bin._label.set_text(text);
                bin.show();
            } else {
                bin.hide();
            }
        }

        this._updateBoxVisibility();
    }

    _updateBoxVisibility() {
        const anyVisible = this._bins.some(b => b.visible);
        if (anyVisible)
            this.show();
        else
            this.hide();
    }
});

