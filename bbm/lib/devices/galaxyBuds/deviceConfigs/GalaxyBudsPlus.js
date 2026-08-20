'use strict';

// 2) Galaxy Buds+
export default {
    modelId: 2,
    name: 'Galaxy Buds+',

    features: {
        ambientExtraLoud: true,
        ambientSidetone: true,
        ambientSound: true,
        ambientSoundVolume: true,
        ambientVolumeMax: 2, // 3 if ExtraLoud is set
        buildInfo: true,
        callPathControl: true,
        caseBattery: true,
        doubleTapVolume: true,
        gamingMode: true,
        hiddenAtMode: true,
        pairingMode: true,
        seamlessConnection: true,
        smartThingsFind: true,
        voltage: true,
    },
    touchOptions: {
        voiceAssistant: 1,
        ambientSound: 2,
        volume: 3,
        spotifySpotOn: 4,
        otherL: 5,
        otherR: 6,
    },

    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-oval',
};

