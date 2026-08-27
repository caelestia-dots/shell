'use strict';

export default {
    modelId: 'B164',
    name: 'Neckband Pro',
    pattern: /^.*Neckband Pro$/,

    batterySingle: true,

    eqPreset: {
        balanced: 0x00,
        voice: 0x01,
        more_treble: 0x02,
        more_bass: 0x03,
        custom: 0x05,
    },

    bassEnhanceLevel: 5,

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

    lowLatencyMode: true,
    ring: true,
    dualConnection: true,
    dualConnectionReboot: true,
    spatialAudioSwitch: true,

    gestureOptions: {
        default: '03060102090601030806010716',
        slots: [
            {group: 'single', device: 0x06, buttonId: 0x01, type: 'double'},
            {group: 'single', device: 0x06, buttonId: 0x01, type: 'triple'},
            {group: 'single', device: 0x06, buttonId: 0x01, type: 'action-hold'},
        ],
        mapping: {
            gestureTypes: {
                'double': 0x02,
                'triple': 0x03,
                'action-hold': 0x07,
            },
            actions: {
                'skip-back': [0x08],
                'skip-forward': [0x09],
                'voice-assistant': [0x0B],
                'noise-control': [0x0A, 0x14, 0x15, 0x16],
            },
        },
        gestures: {
            'double': {
                type: 'tap',
                actions: [
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                ],
            },
            'triple': {
                type: 'tap',
                actions: [
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                ],
            },
            'action-hold': {
                type: 'tap',
                actions: [
                    'noise-control',
                ],
            },
        },
        noiseControlModes: ['off', 'transparency', 'noise-cancellation'],
    },


    albumArtIcon: 'earbuds-neckband',
    budsIcon: 'earbuds-neckband',
};

