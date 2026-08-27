'use strict';

export default {
    name: 'Redmi AirDots 3 Pro',
    id: {
        vid: [0x5A4D],
        pid: [0xEA03, 0xEA0D],
    },

    batteryMutiple: true,
    batteryCase: true,

    eqPreset: {
        balanced: 0x15,
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
        adaptive: 0x03,
    },

    transparencyStrength: {
        regular: 0x00,
        voice: 0x01,
    },

    inEarDetection: true,
    lowLatencyMode: true,
    adaptiveSound: true,
    dualConnection: true,
    autoAnswer: true,
    adaptiveChat: true, // 5,10,15,close


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
                    'volume-up': 0x04,
                    'volume-down': 0x05,
                },
            },
            'triple': {
                type: 'press',
                actions: {
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

