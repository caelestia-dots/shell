'use strict';

export default {
    name: 'Redmi Buds 6 Play',
    id: {
        vid: [0x2717],
        pid: [0x509B],
    },

    batteryMutiple: true,
    batteryCase: true,

    eqPreset: {
        standard: 0x00,
        treble: 0x06,
        base: 0x05,
        voice: 0x01,
        boostVolume: 0x07,
    },

    inEarDetection: false,
    lowLatencyMode: true,
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
                    'voice-assistant': 0x00,
                },
            },
            'double': {
                type: 'tap',
                actions: {
                    'no-action': 0x08,
                    'play-pause': 0x01,
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                    'volume-up': 0x04,
                    'volume-down': 0x05,
                    'voice-assistant': 0x00,
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
                    'voice-assistant': 0x00,
                },
            },
            'action-hold': {
                type: 'press',
                actions: {
                    'no-action': 0x00,
                    'voice-assistant': 0x08,
                    'take-photo': 0x09,
                    'play-pause': 0x01,
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                    'volume-up': 0x04,
                    'volume-down': 0x05,
                },
            },
        },
    },

    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-oval-short',
};

