'use strict';

export default {
    name: 'WF-1000XM4', // uuid: 956c7b26-d49a-4ba8-b03f-b17d393cb6e2 (v2)
    pattern: /.*WF-1000XM4.*/,
    modaliasPrefix: 'v054Cp0DE1',
    batteryDual: true,
    batteryCase: true,
    ambientSoundControl: true,
    windNoiseReduction: true,
    equalizerSixBands: true,
    audioUpsampling: true,
    buttonModesLeftRight: ['amb', 'vol', 'pb', 'na'],
    pauseWhenTakenOff: true,
    automaticPowerOffWhenTakenOff: true,
    dualConnection: {
        hasRoutingIndicator: true,
        hasRoutingControl: true,
        hasActiveFix: true,
    },
    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-oval',
};

