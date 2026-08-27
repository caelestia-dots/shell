'use strict';

export default {
    name: 'WF-C700N',   // uuid: 956c7b26-d49a-4ba8-b03f-b17d393cb6e2 (v2)
    pattern: /.*WF-C700N.*/,
    modaliasPrefix: 'v054Cp0EC4',
    batteryDual: true,
    batteryCase: true,
    ambientSoundControl: true,
    equalizerSixBands: true,
    audioUpsampling: true,
    buttonModesLeftRight: ['amb', 'vol', 'pb', 'na'],
    powerOffFromPhone: true,
    ambientSoundControlButtonMode: true,
    automaticPowerOffWhenTakenOff: true,
    automaticPowerOffByTime: true,
    dualConnection: {
        hasRoutingIndicator: true,
        hasRoutingControl: true,
        hasActiveFix: true,
    },
    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-oval-short',
};

