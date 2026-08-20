'use strict';

export default {
    name: 'WH-1000XM4', // uuid: 96cc203e-5068-46ad-b32d-e316f5e069ba (v1)
    pattern: /.*WH-1000XM4.*/,
    modaliasPrefix: 'v054Cp0D58',
    batterySingle: true,
    ambientSoundControl: true,
    windNoiseReduction: true,
    speakToChatEnabled: true,
    speakToChatConfig: true,
    speakToChatFocusOnVoice: true,
    ancOptimizer: true,
    equalizerSixBands: true,
    audioUpsampling: true,
    touchSensorSingle: true,
    pauseWhenTakenOff: true,
    automaticPowerOffWhenTakenOff: true,
    voiceNotifications: true,
    dualConnection: {
        hasRoutingIndicator: true,
        hasRoutingControl: false,
        hasActiveFix: false,
    },
    albumArtIcon: 'headphone1',
    budsIcon: 'headphone1',
};

