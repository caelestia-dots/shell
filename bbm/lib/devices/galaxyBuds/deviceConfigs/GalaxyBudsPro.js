'use strict';

// 4) Galaxy Buds Pro
export default {
    modelId: 4,
    name: 'Galaxy Buds Pro',

    features: {
        ambientCustomize: true,
        ambientCustomizeVolume: 4,
        ambientSidetone: true,
        ambientSound: true,
        ambientSoundVolume: true,
        ambientVolumeMax: 3, // from GBC
        bixbyWakeup: true,
        buildInfo: true,
        callPathControl: true,
        caseBattery: true,
        detectConversations: true,
        doubleTapVolume: true,
        gamingMode: true,
        hiddenAtMode: true,
        noiseCancellation: true,
        noiseControl: true,
        noiseControlModeDualSide: true,
        noiseControlsWithOneEarbud: true,
        noiseReductionAdjustments: true,
        noiseReductionLevels: 1,
        pairingMode: true,
        seamlessConnection: true,
        smartThingsFind: true,
        spatialSensor: true,
        stereoPan: true,
        voltage: true,
    },
    touchOptions: {
        voiceAssistant: 1,
        noiseControl: 2,
        volume: 3,
        spotifySpotOn: 4,
        otherL: 5,
        otherR: 6,
    },

    albumArtIcon: 'earbuds',
    budsIcon: 'earbuds',
    case: 'case-normal',
};

