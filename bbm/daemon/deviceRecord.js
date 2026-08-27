'use strict';

/**
 * Creates a blank DeviceRecord — the canonical internal representation of a device.
 * The D-Bus service reads only DeviceRecords; it never touches DataHandler or protocol
 * objects directly. The orchestrator owns the lifecycle: create on handshake success,
 * update on configuration-changed / properties-changed, destroy on disconnect/removal.
 */
export function createDeviceRecord(address, alias, icon, connected, paired) {
    return {
        // Identity
        address,
        alias,
        icon,
        connected,
        paired,

        // Computed battery level (0-100), primary level for indicators
        computedLevel: 0,

        // Per-component batteries. batteries[0] = primary/left, [1] = right, [2] = case.
        batteries: [
            {level: 0, status: 'not-reported', icon: null},
            {level: 0, status: 'not-reported', icon: null},
            {level: 0, status: 'not-reported', icon: null},
        ],

        // Toggle rows (ANC, Conversation Awareness, etc.).
        // toggles[0] = toggle1, toggles[1] = toggle2.
        toggles: [
            {title: '', buttons: [], buttonIcons: [], state: 0, visible: false},
            {title: '', buttons: [], buttonIcons: [], state: 0, visible: false},
        ],

        // ANC sub-level selector (box1RadioButton / box1RadioButtonState).
        // Empty buttons[] means the device has no NC level control.
        ancLevel: {title: '', buttons: [], state: 0},

        // Which options box is currently visible (0 = none, 1 = box1 = NC levels).
        // Mirrors props.optionsBoxVisible from DataHandler.
        optionsBoxVisible: 0,
    };
}

/**
 * Updates a DeviceRecord in-place from a DataHandler's current config + props.
 * Call this whenever configuration-changed or properties-changed fires.
 */
export function updateRecordFromDataHandler(record, dataHandler) {
    const cfg = dataHandler.config;
    const props = dataHandler.props;

    record.computedLevel = props.computedBatteryLevel;

    record.batteries[0] = {
        level: props.battery1Level,
        status: props.battery1Status,
        icon: cfg.battery1Icon,
    };
    record.batteries[1] = {
        level: props.battery2Level,
        status: props.battery2Status,
        icon: cfg.battery2Icon,
    };
    record.batteries[2] = {
        level: props.battery3Level,
        status: props.battery3Status,
        icon: cfg.battery3Icon,
    };

    // Build toggle arrays from individual button fields
    for (let t = 0; t < 2; t++) {
        const n = t + 1; // 1 or 2
        const buttons = [];
        const buttonIcons = [];
        for (let b = 1; b <= 4; b++) {
            const name = cfg[`toggle${n}Button${b}Name`];
            if (name)
                buttons.push(name);
            buttonIcons.push(cfg[`toggle${n}Button${b}Icon`] ?? '');
        }
        record.toggles[t] = {
            title: cfg[`toggle${n}Title`] ?? '',
            buttons,
            buttonIcons: buttonIcons.slice(0, buttons.length),
            state: props[`toggle${n}State`],
            visible: props[`toggle${n}Visible`],
        };
    }

    record.ancLevel = {
        title: cfg.box1RadioTitle ?? '',
        buttons: Array.isArray(cfg.box1RadioButton) ? [...cfg.box1RadioButton] : [],
        state: props.box1RadioButtonState ?? 0,
    };

    record.optionsBoxVisible = props.optionsBoxVisible ?? 0;
}
