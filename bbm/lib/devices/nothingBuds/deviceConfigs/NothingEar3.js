'use strict';

// Nothing Ear (2)
export default {
    modelId: 'B173',
    name: 'Nothing Ear (3)',
    pattern: /^.*Nothing Ear \(3\)$/,

    batteryLR: true,
    batteryCase: true,

    eqPreset: {
        balanced: 0x00,
        voice: 0x01,
        more_treble: 0x02,
        more_bass: 0x03,
        custom: 0x05,
        advance: 0x06,
    },

    noiseControl: {
        off: {byte: 0x05},
        transparency: {byte: 0x07},
        noiseCancellation: {
            levels: {
                low: 0x03,
                mid: 0x02,
                high: 0x01,
                adaptive: 0x04,
            },
        },
    },

    personalizeAnc: true,

    inEarDetection: true,
    lowLatencyMode: true,
    earTipTest: true,
    ring: true,
    dualConnection: true,
    dualConnectionReboot: false,
    spatialAudioSwitch: true,

    gestureOptions: {
        default: '0902010209030102090201030803010308020107160301071602010901030109010401070B',
        slots: [
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'double'},
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'triple'},
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'action-hold'},
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'double-action-hold'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'double'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'triple'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'action-hold'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'double-action-hold'},
        ],
        mapping: {
            gestureTypes: {
                'double': 0x02,
                'triple': 0x03,
                'action-hold': 0x07,
                'double-action-hold': 0x09,
            },
            actions: {
                'skip-forward': [0x09],
                'skip-back': [0x08],
                'voice-assistant': [0x0B],
                'noise-control': [0x0A, 0x14, 0x15, 0x16],
                'volume-up': [0x12],
                'volume-down': [0x13],
                'mic-on-off': [0x1D],
                'essential-space': [0x21],
                'no-action': [0x01],
            },
        },
        gestures: {
            'double': {
                type: 'press',
                actions: [
                    'skip-forward',
                    'skip-back',
                    'voice-assistant',
                ],
            },
            'triple': {
                type: 'press',
                actions: [
                    'skip-forward',
                    'skip-back',
                    'voice-assistant',
                    'no-action',
                ],
            },
            'action-hold': {
                type: 'press',
                actions: [
                    'noise-control',
                    'voice-assistant',
                    'volume-up',
                    'volume-down',
                    'mic-on-off',
                    'no-action',
                ],
            },
            'double-action-hold': {
                type: 'press',
                actions: [
                    'noise-control',
                    'voice-assistant',
                    'volume-up',
                    'volume-down',
                    'no-action',
                ],
            },
        },
        noiseControlModes: ['off', 'transparency', 'noise-cancellation'],
    },

    albumArtIcon: 'earbuds-stem',
    budsIcon: 'earbuds-stem',
    case: 'case-square',
};

