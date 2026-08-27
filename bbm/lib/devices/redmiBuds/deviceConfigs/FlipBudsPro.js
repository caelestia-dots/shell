'use strict';

export default {
    name: 'FlipBuds Pro',
    id: {
        vid: [0x0001],
        pid: [0x0000, 0x0001],
    },

    batteryMutiple: true,
    batteryCase: true,

    noiseControl: {
        off: 0x00,
        noiseCancellation: 0x01,
        transparency: 0x02,
    },

    noiseCancellationStrength: {
        low: 0x01,
        mid: 0x00,
        high: 0x02,
        adaptive: 0x03,
    },

    transparencyStrength: {
        regular: 0x00,
        voice: 0x01,
        ambient: 0x02,
    },

    inEarDetection: true,
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
                    'skip-forward': 0x03,
                    'volume-up': 0x04,
                },
            },
            'triple': {
                type: 'tap',
                actions: {
                    'skip-back': 0x02,
                    'volume-down': 0x05,
                },
            },
            'action-hold': {
                type: 'tap',
                actions: {
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

