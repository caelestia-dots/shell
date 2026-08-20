'use strict';

// 1) Galaxy Buds
export default {
    modelId: 1,
    name: 'Galaxy Buds',

    features: {
        ambientSound: true,
        ambientSoundVolume: true,
        ambientVolumeMax: 4,
        ambientVoiceFocus: true,
        batteryType: true,
        buildInfo: true,
        current: true,
        pairingMode: true,
        seamlessConnection: true,
        sppLegacyMessageHeader: true,
        voltage: true,
    },
    touchOptions: {
        voiceAssistant: 0,
        quickAmbientSound: 1,
        volume: 2,
        ambientSound: 3,
        spotifySpotOn: 4,
        otherL: 5,
        otherR: 6,
    },

    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-oval',
};

