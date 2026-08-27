'use strict';

export default {
    name: 'Xiaomi Buds 5',
    id: {
        vid: [0x2717],
        pid: [0x5081, 0x5082],
    },

    batteryMutiple: true,
    batteryCase: true,

    eqPreset: {
        harman: 0x0E,
        treble: 0x06,
        base: 0x05,
        voice: 0x01,
        classic: 0x0B,
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
                    'voice-assistant': 0x08,
                    'take-photo': 0x09,
                },
            },
        },
    },

    albumArtIcon: 'earbuds-stem2',
    budsIcon: 'earbuds-stem2',
    case: 'case-normal',
};

