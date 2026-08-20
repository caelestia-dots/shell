'use strict';

import FlipBudsPro from './deviceConfigs/FlipBudsPro.js';
import RedmiAirDots3Pro from './deviceConfigs/RedmiAirDots3Pro.js';
import RedmiBuds3 from './deviceConfigs/RedmiBuds3.js';
import RedmiBuds3Pro from './deviceConfigs/RedmiBuds3Pro.js';
import RedmiBuds4 from './deviceConfigs/RedmiBuds4.js';
import RedmiBuds4Active from './deviceConfigs/RedmiBuds4Active.js';
import RedmiBuds4Pro from './deviceConfigs/RedmiBuds4Pro.js';
import RedmiBuds5 from './deviceConfigs/RedmiBuds5.js';
import RedmiBuds5Pro from './deviceConfigs/RedmiBuds5Pro.js';
import RedmiBuds6 from './deviceConfigs/RedmiBuds6.js';
import RedmiBuds6Active from './deviceConfigs/RedmiBuds6Active.js';
import RedmiBuds6Lite from './deviceConfigs/RedmiBuds6Lite.js';
import RedmiBuds6Play from './deviceConfigs/RedmiBuds6Play.js';
import RedmiBuds6Pro from './deviceConfigs/RedmiBuds6Pro.js';
import RedmiBuds6s from './deviceConfigs/RedmiBuds6s.js';
import RedmiBuds7s from './deviceConfigs/RedmiBuds7s.js';
import RedmiBuds8 from './deviceConfigs/RedmiBuds8.js';
import RedmiBuds8Active from './deviceConfigs/RedmiBuds8Active.js';
import RedmiBuds8Lite from './deviceConfigs/RedmiBuds8Lite.js';
import RedmiBuds8Pro from './deviceConfigs/RedmiBuds8Pro.js';
import RedmiBudsSE from './deviceConfigs/RedmiBudsSE.js';
import XiaomiAirSE from './deviceConfigs/XiaomiAirSE.js';
import XiaomiBuds3 from './deviceConfigs/XiaomiBuds3.js';
import XiaomiBuds3Pro from './deviceConfigs/XiaomiBuds3Pro.js';
import XiaomiBuds3TPro from './deviceConfigs/XiaomiBuds3TPro.js';
import XiaomiBuds4 from './deviceConfigs/XiaomiBuds4.js';
import XiaomiBuds4Pro from './deviceConfigs/XiaomiBuds4Pro.js';
import XiaomiBuds5 from './deviceConfigs/XiaomiBuds5.js';
import XiaomiBuds5Pro from './deviceConfigs/XiaomiBuds5Pro.js';
import XiaomiBuds6 from './deviceConfigs/XiaomiBuds6.js';
import XiaomiOpenWear from './deviceConfigs/XiaomiOpenWear.js';
import XiaomiOpenWearPro from './deviceConfigs/XiaomiOpenWearPro.js';

export const RedmiBudsModelList = [
    FlipBudsPro,
    RedmiAirDots3Pro,
    RedmiBuds3,
    RedmiBuds3Pro,
    RedmiBuds4,
    RedmiBuds4Active,
    RedmiBuds4Pro,
    RedmiBuds5,
    RedmiBuds5Pro,
    RedmiBuds6,
    RedmiBuds6Active,
    RedmiBuds6Lite,
    RedmiBuds6Play,
    RedmiBuds6Pro,
    RedmiBuds6s,
    RedmiBuds7s,
    RedmiBuds8,
    RedmiBuds8Active,
    RedmiBuds8Lite,
    RedmiBuds8Pro,
    RedmiBudsSE,
    XiaomiAirSE,
    XiaomiBuds3,
    XiaomiBuds3Pro,
    XiaomiBuds3TPro,
    XiaomiBuds4,
    XiaomiBuds4Pro,
    XiaomiBuds5,
    XiaomiBuds5Pro,
    XiaomiBuds6,
    XiaomiOpenWear,
    XiaomiOpenWearPro,
];

export const MessageType = {
    PHONE_REQUEST: 0xC4,
    RESPONSE: 0x04,
    EARBUDS_REQUEST: 0xC0,
    EARBUDS_RESPONSE: 0x07,
    EARBUDS_NOTIFY: 0xC7,
    UNKNOWN: 0xFF,
};

export const Opcode = {
    GET_DEVICE_INFO: 0x02,
    SET_DEVICE_INFO: 0x08,
    GET_DEVICE_RUN_INFO: 0x09,
    REPORT_STATUS: 0x0E,
    AUTH_CHALLENGE: 0x50,
    AUTH_CONFIRM: 0x51,
    SET_CONFIG: 0xF2,
    GET_CONFIG: 0xF3,
    NOTIFY_CONFIG: 0xF4,
    UNKNOWN: 0xFF,
};

export const ConfigType = {
    SERIAL_NUMBER: 0x27,
    GESTURES: 0x02,
    AUTO_ANSWER: 0x03,
    DOUBLE_CONNECTION: 0x04,
    EQ_PRESET: 0x07,
    RING_MY_BUDS: 0x09,
    LONG_GESTURES: 0x0A,
    ANC: 0x0B,
    ADAPTIVE_ANC: 0x25,
    LOW_LATENCY: 0x2F,
    ADAPTIVE_SOUND: 0x29,
    EQ_CURVE: 0x37,
    PERSONALIZE_ANC: 0x3B,
    ADAPTIVE_VOLUME: 0x48,
    SPATIAL_AUDIO: 0x4F,
    UNKNOWN: 0xFF,
};

export const DeviceInfoRetType = {
    FIRMWARE: 0x01,
    VID_PID: 0x03,
    BATTERY: 0x07,
};

