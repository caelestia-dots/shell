'use strict';

export default {
    modelId: 'B198',
    name: 'Nothing Headphone (a)',
    pattern: /^.*Nothing Headphone \(a\)$/,

    batterySingle: true,

    eqPreset: {
        balanced: 0x00,
        voice: 0x01,
        more_treble: 0x02,
        more_bass: 0x03,
        custom: 0x05,
        advance: 0x06,
    },

    bassEnhanceLevel: 3,

    noiseControl: {
        off: {byte: 0x05},
        transparency: {byte: 0x07},
        noiseCancellation: {
            levels: {
                low: 0x03,
                mid: 0x02,
                high: 0x01,
                adaptive: 0x04,
            },
        },
    },

    lowLatencyMode: true,
    ring: true,
    dualConnection: true,
    spatialHeadTracking: true,
    autoPowerOff: [30, 60, 120, 180, 240],

    gestureOptions: {
        default: '0306010716060A010B060A0701',
        slots: [
            {group: 'single', device: 0x06, buttonId: 0x0A, type: 'single'},
            {group: 'single', device: 0x06, buttonId: 0x0A, type: 'action-hold'},
            {group: 'roller', device: 0x06, buttonId: 0x01, type: 'roller-action-hold'},
        ],
        mapping: {
            gestureTypes: {
                'single': 0x01,
                'action-hold': 0x07,
                'roller-action-hold': 0x07,
            },
            actions: {
                'no-action': [0x01],
                'channel-hop': [0x20],
                'voice-assistant': [0x0B],
                'news-description': [0x1F],
                'spatial-audio': [0x1B],
                'mic-on-off': [0x1D],
                'eq-preset': [0x22],
                'noise-control': [0x0A, 0x14, 0x15, 0x16],
                'take-photo': [0x18],
            },
        },
        gestures: {
            'single': {
                type: 'press',
                actions: [
                    'channel-hop',
                    'voice-assistant',
                    'news-description',
                    'noise-control',
                    'take-photo',
                    'mic-on-off',
                    'eq-preset',
                    'no-action',
                ],
            },
            'action-hold': {
                type: 'press',
                actions: [
                    'channel-hop',
                    'voice-assistant',
                    'news-description',
                    'noise-control',
                    'mic-on-off',
                    'eq-preset',
                    'no-action',
                ],
            },
            'roller-action-hold': {
                type: 'press',
                actions: [
                    'noise-control',
                    'no-action',
                ],
            },
        },
        noiseControlModes: ['off', 'transparency', 'noise-cancellation'],
    },

    albumArtIcon: 'headphone1',
    budsIcon: 'headphone1',
};

