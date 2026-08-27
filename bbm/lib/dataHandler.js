'use strict';
import GObject from 'gi://GObject';

export function createConfig() {
    // Assigning batteryIcon/setButtons a name(string) enables it.
    // commonIcon: St.Drawing vector name for indicator widget in indicatorVectorImages
    //             Also for svg icon for panel button.
    //              (`bbm-${config.commonIcon}-symbolic.svg`) in folder
    //             ${extensions directory}/icons/hicolor/scalable/actions
    // battery*Icon: St.Drawing vector name for circular widget  in circularBatteryVectorImages
    // battery*ShowOnDisconnect: false: Hide the circular battery widget when disconnected
    //                           true: Shows the circular battery widget
    //                                  when disconnected with disconnect icon
    // toggle1/2Button*Icon: toggle set, accepts svg icon name located at
    //                  ${extensions directory}/icons/hicolor/scalable/actions
    //                  assign at least 2 icons to active toggle
    // toggle1/2Title: title for toggle
    //
    // panelButtonLabelFixed: Position of bat1/2 label relative to the icon
    //                        true: position bat1 : left, bat2 : right. if bat1/2 = 0 display '...'
    //                        false; if bat2 = 0, bat1 : right. else bat1 : left, bat2: right.
    // optionsBox*: accepts widget type [ 'slider' , 'check-button' , 'radio-button' ]
    //              accepts only one widget type. Cannot accept duplicates, example 2 sliders
    //              4 optionBoxes are availabe, but only 1 will be displayed.
    // box*SliderTitle: Title for slider box
    // box*CheckButton: Can have either 1 or 2 check button per box.
    //                  Elements in array will be used as titles
    //                  example to define 2 checkbutton ['title1', 'title2']
    // box*RadioButton: Can have either 2 - 4 radio button per box.
    //                  Elements in array will be used as button name
    //                  example to define 2 radio button ['button name 1', 'button name2']
    // box*RadioTitle:  Title for Radio Box
    // labelIndicatorEnabled: No of Indicators on panel, displaying info. max 3.
    // labelWidth: Adjust width depending on text (em).

    return {
        commonIcon: null,
        albumArtIcon: null,

        battery1Icon: null,
        battery2Icon: null,
        battery3Icon: null,
        battery1ShowOnDisconnect: false,
        battery2ShowOnDisconnect: false,
        battery3ShowOnDisconnect: false,

        toggle1Title: '',
        toggle1Button1Icon: null,
        toggle1Button1Name: '',
        toggle1Button2Icon: null,
        toggle1Button2Name: '',
        toggle1Button3Icon: null,
        toggle1Button3Name: '',
        toggle1Button4Icon: null,
        toggle1Button4Name: '',

        optionsBox1: [],
        optionsBox2: [],
        optionsBox3: [],
        optionsBox4: [],
        box1SliderTitle: '',
        box2SliderTitle: '',
        box3SliderTitle: '',
        box4SliderTitle: '',
        box1CheckButton: [],
        box2CheckButton: [],
        box3CheckButton: [],
        box4CheckButton: [],
        box1RadioButton: [],
        box1RadioTitle: '',
        box2RadioButton: [],
        box2RadioTitle: '',
        box3RadioButton: [],
        box3RadioTitle: '',
        box4RadioButton: [],
        box4RadioTitle: '',

        toggle2Title: '',
        toggle2Button1Icon: null,
        toggle2Button1Name: '',
        toggle2Button2Icon: null,
        toggle2Button2Name: '',
        toggle2Button3Icon: null,
        toggle2Button3Name: '',
        toggle2Button4Icon: null,
        toggle2Button4Name: '',

        labelWidth: 4,
        labelIndicatorEnabled: 0,

        panelButtonLabelFixed: true,
        showSettingsButton: false,
    };
}

export function createProperties() {
    // computedBatteryLevel: accepted value 0 - 100. Computed value for indicator and popupmenu
    // battery*Level: accepted value 0 - 100. displays level on circular widget
    // battery*Status: accepted value : 'charging', 'discharging', 'disconnected'
    // toggle*State: accepted value: 0 - 3
    //               0: no buttons active,
    //               1: button1 is active, other inactive
    //               2: button2 is active, other inactive
    //               3: button3 is active, other inactive
    //               4: button3 is active, other inactive
    // toggle1Visible: accepted value: boolean
    // toggle2Visible: accepted value: boolean
    // optionsBoxVisible: accepted value: 0 - 4
    //                  Current Box visible. 0 = all hidden , (1 - 4) displays optionBox(1 - 4)
    // box*SliderValue: accepted value: 0 - 100. Write the value to change slider position.
    // box*CheckButton*State: accepted value : 0 - 1.  0 - false 1 - true
    // box*RadioButtonState: accepted value 0 - 3. 0 Non selected, 1 - 3  button selected
    return {
        computedBatteryLevel: 0,
        battery1Level: 0,
        battery2Level: 0,
        battery3Level: 0,
        battery1Status: 'not-reported',
        battery2Status: 'not-reported',
        battery3Status: 'not-reported',

        toggle1State: 0,
        toggle1Visible: false,

        optionsBoxVisible: 0,
        box1SliderValue: 0,
        box2SliderValue: 0,
        box3SliderValue: 0,
        box4SliderValue: 0,
        box1CheckButton1State: 0,
        box1CheckButton2State: 0,
        box2CheckButton1State: 0,
        box2CheckButton2State: 0,
        box3CheckButton1State: 0,
        box3CheckButton2State: 0,
        box4CheckButton1State: 0,
        box4CheckButton2State: 0,
        box1RadioButtonState: 0,
        box2RadioButtonState: 0,
        box3RadioButtonState: 0,
        box4RadioButtonState: 0,

        labelIndicator1: '',
        labelIndicator2: '',
        labelIndicator3: '',

        toggle2State: 0,
        toggle2Visible: false,

    };
}

// 'ui-action': emitted when user change state or toggle button, or move slider
// Signal: 'ui-action', widgetId(string), value(int)
// toggle*State: toggleButton activate, value = Button index
// box*SliderValue: slider position changed, value = Slider position
// box*SliderIsDragging: slider, isDragging, value = 0(fasle) 1(true)
// box*CheckButton*State: check button state changed, value = 0(fasle) 1(true)
// box*RadioButtonState: Radio button activated, value = button index
// settingsButtonClicked: Setting button clicked

export const DataHandler = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_DataHandler',
    Signals: {
        'configuration-changed': {},
        'properties-changed': {},
        'ui-action': {param_types: [GObject.TYPE_STRING, GObject.TYPE_INT]},
    },
}, class DataHandler extends GObject.Object {
    constructor(config, props) {
        super();
        this.config = config;
        this.props = props;
    }

    getConfig() {
        return this.config;
    }

    setConfig(config) {
        this.config = config;
        this.emit('configuration-changed');
    }


    setProps(prop) {
        this.props = prop;
        this.emit('properties-changed');
    }

    getProps() {
        return this.props;
    }

    emitUIAction(actionName, value) {
        this.emit('ui-action', actionName, value);
    }
});
