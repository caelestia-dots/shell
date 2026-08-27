'use strict';

export default {
    modelId: 'B181',
    name: 'Nothing ear (1)',
    pattern: /^.*Nothing ear \(1\)$/,

    noUTCTimeUpdate: true,

    batteryLR: true,
    batteryCase: true,

    eqPreset: {
        balanced: 0x00,
        voice: 0x01,
        more_treble: 0x02,
        more_bass: 0x03,
    },


    noiseControl: {
        off: {byte: 0x05},
        transparency: {byte: 0x07},
        noiseCancellation: {
            levels: {
                low: 0x03,
                high: 0x01,
            },
        },
    },

    inEarDetection: false,
    lowLatencyMode: true,
    ring: true,
    ringLegacy: true,
    dualConnection: false,

    gestureOptions: {
        default: '06020102080301020802010308030103080201070A0301070A',
        slots: [
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'triple'},
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'action-hold'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'triple'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'action-hold'},
        ],
        mapping: {
            gestureTypes: {
                'triple': 0x03,
                'action-hold': 0x07,
            },
            actions: {
                'no-action': [0x01],
                'skip-back': [0x08],
                'skip-forward': [0x09],
                'voice-assistant': [0x0B],
                'anc-type': [0x0A],
            },
        },
        gestures: {
            'triple': {
                type: 'tap',
                actions: [
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                    'no-action',
                ],
            },
            'action-hold': {
                type: 'tap',
                actions: [
                    'anc-type',
                    'no-action',
                ],
            },
        },
    },

    albumArtIcon: 'earbuds-stem',
    budsIcon: 'earbuds-stem',
    case: 'case-square',
};

