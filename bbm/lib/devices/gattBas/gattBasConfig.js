'use strict';

export const Bat1Group = new Set([
    'Front', 'Top', 'Upper', 'Main', 'Inside', 'Left', 'Internal',
]);

export const Bat2Group = new Set([
    'Back', 'Bottom', 'Lower', 'Backup', 'Auxiliary',
    'Supplementary', 'Outside', 'Right', 'External',
]);

export const CpfNames = {
    0x0100: 'Front',  0x0101: 'Back',       0x0102: 'Top',        0x0103: 'Bottom',
    0x0104: 'Upper',  0x0105: 'Lower',      0x0106: 'Main',       0x0107: 'Backup',
    0x0108: 'Auxiliary', 0x0109: 'Supplementary', 0x010B: 'Inside',  0x010C: 'Outside',
    0x010D: 'Left',   0x010E: 'Right',      0x010F: 'Internal',   0x0110: 'External',
};

export const supportedCommonIcons = [
    'audio-card', 'audio-speakers', 'audio-speakers2', 'audio-speakers3',
    'audio-headphones', 'audio-headset', 'headphone1', 'earbuds',
    'earbuds-wingtip', 'earbuds-wingtip2',  'earbuds-neckband', 'earbuds-stem',
    'earbuds-stem2', 'earbuds-stem3', 'input-microphone', 'input-gaming',
    'input-gaming2', 'input-gaming3', 'input-keyboard', 'input-keyboard2', 'input-mouse',
    'input-tablet', 'touchpad', 'phone', 'camera-photo', 'camera-video',
    'computer', 'video-display', 'printer', 'scanner', 'multimedia-player',
    'modem', 'network-wireless', 'wearable', 'wearable2',
];

export const supportedCircularWidgetIcons = [
    'audio-card', 'audio-speakers', 'audio-speakers2', 'audio-speakers3',
    'audio-headphones', 'audio-headset', 'headphone1', 'earbuds',
    'earbuds-left', 'earbuds-right', 'earbuds-wingtip', 'earbuds-wingtip-left',
    'earbuds-wingtip-right', 'earbuds-wingtip2', 'earbuds-wingtip2-left',
    'earbuds-wingtip2-right', 'earbuds-neckband', 'earbuds-stem', 'earbuds-stem-left',
    'earbuds-stem-right', 'earbuds-stem2', 'earbuds-stem2-left', 'earbuds-stem2-right',
    'earbuds-stem3', 'earbuds-stem3-left', 'earbuds-stem3-right', 'case-normal',
    'case-narrow', 'case-oval', 'case-oval-short', 'input-microphone', 'input-gaming',
    'input-gaming2', 'input-gaming3', 'input-keyboard', 'input-keyboard2',
    'input-split-keyboard-l', 'input-split-keyboard-r', 'input-mouse',
    'input-tablet', 'touchpad', 'phone', 'multimedia-player', 'pda', 'camera-photo',
    'camera-video', 'computer', 'video-display', 'printer', 'scanner',
    'modem', 'network-wireless', 'wearable', 'wearable2',
];
