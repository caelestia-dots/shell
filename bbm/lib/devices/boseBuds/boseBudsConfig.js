'use strict';

import QC35 from './deviceConfigs/QC35.js';
import QC35SE from './deviceConfigs/QC35SE.js';
import QCEarbuds2 from './deviceConfigs/QCEarbuds2.js';
import QCUltra2Earbuds from './deviceConfigs/QCUltra2Earbuds.js';
import QCUltra2Headphones from './deviceConfigs/QCUltra2Headphones.js';
import QCUltraEarbuds from './deviceConfigs/QCUltraEarbuds.js';
import QCUltraHeadphones from './deviceConfigs/QCUltraHeadphones.js';

export const BoseBudsModelList = [
    QC35,
    QC35SE,
    QCEarbuds2,
    QCUltra2Earbuds,
    QCUltra2Headphones,
    QCUltraEarbuds,
    QCUltraHeadphones,
];

export const Operator = {
    SET: 0x00,
    GET: 0x01,
    SETGET: 0x02,
    STATUS: 0x03,
    ERROR: 0x04,
    START: 0x05,
    RESULT: 0x06,
    PROCESSING: 0x07,
};

export const SourceType = {
    NONE: 0,
    BLUETOOTH: 1,
    AUXILIARY: 2,
};

export const CommandType = {
    INIT: 0x0001,
    FIRMWARE: 0x0005,
    SERIAL: 0x0007,
    PRODUCT_NAME: 0x0102,
    VOICE_PROMPTS: 0x0103,
    AUTO_POWER_OFF_TIME: 0x0104,
    CNC: 0x0105,
    ANR: 0x0106,
    EQ: 0x0107,
    BUTTONS: 0x0109,
    DUALCONNECTION: 0x010A,
    SIDETONE: 0x010B,
    INEAR_SETTINGS: 0x0110,
    AUTO_PAUSE: 0x0118,
    AUTO_ANSWER: 0x011B,
    AUTO_TRANSP: 0x011D,
    BATTERY: 0x0202,
    CHARGING_STATE: 0x0205,
    INEAR_STATE: 0x0209,
    CONNECT_DEVICE: 0x0401,
    DISCONNECT_DEVICE: 0x0402,
    REMOVE_DEVICE: 0x0403,
    GET_ALL_DEVICES: 0x0404,
    DEVICE_INFO: 0x0405,
    PAIRING_MODE: 0x0408,
    GET_OWN_DEVICE_ID: 0x0409,
    DEVICE_ROUTING: 0x040C,
    SOURCE: 0x0501,
    SPATIAL_AUDIO: 0x050F,
    POWER: 0x0704,
    NOTIFICATION_BY_BLOCK: 0x0902,
    AUDIOMODE_GETALL: 0x1F01,
    AUDIOMODE_CAPABILTY: 0x1F02,
    AUDIOMODE_CURRENT: 0x1F03,
    AUDIOMODE_DEFAULT: 0x1F04,
    AUDIOMODE_RESTORE: 0x1F05,
    AUDIOMODE_CONFIG: 0x1F06,
    AUDIOMODE_FAV: 0x1F08,
    AUDIO_SETTNGS: 0x1F0A,
};

export const BudId = {
    Single: 0x00,
    Right: 0x01,
    Left: 0x02,
    Case: 0x03,
};

export const AudioModes = {
    1: 'quiet',
    2: 'aware',
    34: 'immersion',
    36: 'cinema',
    7: 'commute',
    13: 'focus',
    10: 'home',
    12: 'music',
    8: 'outdoor',
    14: 'relax',
    20: 'run',
    21: 'walk',
    11: 'work',
    9: 'workout',
};

export const VoicePrompt = {
    0x00: 'English (UK)',
    0x01: 'English (US)',
    0x02: 'Français',
    0x03: 'Italiano',
    0x04: 'Deutsch',
    0x05: 'Español (EU)',
    0x06: 'Español (MX)',
    0x07: 'Português',
    0x08: '普通话 (Mandarin)',
    0x09: '한국어 (Korean)',
    0x0A: 'Русский (Russian)',
    0x0B: 'Polski',
    0x0C: 'עִברִית (Hebrew)',
    0x0D: 'Türk',
    0x0E: 'Nederlands',
    0x0F: '日本語 (Japanese)',
    0x10: '廣東話 (Cantonese)',
    0x11: 'العربية (Arabic)',
    0x12: 'Svensk',
    0x13: 'Dansk',
    0x14: 'Norsk',
    0x15: 'Suomen kieli (Finnish)',
    0x16: 'हिंदी (Hindi)',
};

