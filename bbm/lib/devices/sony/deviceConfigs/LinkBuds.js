'use strict';

export default {
    name: 'LinkBuds',
    pattern: /^LinkBuds$/,
    modaliasPrefix: 'v054Cp0DDF',
    batteryDual: true,
    batteryCase: true,
    speakToChatEnabled: true,
    speakToChatConfig: true,
    adaptiveVolumeControl: true,
    equalizerSixBands: true,
    audioUpsampling: true,
    buttonModesLeftRight: ['vol', 'pb', 'na'], // qa, alx, song, vass
    pauseWhenTakenOff: true,
    automaticPowerOffWhenTakenOff: true,
    wideAreaTap: true,
    voiceNotifications: true,
    dualConnection: {
        hasRoutingIndicator: true,
        hasRoutingControl: true,
        hasActiveFix: true,
    },
    albumArtIcon: 'earbuds-wingtip',
    budsIcon: 'earbuds-wingtip',
    case: 'case-normal',
};

