'use strict';

// Nothing Headphone (1)
export default {
    modelId: 'B175',
    name: 'CMF Headphone Pro',
    pattern: /^.*CMF Headphone Pro$/,

    batterySingle: true,

    eqPreset: {
        balanced: 0x00,
        voice: 0x01,
        more_treble: 0x02,
        more_bass: 0x03,
        custom: 0x05,
    },

    bassEnhanceLevel: 5,

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

    inEarDetection: true,
    lowLatencyMode: true,
    ring: true,
    dualConnection: true,
    dualConnectionReboot: false,
    spatialimmersiveModes: true,

    gestureOptions: {
        default: '060A0107060A010B0605012306010716',
        slots: [
            {group: 'single', device: 0x06, buttonId: 0x0A, type: 'single'},
            {group: 'single', device: 0x06, buttonId: 0x0A, type: 'action-hold'},
            {group: 'roller', device: 0x06, buttonId: 0x01, type: 'roller-action-hold'},
            {group: 'slider', device: 0x06, buttonId: 0x05, type: 'slider-single'},
        ],
        mapping: {
            gestureTypes: {
                'single': 0x01,
                'action-hold': 0x07,
                'roller-action-hold': 0x07,
                'slider-single': 0x01,
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
                'ultra-bass': [0x23],
                'treble-enhance': [0x24],
            },
        },
        gestures: {
            'single': {
                type: 'press',
                actions: [
                    'channel-hop',
                    'voice-assistant',
                    'news-description',
                    'spatial-audio',
                    'mic-on-off',
                    'eq-preset',
                    'noise-control',
                    'no-action',
                ],
            },
            'action-hold': {
                type: 'press',
                actions: [
                    'channel-hop',
                    'voice-assistant',
                    'news-description',
                    'spatial-audio',
                    'mic-on-off',
                    'eq-preset',
                    'noise-control',
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
            'slider-single': {
                type: 'slide',
                actions: [
                    'ultra-bass',
                    'treble-enhance',
                ],
            },
        },
        noiseControlModes: ['off', 'transparency', 'noise-cancellation'],
    },

    albumArtIcon: 'headphone1',
    budsIcon: 'headphone1',
};

