'use strict';
import AirPods1stGen from './deviceConfigs/AirPods1stGen.js';
import AirPods2ndGen from './deviceConfigs/AirPods2ndGen.js';
import AirPods3rdGen from './deviceConfigs/AirPods3rdGen.js';
import AirPods4thGen from './deviceConfigs/AirPods4thGen.js';
import AirPods4thGenANC from './deviceConfigs/AirPods4thGenANC.js';
import AirPodsMax from './deviceConfigs/AirPodsMax.js';
import AirPodsMax2 from './deviceConfigs/AirPodsMax2.js';
import AirPodsMaxUsbC from './deviceConfigs/AirPodsMaxUsbC.js';
import AirPodsPro from './deviceConfigs/AirPodsPro.js';
import AirPodsPro2ndGen from './deviceConfigs/AirPodsPro2ndGen.js';
import AirPodsPro2ndGenUsbC from './deviceConfigs/AirPodsPro2ndGenUsbC.js';
import AirPodsPro3rdGen from './deviceConfigs/AirPodsPro3rdGen.js';
import BeatsFitPro from './deviceConfigs/BeatsFitPro.js';
import BeatsFlex from './deviceConfigs/BeatsFlex.js';
import BeatsSolo3 from './deviceConfigs/BeatsSolo3.js';
import BeatsSolo4 from './deviceConfigs/BeatsSolo4.js';
import BeatsSoloBuds from './deviceConfigs/BeatsSoloBuds.js';
import BeatsSoloPro from './deviceConfigs/BeatsSoloPro.js';
import BeatsStudio3 from './deviceConfigs/BeatsStudio3.js';
import BeatsStudioBuds from './deviceConfigs/BeatsStudioBuds.js';
import BeatsStudioBudsPlus from './deviceConfigs/BeatsStudioBudsPlus.js';
import BeatsStudioPro from './deviceConfigs/BeatsStudioPro.js';
import BeatsX from './deviceConfigs/BeatsX.js';
import Powerbeats3 from './deviceConfigs/Powerbeats3.js';
import Powerbeats4 from './deviceConfigs/Powerbeats4.js';
import PowerbeatsPro from './deviceConfigs/PowerbeatsPro.js';
import PowerbeatsPro2 from './deviceConfigs/PowerbeatsPro2.js';
import PowerbeatsFit from './deviceConfigs/PowerbeatsFit.js';

export const AirpodsModelList = [
    AirPods1stGen,
    AirPods2ndGen,
    AirPods3rdGen,
    AirPods4thGen,
    AirPods4thGenANC,
    AirPodsMax,
    AirPodsMax2,
    AirPodsMaxUsbC,
    AirPodsPro,
    AirPodsPro2ndGen,
    AirPodsPro2ndGenUsbC,
    AirPodsPro3rdGen,
    BeatsFitPro,
    BeatsFlex,
    BeatsSolo3,
    BeatsSolo4,
    BeatsSoloBuds,
    BeatsSoloPro,
    BeatsStudio3,
    BeatsStudioBuds,
    BeatsStudioBudsPlus,
    BeatsStudioPro,
    BeatsX,
    Powerbeats3,
    Powerbeats4,
    PowerbeatsPro,
    PowerbeatsPro2,
    PowerbeatsFit,
];


export const BatteryType = {
    SINGLE: 0x01,
    RIGHT: 0x02,
    LEFT: 0x04,
    CASE: 0x08,
};

export const BatteryChargingStatus = {
    CHARGING: 0x01,
    DISCHARGING: 0x02,
    DISCONNECTED: 0x04,
};

export const EarDetection = {
    IN_EAR: 0x00,
    OUT_EAR: 0x01,
    IN_CASE: 0x02,
};

export const ANCMode = {
    ANC_OFF: 0x01,
    ANC_ON: 0x02,
    TRANSPARENCY: 0x03,
    ADAPTIVE: 0x04,
};

export const LongPressBits = {
    off: 0x01,
    anc: 0x02,
    transparency: 0x04,
    adaptive: 0x08,
};

export const AwarenessMode = {
    ON: 0x01,
    OFF: 0x02,
};

export const PressSpeedMode = {
    DEFAULT: 0x00,
    SLOWER: 0x01,
    SLOWEST: 0x02,
};

export const PressDurationMode = {
    DEFAULT: 0x00,
    SHORTER: 0x01,
    SHORTEST: 0x02,
};

export const VolSwipeLength = {
    DEFAULT: 0x00,
    LONGER: 0x01,
    LONGEST: 0x02,
};

export const VolSwipeMode = {
    ON: 0x01,
    OFF: 0x02,
};

export const PacketConstants = {
    SETTINGS: [0x09, 0x00],
    PREFIX: [0x04, 0x00, 0x04, 0x00],
    SUFFIX: [0x00, 0x00, 0x00],

    HANDSHAKE: Uint8Array.from([
        0x00, 0x00, 0x04, 0x00, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
    ]),

    SET_SPECIFIC_FEATURES: Uint8Array.from([
        0x04, 0x00, 0x04, 0x00, 0x4d, 0x00, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ]),

    REQUEST_NOTIFICATIONS: Uint8Array.from([
        0x04, 0x00, 0x04, 0x00, 0x0f, 0x00, 0xff, 0xff, 0xff, 0xff,
    ]),

    HANDSHAKE_ACK: Uint8Array.from([
        0x01, 0x00, 0x04, 0x00,
    ]),

    FEATURES_ACK: Uint8Array.from([
        0x04, 0x00, 0x04, 0x00, 0x2b, 0x00,
    ]),

    BATTERY_STATUS_NOTIFICATION: Uint8Array.from([
        0x04, 0x00, 0x04, 0x00, 0x04, 0x00,
    ]),

    CONVERSATION_AWARENESS_DATA: Uint8Array.from([
        0x04, 0x00, 0x04, 0x00, 0x4b, 0x00, 0x02, 0x00, 0x01,
    ]),

    EAR_DETECTION_PREFIX: Uint8Array.from([
        0x04, 0x00, 0x04, 0x00, 0x06, 0x00,
    ]),

    ADAPTIVE_CONTROL_HEADER: Uint8Array.from([
        0x04, 0x00, 0x04, 0x00, 0x09, 0x00, 0x2e,
    ]),

    CASE_SOUND_HEADER: Uint8Array.from([
        0x12, 0x3a, 0x00, 0x01, 0x01, 0x08,
    ]),

};

PacketConstants.NOISE_CANCELLATION_HEADER = Uint8Array.from([
    ...PacketConstants.PREFIX, ...PacketConstants.SETTINGS, 0x0d,
]);

PacketConstants.NOISE_CANCELLATION_OFF = Uint8Array.from([
    ...PacketConstants.NOISE_CANCELLATION_HEADER, 0x01, ...PacketConstants.SUFFIX,
]);

PacketConstants.NOISE_CANCELLATION_ON = Uint8Array.from([
    ...PacketConstants.NOISE_CANCELLATION_HEADER, 0x02, ...PacketConstants.SUFFIX,
]);

PacketConstants.NOISE_CANCELLATION_TRANSPARENCY = Uint8Array.from([
    ...PacketConstants.NOISE_CANCELLATION_HEADER, 0x03, ...PacketConstants.SUFFIX,
]);

PacketConstants.NOISE_CANCELLATION_ADAPTIVE = Uint8Array.from([
    ...PacketConstants.NOISE_CANCELLATION_HEADER, 0x04, ...PacketConstants.SUFFIX,
]);

PacketConstants.CONVERSATION_AWARENESS_HEADER = Uint8Array.from([
    ...PacketConstants.PREFIX, ...PacketConstants.SETTINGS, 0x28,
]);

PacketConstants.CONVERSATION_AWARENESS_OFF = Uint8Array.from([
    ...PacketConstants.CONVERSATION_AWARENESS_HEADER, 0x02, ...PacketConstants.SUFFIX,
]);

PacketConstants.CONVERSATION_AWARENESS_ON = Uint8Array.from([
    ...PacketConstants.CONVERSATION_AWARENESS_HEADER, 0x01, ...PacketConstants.SUFFIX,
]);

PacketConstants.PRESS_SPEED_HEADER = Uint8Array.from([
    ...PacketConstants.PREFIX, ...PacketConstants.SETTINGS, 0x17,
]);

PacketConstants.PRESS_AND_HOLD_DURATION_HEADER = Uint8Array.from([
    ...PacketConstants.PREFIX, ...PacketConstants.SETTINGS, 0x18,
]);

PacketConstants.VOL_SWIPE_MODE_HEADER = Uint8Array.from([
    ...PacketConstants.PREFIX, ...PacketConstants.SETTINGS, 0x25,
]);

PacketConstants.VOL_SWIPE_LENGHT_HEADER = Uint8Array.from([
    ...PacketConstants.PREFIX, ...PacketConstants.SETTINGS, 0x23,
]);

PacketConstants.NOTI_VOLUME_HEADER = Uint8Array.from([
    ...PacketConstants.PREFIX, ...PacketConstants.SETTINGS, 0x1f,
]);

PacketConstants.LONGPRESS_CYCLE_HEADER = Uint8Array.from([
    ...PacketConstants.PREFIX, ...PacketConstants.SETTINGS, 0x1a,
]);

PacketConstants.LISTENING_MODE_HEADER = Uint8Array.from([
    ...PacketConstants.PREFIX, ...PacketConstants.SETTINGS, 0x34,
]);

