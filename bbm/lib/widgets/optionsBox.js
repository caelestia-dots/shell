'use strict';
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Config from 'resource:///org/gnome/shell/misc/config.js';

import {SliderBin} from './sliderBin.js';
import {CheckButtonBin} from './checkButtonBin.js';
import {RadioButtonBin} from './radioButtonBin.js';

const [major] = Config.PACKAGE_VERSION.split('.');
const shellVersion = Number.parseInt(major);
const boxLayoutProps = shellVersion >= 48 ? {orientation: Clutter.Orientation.VERTICAL}
    : {vertical: true};

export const OptionsBox = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_OptionsBox',
}, class OptionsBox extends St.Widget {
    _init(gIcon, colorInfo, dataHandler) {
        super._init({layout_manager: new Clutter.BinLayout(), x_expand: true});

        this._dataHandler = dataHandler;
        const config = dataHandler.getConfig();

        const allOpts = [
            config.optionsBox1,
            config.optionsBox2,
            config.optionsBox3,
            config.optionsBox4,
        ];

        this._boxes = allOpts.map((opts, idx) => {
            if (!Array.isArray(opts) || opts.length === 0)
                return null;

            const container = new St.BoxLayout({...boxLayoutProps, x_expand: true});

            opts.forEach(opt => {
                let widget;

                if (opt === 'slider') {
                    widget = new SliderBin(gIcon, dataHandler, idx + 1);
                } else if (opt === 'check-button') {
                    const len = config[`box${idx + 1}CheckButton`].length;
                    if (len < 1 || len > 2) {
                        console.log('Bluetooth-Battery-Meter: bad check-button config');
                        return;
                    }
                    widget = new CheckButtonBin(gIcon, colorInfo, dataHandler, idx + 1);
                } else if (opt === 'radio-button') {
                    const len = config[`box${idx + 1}RadioButton`].length;
                    if (len < 2 || len > 4) {
                        console.log('Bluetooth-Battery-Meter: bad radio-button config');
                        return;
                    }
                    widget = new RadioButtonBin(gIcon, colorInfo, dataHandler, idx + 1);
                }

                if (widget)
                    container.add_child(widget);
            });

            this.add_child(container);
            container.visible = false;
            return container;
        });

        this._current = 0;
        this.showUI(dataHandler.props.optionsBoxVisible);

        dataHandler.connectObject('properties-changed', () => {
            this.showUI(dataHandler.props.optionsBoxVisible);
        }, this);
    }

    showUI(index) {
        if (this._current === 0 && index > 0) {
            this._showWidget(this._boxes[index - 1]);
            this._current = index;
        } else if (this._current > 0 && index !== this._current) {
            const oldWidget = this._boxes[this._current - 1];
            const newWidget = this._boxes[index - 1];
            this._hideWidget(oldWidget, newWidget);
            this._current = index;
        } else if (this._current > 0 && index === 0) {
            const oldWidget = this._boxes[this._current - 1];
            this._hideWidget(oldWidget, null);
            this._current = index;
        }
    }

    _showWidget(widget) {
        if (!widget)
            return;

        widget.visible = true;
        widget.set_pivot_point(0.5, 0.5);
        widget.opacity = 0;
        widget.scale_x = 0.8;
        widget.scale_y = 0.8;
        widget.reactive = true;

        widget.ease({
            opacity: 255,
            scale_x: 1.0,
            scale_y: 1.0,
            duration: 250,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
        });
    }

    _hideWidget(widget, nextWidget) {
        if (!widget)
            return;

        widget.set_pivot_point(0.5, 0.5);

        widget.ease({
            opacity: 255,
            scale_x: 0.8,
            scale_y: 0.8,
            duration: 50,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            onComplete: () => {
                widget.reactive = false;
                widget.opacity = 0;
                widget.scale_x = 1.0;
                widget.scale_y = 1.0;
                if (nextWidget)
                    this._showWidget(nextWidget);
                widget.visible = false;
            },
        });
    }
});

