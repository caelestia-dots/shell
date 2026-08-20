'use strict';

export default {
    name: 'WH-1000XM5', // uuid: 956c7b26-d49a-4ba8-b03f-b17d393cb6e2 (v2)
    pattern: /.*WH-1000XM5.*/,
    modaliasPrefix: 'v054Cp0DF0',
    batterySingle: true,
    powerOffFromPhone: true,
    ambientSoundControl: true,
    ambientSoundControlButtonMode: true,
    speakToChatEnabled: true,
    speakToChatConfig: true,
    speakToChatFocusOnVoice: true,
    voiceNotifications: true,
    automaticPowerOffWhenTakenOff: true,
    equalizerSixBands: true,
    quickAccess: true,
    pauseWhenTakenOff: true,
    audioUpsampling: true,
    dualConnection: {
        hasRoutingIndicator: true,
        hasRoutingControl: true,
        hasActiveFix: true,
    },
    albumArtIcon: 'headphone1',
    budsIcon: 'headphone1',
};

