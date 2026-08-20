'use strict';

export default {
    name: 'Accentum True Wireless',
    id: ['ATW1'],
    type: 'earbuds',

    batteryMultiple: true,
    batteryCase: true,

    eq: {
        displayedBand: [63, 250, 1000, 4000, 8000],
        band: [0, 90, 325, 1500, 6500],
        range: 6,
        bassBoost: true,
        custom: true,
        presets: {
            flat: [0.0, 0.0, 0.0, 0.0, 0.0],
            rock: [-2.5, 0.5, 2.5, -0.5, -3.5],
            pop: [0.0, -2.5, 0.0, 2.5, -1.0],
            dance: [3.0, -1.0, -2.0, 0.0, 1.0],
            hipHop: [2.5, 1.5, -1.5, -1.5, -1.5],
            classical: [-3.5, -1.5, 0.0, 1.5, 0.5],
            movie: [-3.0, -1.0, 0.0, 1.0, -4.0],
            jazz: [-4.0, 0.0, 1.0, 3.0, -1.0],
        },
    },

    noiseControl: {
        type: 1,
        wind: {
            off: 0x00,
            max: 0x01,
        },
        transparencyStep: 3,
    },

    reportsCodec: true,
    inEarDetection: true,
    smartPause: true,
    autoAnswer: true,
    autoPowerOff: [0, 15, 30, 60],
    //    ring: true,
    sideTone: 3,
    dualConnection: true,
    notifcation: true,

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
        0x16, // Find Ringing
    ],

    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-normal',
};

