'use strict';

export default {
    name: 'QuietComfort 35 II',
    id: '4020',
    type: 'headband',

    batterySingle: true,
    legacy: true,
    anr: {
        off: 0x00,
        low: 0x03,
        high: 0x01,
    },

    sideTone: {
        off: 0x00,
        low: 0x03,
        mid: 0x02,
        high: 0x01,
    },

    automaticPowerOffTimer: [0, 5, 20, 40, 60, 180],
    voicePrompt: true,

    dualConnection: true,
    maxConnected: 2,
    gestureOptions: {
        buttons: {
            action: {
                id: 0x10,
                gestures: {
                    'single': {
                        type: 'press',
                        byte: 0x04,
                        actions: {
                            'anc': 0x02,
                            'voice-assistant': 0x01,
                        },
                    },
                },
            },
        },
    },

    albumArtIcon: 'headphone1',
    budsIcon: 'headphone1',
};

