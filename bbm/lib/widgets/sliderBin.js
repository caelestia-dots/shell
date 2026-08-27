'use strict';
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Config from 'resource:///org/gnome/shell/misc/config.js';
import {Slider} from 'resource:///org/gnome/shell/ui/slider.js';

import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

const [major] = Config.PACKAGE_VERSION.split('.');
const shellVersion = Number.parseInt(major);
const boxLayoutProps = shellVersion >= 48
    ? {orientation: Clutter.Orientation.VERTICAL} : {vertical: true};

export const SliderBin = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_SliderBin',
}, class SliderBin extends St.BoxLayout {
    _init(gIcon, dataHandler, id) {
        super._init({
            style_class: 'bbm-box',
            ...boxLayoutProps, x_expand: true,
        });

        const config = dataHandler.getConfig();

        const sliderLabel = new St.Label({
            x_expand: true,
            style_class: 'bbm-subtitle-label',
            x_align: Clutter.ActorAlign.CENTER,
        });
        const title = config[`box${id}SliderTitle`];
        if (!title)
            console.log(`Bluetooth-Battery-Meter: Title for Slider in option-box${id} not defined`);

        sliderLabel.text = title;
        this.add_child(sliderLabel);

        const pluslabel = new St.Label({style: 'padding: 4px', x_align: Clutter.ActorAlign.END});
        pluslabel.text = '+';
        const minuslabel = new St.Label({style: 'padding: 4px', x_align: Clutter.ActorAlign.START});
        minuslabel.text = '-';

        const slider = new Slider(0);
        const sliderBin = new St.Bin({
            child: slider,
            reactive: true,
            can_focus: true,
            x_expand: true,
            y_align: Clutter.ActorAlign.CENTER,
            style_class: 'slider-bin',

        });

        const hbox = new St.BoxLayout({style_class: 'quick-slider'});
        hbox.add_child(minuslabel);
        hbox.add_child(sliderBin);
        hbox.add_child(pluslabel);
        this.add_child(hbox);

        const sliderAccessible = slider.get_accessible();
        sliderAccessible.set_parent(sliderBin.get_parent().get_accessible());
        sliderBin.set_accessible(sliderAccessible);
        sliderBin.connectObject('event', (bin, event) => slider.event(event, false), this);
        slider.accessible_name = sliderLabel.text;

        slider.value = dataHandler.props[`box${id}SliderValue`] / 100;

        slider.connectObject(
            'notify::value', () => {
                dataHandler.emitUIAction(`box${id}SliderValue`, slider.value * 100);
            },
            'drag-begin', () => {
                dataHandler.emitUIAction(`box${id}SliderIsDragging`, 1);
            },
            'drag-end', () => {
                dataHandler.emitUIAction(`box${id}SliderIsDragging`, 0);
            },
            this
        );

        dataHandler.connectObject('properties-changed', () => {
            slider.value = dataHandler.props[`box${id}SliderValue`] / 100;
        }, this);
    }
});

