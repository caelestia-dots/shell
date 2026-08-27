'use strict';

export default {
    name: 'Xiaomi Buds 5 Pro',
    id: {
        vid: [0x2717],
        pid: [0x50AD, 0x50B4, 0x50AB, 0x50AC],
    },

    batteryMutiple: true,
    batteryCase: true,

    eqPreset: {
        harman: 0x0E,
        harmanmaster: 0x0F,
        treble: 0x06,
        base: 0x05,
        voice: 0x01,
        legendary: 0x0C,
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
        high: 0x02,
    },

    transparencyStrength: {
        regular: 0x00,
        voice: 0x01,
        ambient: 0x02,
    },

    inEarDetection: true,
    immersiveSound: true,
    dualConnection: true,
    adaptiveSound: true,
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
            'swipe': 0x05,
        },
        gestures: {
            'single': {
                type: 'pinch',
                actions: {
                    'no-action': 0x08,
                    'play-pause': 0x01,
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                    'volume-up': 0x04,
                    'volume-down': 0x05,
                    'take-photo': 0x09,
                },
            },
            'double': {
                type: 'pinch',
                actions: {
                    'no-action': 0x08,
                    'play-pause': 0x01,
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                    'volume-up': 0x04,
                    'volume-down': 0x05,
                },
            },
            'triple': {
                type: 'pinch',
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
                type: 'pinch',
                actions: {
                    'no-action': 0x00,
                    'voice-assistant': 0x08,
                    'take-photo': 0x09,
                },
            },
            'swipe': {
                type: 'swipe',
                actions: {
                    'no-action': 0x00,
                    'change-volume': 0x0B,
                },
            },
        },
    },

    albumArtIcon: 'earbuds-stem',
    budsIcon: 'earbuds-stem',
    case: 'case-normal',
};

