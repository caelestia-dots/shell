'use strict';

export default {
    modelId: 'B157',
    name: 'Ear (Stick)',
    pattern: /^.*Ear \(Stick\)$/,

    batteryLR: true,
    batteryCase: true,

    eqPreset: {
        balanced: 0x00,
        voice: 0x01,
        more_treble: 0x02,
        more_bass: 0x03,
        custom: 0x05,
        advance: 0x06,
    },

    noiseControl: {
        off: {byte: 0x01},
        noiseCancellation: {byte: 0x04},
    },

    inEarDetection: true,
    lowLatencyMode: true,
    ring: true,
    dualConnection: false,

    gestureOptions: {
        default: '08020102090301020902010308030103080201070A0301070A0201090103010901',
        slots: [
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'double'},
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'triple'},
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'action-hold'},
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'double-action-hold'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'double'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'triple'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'action-hold'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'double-action-hold'},
        ],
        mapping: {
            gestureTypes: {
                'double': 0x02,
                'triple': 0x03,
                'action-hold': 0x07,
                'double-action-hold': 0x09,
            },
            actions: {
                'skip-back': [0x08],
                'skip-forward': [0x09],
                'voice-assistant': [0x0B],
                'noise-control': [0x0A, 0x14, 0x15, 0x16],
                'volume-up': [0x12],
                'volume-down': [0x13],
                'no-action': [0x01],
            },
        },
        gestures: {
            'double': {
                type: 'pinch',
                actions: [
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                ],
            },
            'triple': {
                type: 'pinch',
                actions: [
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                ],
            },
            'action-hold': {
                type: 'pinch',
                actions: [
                    'noise-control',
                    'volume-up',
                    'volume-down',
                    'voice-assistant',
                ],
            },
            'double-action-hold': {
                type: 'pinch',
                actions: [
                    'noise-control',
                    'volume-up',
                    'volume-down',
                    'voice-assistant',
                    'no-action',
                ],
            },
        },
        noiseControlModes: ['off', 'transparency', 'noise-cancellation'],
    },

    albumArtIcon: 'earbuds-stem2',
    budsIcon: 'earbuds-stem2',
    case: 'case-oval-short',
};

