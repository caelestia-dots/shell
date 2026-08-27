'use strict';

export default {
    name: 'QuietComfort Earbuds II',
    id: '4064',
    type: 'earbuds',

    batteryMultiple: true,
    batteryCase: true,

    eq: {
        bands: ['bass', 'mid', 'treble'],
        range: 8,
        custom: true,
        presets: {
            flat: [0, 0, 0],
            bassBoost: [8, 0, 0],
            bassReducer: [-8, -2, 0],
            trebleBoost: [0, 0, 6],
            trebleReducer: [0, -2, -6],
        },
    },

    audioModes: {
        defaultConfig: {
            index: 256,
            id: 0,
            editable: true,
            added: false,
            ui: false,
            fav: false,
            name: '',
            flag: 255,
            cnc: 5,
            autoCnc: false,
            spatial: 0,
            wind: false,
            anc: false,
        },
        presets: {
            quiet: {
                index: 0,
                id: 1,
                editable: false,
                added: true,
                ui: true,
                fav: true,
                name: 'Quiet',
                cnc: 10,
            },

            aware: {
                index: 1,
                id: 2,
                editable: false,
                added: true,
                ui: true,
                fav: true,
                name: 'Aware',
                cnc: 0,
            },
        },

        ancToggle: false,
        nc: {level: 10, steps: 1},
        autoNc: false,
        windToggle: false,
        showNCInterface: true,
        spatialMode: false,
        userMode: [
            'commute', 'focus', 'home', 'music', 'outdoor', 'relax',
            'run', 'walk', 'work', 'workout',
        ],
        totalModes: 10,
        maxAllowedFav: 10,
    },

    sideTone: {
        off: 0x00,
        low: 0x03,
        mid: 0x02,
        high: 0x01,
    },

    // inEarSettings: true,
    autoAnswer: true,
    autoPause: true,
    autoTransparency: true,
    dualConnection: true,
    maxConnected: 2,
    voicePrompt: true,

    gestureOptions: {
        buttons: {
            left: {
                id: 0x04,
                gestures: {
                    'action-hold': {
                        type: 'tap',
                        byte: 0x09,
                        actions: {
                            'disabled': 0x0E,
                            'mode': 0x11,
                            'voice-assistant': 0x01,
                        },
                    },
                },
            },

            right: {
                id: 0x03,
                gestures: {
                    'action-hold': {
                        type: 'tap',
                        byte: 0x09,
                        actions: {
                            'disabled': 0x0E,
                            'mode': 0x11,
                            'voice-assistant': 0x01,
                        },
                    },
                },
            },
        },
    },

    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-normal',
};

