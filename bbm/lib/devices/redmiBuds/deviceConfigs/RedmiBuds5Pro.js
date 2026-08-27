'use strict';

export default {
    name: 'Redmi Buds 5 Pro',
    id: {
        vid: [0x2717],
        pid: [0x506C, 0x506D, 0x506F],
    },

    batteryMutiple: true,
    batteryCase: true,

    eqPreset: {
        standard: 0x00,
        treble: 0x06,
        base: 0x05,
        voice: 0x01,
        custom: 0x0A,
    },

    noiseControl: {
        off: 0x00,
        noiseCancellation: 0x01,
        transparency: 0x02,
    },

    adaptiveNcSwitch: true,

    noiseCancellationStrength: {
        low: 0x01,
        mid: 0x00,
        high: 0x02,
    },

    transparencyStrength: {
        regular: 0x00,
        voice: 0x01,
        ambient: 0x02,
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
            'single': 0x04,
            'double': 0x01,
            'triple': 0x02,
            'action-hold': 0x03,
        },
        gestures: {
            'single': {
                type: 'tap',
                actions: {
                    'no-action': 0x08,
                    'play-pause': 0x01,
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                    'volume-up': 0x04,
                    'volume-down': 0x05,
                },
            },
            'double': {
                type: 'tap',
                actions: {
                    'play-pause': 0x01,
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                    'volume-up': 0x04,
                    'volume-down': 0x05,
                },
            },
            'triple': {
                type: 'tap',
                actions: {
                    'no-action': 0x08,
                    'play-pause': 0x01,
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

    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-normal',
};

