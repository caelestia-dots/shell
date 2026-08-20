'use strict';

export default {
    name: 'Xiaomi Buds 3',
    id: {
        vid: [0x2717],
        pid: [0x5026, 0x502B, 0x5066, 0x505E, 0x505A],
    },

    batteryMutiple: true,
    batteryCase: true,

    inEarDetection: true,
    lowLatencyMode: true,
    ring: true,


    gestureOptions: {
        positions: {
            left: 0x00,
            right: 0x01,
        },
        gestureTypes: {
            'double': 0x01,
            'triple': 0x02,
            'action-hold': 0x03,
        },
        gestures: {
            'double': {
                type: 'press',
                actions: {
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                },
            },
            'triple': {
                type: 'press',
                actions: {
                    'skip-back': 0x02,
                    'skip-forward': 0x03,
                },
            },
            'action-hold': {
                type: 'press',
                actions: {
                    'voice-assistant': 0x08,
                    'no-action': 0x00,
                },
            },
        },
    },

    albumArtIcon: 'earbuds-stem3',
    budsIcon: 'earbuds-stem3',
    case: 'case-normal',
};

