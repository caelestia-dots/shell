'use strict';
/* eslint-disable max-len */
export default {
    modelId: 'B187',
    name: 'CMF Buds Pro 2',
    pattern: /^.*CMF Buds Pro 2$/,

    batteryLR: true,
    batteryCase: true,

    eqPreset: {
        dirac: 0x00,
        pop: 0x03,
        rock: 0x01,
        electronic: 0x02,
        enhance_vocals: 0x04,
        classical: 0x05,
        custom: 0x06,
    },
    eqListeningModeType: true,

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
    earTipTest: true,
    ring: true,
    dualConnection: true,
    dualConnectionReboot: true,
    spatialAudioSwitch: true,

    gestureOptions: {
        default: '0f03010209030103080301071603010901020102090201030802010716020109010401010104010201040103010401070104010a010409020104090301',
        slots: [
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'double'},
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'triple'},
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'action-hold'},
            {group: 'left',  device: 0x02, buttonId: 0x01, type: 'double-action-hold'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'double'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'triple'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'action-hold'},
            {group: 'right', device: 0x03, buttonId: 0x01, type: 'double-action-hold'},
            {group: 'case-knob', device: 0x04, buttonId: 0x01, type: 'case-knob-single'},
            {group: 'case-knob', device: 0x04, buttonId: 0x01, type: 'case-knob-double'},
            {group: 'case-knob', device: 0x04, buttonId: 0x01, type: 'case-knob-triple'},
            {group: 'case-knob', device: 0x04, buttonId: 0x01, type: 'case-knob-action-hold'},
            {group: 'case-knob', device: 0x04, buttonId: 0x01, type: 'case-knob-double-action-hold'},
            {group: 'case-knob', device: 0x04, buttonId: 0x01, type: 'case-knob-rotate'},
        ],
        mapping: {
            gestureTypes: {
                'double': 0x02,
                'triple': 0x03,
                'action-hold': 0x07,
                'double-action-hold': 0x09,
                'case-knob-single': 0x01,
                'case-knob-double': 0x02,
                'case-knob-triple': 0x03,
                'case-knob-action-hold': 0x07,
                'case-knob-double-action-hold': 0x09,
                'case-knob-rotate': 0x0A,
            },
            actions: {
                'no-action': [0x01],
                'play-pause': [0x02],
                'skip-back': [0x08],
                'skip-forward': [0x09],
                'voice-assistant': [0x0B],
                'volume-up': [0x12],
                'volume-down': [0x13],
                'noise-control': [0x0A, 0x14, 0x15, 0x16],
                'case-game-mode': [0x11],
                'volume-control': [0x17],
            },
        },
        gestures: {
            'double': {
                type: 'tap',
                actions: [
                    'play-pause',
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                    'no-action',
                ],
            },
            'triple': {
                type: 'tap',
                actions: [
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                    'no-action',
                ],
            },
            'action-hold': {
                type: 'tap',
                actions: [
                    'noise-control',
                    'voice-assistant',
                    'no-action',
                ],
            },
            'double-action-hold': {
                type: 'tap',
                actions: [
                    'volume-up',
                    'volume-down',
                    'voice-assistant',
                    'no-action',
                ],
            },
            'case-knob-single': {
                type: 'press',
                actions: [
                    'play-pause',
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                    'case-game-mode',
                    'no-action',
                ],
            },
            'case-knob-double': {
                type: 'press',
                actions: [
                    'play-pause',
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                    'case-game-mode',
                    'no-action',
                ],
            },
            'case-knob-triple': {
                type: 'press',
                actions: [
                    'play-pause',
                    'skip-back',
                    'skip-forward',
                    'voice-assistant',
                    'case-game-mode',
                    'no-action',
                ],
            },
            'case-knob-action-hold': {
                type: 'press',
                actions: [
                    'noise-control',
                    'voice-assistant',
                    'case-game-mode',
                    'no-action',
                ],
            },
            'case-knob-double-action-hold': {
                type: 'press',
                actions: [
                    'volume-up',
                    'volume-down',
                    'voice-assistant',
                    'case-game-mode',
                    'no-action',
                ],
            },
            'case-knob-rotate': {
                type: 'rotate',
                actions: [
                    'volume-control',
                    'no-action',
                ],
            },
        },
        noiseControlModes: ['off', 'transparency', 'noise-cancellation'],
    },

    albumArtIcon: 'earbuds-stem',
    budsIcon: 'earbuds-stem',
    case: 'case-square',
};

