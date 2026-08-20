'use strict';

export default {
    name: 'Redmi Buds 4 Pro',
    id: {
        vid: [0x5A4D],
        pid: [0xEA0E, 0xEA0F],
    },

    batteryMutiple: true,
    batteryCase: true,

    eqPreset: {
        balanced: 0x15,
        treble: 0x06,
        base: 0x05,
        voice: 0x01,
    },

    adaptiveNcSwitch: true,

    noiseControl: {
        off: 0x00,
        noiseCancellation: 0x01,
        transparency: 0x02,
    },

    noiseCancellationStrength: {
        low: 0x01,
        mid: 0x00,
        high: 0x02,
    },

    transparencyStrength: {
        regular: 0x00,
        voice: 0x01,
    },

    inEarDetection: true,
    immersiveSound: true,
    lowLatencyMode: true,
    adaptiveSound: true,
    dualConnection: true,
    autoAnswer: true,
    ring: true,

    gestureOptions: {
        positions: {
            left: 0x00,
            right: 0x01,
        },
        gestureTypes: {
            'double': 0x01,
            'triple': 0x02,
            'action-hold': 0x03,
        },
        gestures: {
            'double': {
                type: 'tap',
                actions: {
                    'play-pause': 0x01,
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                },
            },
            'triple': {
                type: 'tap',
                actions: {
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                    'volume-up': 0x04,
                    'volume-down': 0x05,
                },
            },
            'action-hold': {
                type: 'tap',
                actions: {
                    'voice-assistant': 0x08,
                    'noise-control': 0x06,
                },
            },
        },
        noiseControlModes: ['off', 'transparency', 'noise-cancellation'],
    },

    albumArtIcon: 'earbuds-stem',
    budsIcon: 'earbuds-stem',
    case: 'case-normal',
};

