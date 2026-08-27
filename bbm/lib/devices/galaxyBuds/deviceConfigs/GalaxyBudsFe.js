'use strict';

// 7) Galaxy Buds FE
export default {
    modelId: 7,
    name: 'Galaxy Buds FE',

    features: {
        advancedTouchLock: true,
        advancedTouchLockForCalls: true,
        ambientCustomize: true,
        ambientCustomizeVolume: 2,
        ambientSidetone: true,
        ambientSound: true,
        ambientVolumeMax: 2,
        bixbyWakeup: true,
        callPathControl: true,
        caseBattery: true,
        chargingState: true,
        fmgRingWhileWearing: true,
        gamingMode: true,
        gearFitTest: true,
        noiseCancellation: true,
        noiseControl: true,
        noiseControlModeDualSide: true,
        noiseControlsWithOneEarbud: true,
        noiseTouchAndHoldNewVersion: true, // Is new? Delete this line
        rename: true,
        seamlessConnection: true,
        smartThingsFind: true,
        stereoPan: true,
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

