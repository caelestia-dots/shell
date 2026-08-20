'use strict';

export default {
    name: 'WF-1000XM6', // uuid: 956c7b26-d49a-4ba8-b03f-b17d393cb6e2 (v2)
    pattern: /.*WF-1000XM6.*/,
    batteryDual: true,
    batteryCase: true,
    powerOffFromPhone: true,
    ambientSoundControl: true,
    ambientSoundControlNA: true,
    ambientSoundControlButtonMode: true,
    speakToChatEnabled: true,
    speakToChatConfig: true,
    speakToChatFocusOnVoice: true,
    voiceNotifications: true,
    voiceNotificationsVolume: true,
    automaticPowerOffWhenTakenOff: true,
    equalizerTenBands: true,
    listeningMode: true,
    quickAccess: true,
    audioUpsampling: true,
    pauseWhenTakenOff: true,
    dualConnection: {
        hasRoutingIndicator: true,
        hasRoutingControl: true,
        hasActiveFix: true,
    },
    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-oval',
};

