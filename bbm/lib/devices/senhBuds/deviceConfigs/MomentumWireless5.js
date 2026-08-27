'use strict';

export default {
    name: 'Momentum Wireless 5',
    modalais: ['M5AEBT'],
    type: 'headband',

    batterySingle: true,


    audioMode: {
        off: 0x00,
        eq: 0x01,
        podcast: 0x02,
        personalized: 0x03,
        peq: 0x04,
    },

    eq: {
        displayedBand: [50, 100, 250, 600, 1400, 3000, 7000, 12000],
        band: [50, 100, 250, 600, 1400, 3000, 7000, 12000],
        range: 6,
        bassBoost: true,
        custom: true,
        presets: {
            flat: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            rock: [-2.0, 0.0, 2.2, 2.7, 2.6, 1.1, -1.0, -2.6],
            pop: [0.0, -2.0, -1.8, 0.0, 1.2, 2.2, 1.0, -1.0],
            dance: [3.0, 0.0, -1.5, -1.9, -1.2, 0.0, 0.5, 1.0],
            hipHop: [2.5, 1.8, 0.5, -1.2, -1.5, 0.0, -1.5, -1.5],
            classical: [-3.5, -2.0, -0.8, 0.0, 0.8, 1.2, 1.0, 0.5],
            movie: [-3.2, -1.5, -0.6, 0.0, 0.5, 1.0, -1.0, -4.0],
            jazz: [-4.0, -0.8, 0.5, 1.0, 2.0, 2.5, 1.0, -1.0],
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

    reportsCodec: true,
    inEarDetection: true,
    transPause: true,
    smartPause: true,
    autoAnswer: true,
    autoPowerOff: [0, 15, 30, 60],
    //    ring: true,
    sideTone: 5,
    dualConnection: true,
    notifcation: true,
    spatialAudio: true,
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

