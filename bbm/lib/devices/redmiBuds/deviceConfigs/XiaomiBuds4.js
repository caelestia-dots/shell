'use strict';

export default {
    name: 'Xiaomi Buds 4',
    id: {
        vid: [0x2717],
        pid: [0x5044],
    },

    batteryMutiple: true,
    batteryCase: true,

    noiseControl: {
        off: 0x00,
        noiseCancellation: 0x01,
    },

    adaptiveNcSwitch: true,

    noiseCancellationStrength: {
        low: 0x01,
        high: 0x00,
    },

    inEarDetection: true,
    immersiveSound: true,
    lowLatencyMode: true,
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
                type: 'press',
                actions: {
                    'skip-forward': 0x03,
                    'volume-down': 0x05,
                },
            },
            'triple': {
                type: 'press',
                actions: {
                    'skip-back': 0x02,
                    'volume-down': 0x05,
                },
            },
            'action-hold': {
                type: 'press',
                actions: {
                    'voice-assistant': 0x08,
                    'noise-control': 0x06,
                },
            },
        },
        noiseControlModes: ['off', 'noise-cancellation'],
    },

    albumArtIcon: 'earbuds-stem2',
    budsIcon: 'earbuds-stem2',
    case: 'case-narrow',
};

