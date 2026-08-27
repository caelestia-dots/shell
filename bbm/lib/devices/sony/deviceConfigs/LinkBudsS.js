'use strict';

export default {
    name: 'LinkBuds S', // uuid: 956c7b26-d49a-4ba8-b03f-b17d393cb6e2 (v2)
    pattern: /.*LinkBuds S.*/,
    modaliasPrefix: 'v054Cp0DF4',
    batteryDual: true,
    batteryCase: true,
    ambientSoundControl: true,
    ambientSoundControlButtonMode: true,
    quickAccess: true,
    audioUpsampling: true,
    buttonModesLeftRight: ['amb', 'vol', 'pb', 'na'], // alx, ggle
    pauseWhenTakenOff: true,
    automaticPowerOffWhenTakenOff: true,
    powerOffFromPhone: true,
    speakToChatEnabled: true,
    speakToChatConfig: true,
    voiceNotifications: true,
    equalizerSixBands: true,
    dualConnection: {
        hasRoutingIndicator: true,
        hasRoutingControl: true,
        hasActiveFix: true,
    },
    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-oval',
};

