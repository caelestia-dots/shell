'use strict';

export default {
    modelId: 'B185',
    name: 'CMF Buds 2a',
    pattern: /^.*CMF Buds 2a$/,


    batteryLR: true,
    batteryCase: true,

    eqPreset: {
        dirac: 0x07,
        pop: 0x03,
        rock: 0x01,
        electronic: 0x02,
        enhance_vocals: 0x04,
        classical: 0x05,
        custom: 0x06,
    },
    eqListeningModeType: true,

    bassEnhanceLevel: 5,

    noiseControl: {
        off: {byte: 0x05},
        noiseCancellation: {byte: 0x04},
        transparency: {byte: 0x07},
    },

    lowLatencyMode: true,
    ring: true,
    dualConnection: true,
    dualConnectionReboot: false,

    gestureOptions: {
        default: '080201020902010308020107160201090103010209030103080301071603010901',
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
                'no-action': [0x01],
                'play-pause': [0x02],
                'skip-back': [0x08],
                'skip-forward': [0x09],
                'voice-assistant': [0x0B],
                'volume-up': [0x12],
                'volume-down': [0x13],
                'noise-control': [0x0A, 0x14, 0x15, 0x16],
                'news-description': [0x01F],
            },
        },
        gestures: {
            'double': {
                type: 'tap',
                actions: [
                    'play-pause',
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                    'news-description',
                    'no-action',
                ],
            },
            'triple': {
                type: 'pinch',
                actions: [
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                    'news-description',
                    'no-action',
                ],
            },
            'action-hold': {
                type: 'pinch',
                actions: [
                    'noise-control',
                    'voice-assistant',
                    'news-description',
                    'no-action',
                ],
            },
            'double-action-hold': {
                type: 'pinch',
                actions: [
                    'volume-up',
                    'volume-down',
                    'voice-assistant',
                    'news-description',
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

