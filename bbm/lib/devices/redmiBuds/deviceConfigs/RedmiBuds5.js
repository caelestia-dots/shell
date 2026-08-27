'use strict';

export default {
    name: 'Redmi Buds 5',
    id: {
        vid: [0x2717],
        pid: [0x506A, 0x506B, 0x5075],
    },

    batteryMutiple: true,
    batteryCase: true,

    eqPreset: {
        standard: 0x00,
        treble: 0x06,
        base: 0x05,
        voice: 0x01,
    },

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
        ambient: 0x02,
    },

    inEarDetection: true,
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
            'single': 0x04,
            'double': 0x01,
            'triple': 0x02,
            'action-hold': 0x03,
        },
        gestures: {
            'single': {
                type: 'press',
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
                type: 'press',
                actions: {
                    'play-pause': 0x01,
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                },
            },
            'triple': {
                type: 'press',
                actions: {
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                    'volume-up': 0x04,
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
        noiseControlModes: ['off', 'transparency', 'noise-cancellation'],
    },

    albumArtIcon: 'earbuds-stem',
    budsIcon: 'earbuds-stem',
    case: 'case-normal',
};

