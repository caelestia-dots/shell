'use strict';

export default {
    name: 'Accentum Plus Wireless',
    id: ['ACPAEBT'],
    type: 'headband',

    batterySingle: true,


    audioMode: {
        off: 0x00,
        eq: 0x01,
        podcast: 0x02,
        personalized: 0x03,
    },

    eq: {
        displayedBand: [50, 250, 800, 3000, 8000],
        band: [0, 125, 400, 1600, 6000],
        range: 6,
        bassBoost: true,
        custom: true,
        presets: {
            flat: [0.0, 0.0, 0.0, 0.0, 0.0],
            rock: [0.0, 0.0, 3.0, 3.0, -1.0],
            pop: [0.0, -5.0, 0.0, 5.0, 0.0],
            dance: [2.0, -3.0, -3.0, 1.0, 1.0],
            hipHop: [3.0, -1.0, -4.0, 2.0, 0.0],
            classical: [0.0, 0.0, 0.0, 1.0, 2.0],
            movie: [0.0, 0.0, 2.0, 2.0, -1.0],
            jazz: [-3.0, 0.0, 2.0, 2.0, 0.0],
        },
    },

    noiseControl: {
        type: 2,
        adaptive: true,
        wind: {
            off: 0x00,
            max: 0x01,
            auto: 0x02,
        },
    },

    inEarDetection: true,
    smartPause: true,
    autoAnswer: true,
    autoPowerOff: [0, 15, 30, 60],
    //    ring: true,
    sideTone: 5,
    dualConnection: true,
    notifcation: true,
    comfortCalls: true,

    registerNotification: [
        0x00, // Core
        0x02, // Device
        0x03, // Battery
        0x04, // Audio
        0x08, // User EQ
        0x09, // Versions
        0x0A, // Management
        0x0B, // MMI
        0x0C, // Transparency
        0x0D, // ANC
    ],

    albumArtIcon: 'headphone-1',
    budsIcon: 'headphone-1',
};

