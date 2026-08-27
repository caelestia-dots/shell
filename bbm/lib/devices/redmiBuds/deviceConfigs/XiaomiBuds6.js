'use strict';

export default {
    name: 'Xiaomi Buds 6',
    id: {
        vid: [0x2717],
        pid: [0x50EA],
    },

    batteryMutiple: true,
    batteryCase: true,

    eqPreset: {
        harman: 0x0E,
        harmanmaster: 0x0F,
        soothingboost: 0x0D,
        treble: 0x06,
        voice: 0x01,
        custom: 0x0A,
    },

    noiseControl: {
        off: 0x00,
        noiseCancellation: 0x01,
    },

    adaptiveNcSwitch: true,

    noiseCancellationStrength: {
        low: 0x00,
        high: 0x02,
    },

    inEarDetection: true,
    dualConnection: true,
    immersiveSound: true,
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
                type: 'press',
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
            'triple': {
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
            'action-hold': {
                type: 'press',
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

    albumArtIcon: 'earbuds-stem2',
    budsIcon: 'earbuds-stem2',
    case: 'case-normal',
};

