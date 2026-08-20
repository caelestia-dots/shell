'use strict';

export const DeviceTypeGoogleBuds = 'googleBuds';

export const MaestroUUID = '25e97ff7-24ce-4c4c-8951-f764a708f7b5';

export const PacketType = {
    REQUEST: 0,
    RESPONSE: 1,
    CLIENT_ERROR: 4,
    SERVER_ERROR: 5,
    SERVER_STREAM: 7,
};

export const Status = {
    OK: 0,
    FAILED_PRECONDITION: 9,
};

export const MaestroService = 0x7ede71ea;

export const MaestroMethod = {
    GET_SOFTWARE_INFO: 0x7199fa44,
    SUBSCRIBE_RUNTIME_INFO: 0xe61e8290,
    SUBSCRIBE_SETTINGS_CHANGES: 0x2821adf5,
    WRITE_SETTING: 0x9e8c9a1d,
    READ_SETTING: 0xaed0ae51,
};

export const BatteryState = {
    UNKNOWN: 0,
    NOT_CHARGING: 1,
    CHARGING: 2,
};

export const SettingId = {
    ANCR_GESTURE_LOOP: 12,
    CURRENT_ANCR_STATE: 13,
    VOLUME_EQ_ENABLE: 15,
    CURRENT_USER_EQ: 16,
    LAST_SAVED_USER_EQ: 18,
};

export const AncState = {
    OFF: 1,
    ACTIVE: 2,
    AWARE: 3,
    ADAPTIVE: 4,
};

export const EqPreset = {
    DEFAULT: 'default',
    HEAVY_BASS: 'heavy-bass',
    LIGHT_BASS: 'light-bass',
    BALANCED: 'balanced',
    VOCAL_BOOST: 'vocal-boost',
    CLARITY: 'clarity',
    LAST_SAVED: 'last-saved',
    CUSTOM: 'custom',
};

// Presets are applied by writing these bands to CURRENT_USER_EQ.
// LAST_SAVED_USER_EQ is read separately at runtime.
export const EqPresetBands = {
    [EqPreset.DEFAULT]: [0, 0, 0, 0, 0],
    [EqPreset.HEAVY_BASS]: [5, 3, 0, 0, 0],
    [EqPreset.LIGHT_BASS]: [-5, -1, 0, 0, 0],
    [EqPreset.BALANCED]: [-3, 1, 1, -1, 3],
    [EqPreset.VOCAL_BOOST]: [-1, 0, 4, 2, 0],
    [EqPreset.CLARITY]: [-2, 0, 2, 3, 5],
};

export function eqPresetForBands(eqBands) {
    const roundedBands = eqBands.map(value => Math.round(value));

    for (const [preset, bands] of Object.entries(EqPresetBands)) {
        if (JSON.stringify(roundedBands) === JSON.stringify(bands))
            return preset;
    }

    return EqPreset.CUSTOM;
}

export const Peer = {
    CASE: 2,
    LEFT_BT_CORE: 3,
    RIGHT_BT_CORE: 4,
    MAESTRO_A: 10,
    MAESTRO_B: 13,
};

export const CandidateChannels = [18, 19, 21, 23, 24, 26];

export function addressForChannel(channel) {
    switch (channel) {
        case 18:
            return addressFromPeers(Peer.MAESTRO_A, Peer.CASE);
        case 19:
            return addressFromPeers(Peer.MAESTRO_A, Peer.LEFT_BT_CORE);
        case 21:
            return addressFromPeers(Peer.MAESTRO_A, Peer.RIGHT_BT_CORE);
        case 23:
            return addressFromPeers(Peer.MAESTRO_B, Peer.CASE);
        case 24:
            return addressFromPeers(Peer.MAESTRO_B, Peer.LEFT_BT_CORE);
        case 26:
            return addressFromPeers(Peer.MAESTRO_B, Peer.RIGHT_BT_CORE);
        default:
            return null;
    }
}

function addressFromPeers(source, target) {
    return (source & 0x0f) << 6 | (target & 0x0f) << 10;
}
