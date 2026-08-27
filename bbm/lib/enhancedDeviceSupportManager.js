'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

import {getBluezDeviceProxy} from './bluezDeviceProxy.js';
import {createLogger, sanitizeDevPath} from './devices/logger.js';

import {ProfileManager} from './devices/profileManager.js';
import {AirpodsDevice, isAirpods, DeviceTypeAirpods} from './devices/airpods/airpodsDevice.js';
import {
    SonyDevice, isSonyV1, isSonyV2, DeviceTypeSonyV1, DeviceTypeSonyV2
} from './devices/sony/sonyDevice.js';
import {
    GalaxyBudsDevice, isGalaxyLegacy, isGalaxyBuds, DeviceTypeGalaxyLegacy, DeviceTypeGalaxyBuds
} from './devices/galaxyBuds/galaxyBudsDevice.js';
import {
    NothingBudsDevice, isNothingBuds, DeviceTypeNothingBuds
} from './devices/nothingBuds/nothingBudsDevice.js';
import {
    GoogleBudsDevice, isGoogleBuds, DeviceTypeGoogleBuds
} from './devices/googleBuds/googleBudsDevice.js';
import {
    RedmiBudsDevice, isRedmiBuds, DeviceTypeRedmiBuds
} from './devices/redmiBuds/redmiBudsDevice.js';
import {
    SenhBudsDevice, isSenhBuds, DeviceTypeSenhBuds
} from './devices/senhBuds/senhBudsDevice.js';
import {
    BoseBudsDevice, isBoseBuds, DeviceTypeBoseBuds
} from './devices/boseBuds/boseBudsDevice.js';
import {GfpsDevice, isGfps, DeviceTypeGfps} from './devices/gfps/gfpsDevice.js';
import {GattBasDevices, isGattBas, DeviceTypeGattBas} from './devices/gattBas/gattBasDevices.js';

export const EnhancedDeviceSupportManager = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_EnhancedDeviceSupportManager',
}, class EnhancedDeviceSupportManager extends GObject.Object {
    _init(toggle) {
        super._init();
        this._toggle = toggle;
        this._settings = toggle.settings;
        this._extPath = toggle.extPath;
        this._deviceMap = new Map();
        this._log = createLogger('EnhancedDeviceSupportManager');
        this._profileManager = new ProfileManager(this._notifyCb.bind(this));
    }

    _notifyCb(type) {
        this._toggle.notifyCb?.(type);
    }

    updateDeviceMapCb(path, dataHandler) {
        if (this._deviceMap.has(path)) {
            const deviceProps = this._deviceMap.get(path);
            deviceProps.dataHandler = dataHandler;
            this._deviceMap.set(path, deviceProps);
            this._toggle.sync();
        }
    }

    onDeviceSync(path, connected, icon, alias) {
        let deviceProps = this._deviceMap.get(path);
        if (!deviceProps) {
            deviceProps = {
                type: null, connected, dataHandler: null, deviceIcon: icon,
                enhancedDevice: null, pendingDetection: true, bluezId: null,
                bluezProxy: null, alias,
            };
            this._deviceMap.set(path, deviceProps);
        } else {
            deviceProps = this._deviceMap.get(path);
            if (deviceProps.connected && !connected)
                this._destroyEnhancedDevice(path);

            deviceProps.connected = connected;
        }

        if (deviceProps.pendingDetection) {
            const bluezDeviceProxy = getBluezDeviceProxy(path);
            const uuids = bluezDeviceProxy.UUIDs ?? [];

            if (uuids.length === 0) {
                this._log.info(`Detection pending path=${sanitizeDevPath(path)} waitingFor=UUIDs`);
                deviceProps.pendingDetection = true;
                this._waitForBluezProps(path, bluezDeviceProxy, ['UUIDs'], deviceProps);
                return {
                    type: deviceProps.type, dataHandler: deviceProps.dataHandler,
                    pendingDetection: deviceProps.pendingDetection,
                };
            }

            /* ----- Add device variant here _______ */
            const deviceModes = [
                {
                    enabled: this._toggle.airpodsEnabled,
                    check: isAirpods,
                    type: DeviceTypeAirpods,
                },
                {
                    enabled: this._toggle.sonyEnabled,
                    check: isSonyV1,
                    type: DeviceTypeSonyV1,
                },
                {
                    enabled: this._toggle.sonyEnabled,
                    check: isSonyV2,
                    type: DeviceTypeSonyV2,
                },
                {
                    enabled: this._toggle.galaxyBudsEnabled,
                    check: isGalaxyLegacy,
                    type: DeviceTypeGalaxyLegacy,
                },
                {
                    enabled: this._toggle.galaxyBudsEnabled,
                    check: isGalaxyBuds,
                    type: DeviceTypeGalaxyBuds,
                },
                {
                    enabled: this._toggle.nothingBudsEnabled,
                    check: isNothingBuds,
                    type: DeviceTypeNothingBuds,
                },
                {
                    enabled: this._toggle.googleBudsEnabled,
                    check: isGoogleBuds,
                    type: DeviceTypeGoogleBuds,
                },
                {
                    enabled: this._toggle.redmiBudsEnabled,
                    check: isRedmiBuds,
                    type: DeviceTypeRedmiBuds,
                },
                {
                    enabled: this._toggle.senhBudsEnabled,
                    check: isSenhBuds,
                    type: DeviceTypeSenhBuds,
                },
                {
                    enabled: this._toggle.boseBudsEnabled,
                    check: isBoseBuds,
                    type: DeviceTypeBoseBuds,
                },
                {
                    enabled: this._toggle.gfpsEnabled,
                    check: isGfps,
                    type: DeviceTypeGfps,
                },
                {
                    enabled: this._toggle.gattBasEnabled,
                    check: isGattBas,
                    type: DeviceTypeGattBas,
                },
            ];
            /* ------------------------------------- */
            for (const mode of deviceModes) {
                if (!mode.enabled)
                    continue;

                const {supported, bluezProps} = mode.check(bluezDeviceProxy, uuids);

                if (supported === 'pending') {
                    this._log.info(
                        `Detection pending path=${sanitizeDevPath(path)} type=${mode.type} ` +
                        `waitingFor=${bluezProps.join(',')}`
                    );
                    deviceProps.pendingDetection = true;
                    this._waitForBluezProps(path, bluezDeviceProxy, bluezProps, deviceProps);
                    break;
                }

                if (supported === 'yes') {
                    deviceProps.type = mode.type;
                    deviceProps.pendingDetection = false;
                    break;
                }
                deviceProps.pendingDetection = false;
            }
        }
        return {
            type: deviceProps.type, dataHandler: deviceProps.dataHandler,
            pendingDetection: deviceProps.pendingDetection,
        };
    }

    _waitForBluezProps(path, bluezDeviceProxy, bluezProps, deviceProps) {
        if (deviceProps.bluezId && deviceProps.bluezDeviceProxy)
            return;

        const allPropsReady = () => {
            return bluezProps.every(prop => {
                const value = bluezDeviceProxy[prop];
                if (Array.isArray(value))
                    return value.length > 0;

                return value !== null && value !== undefined;
            });
        };

        const onPropsChanged = (_iface, changed, _invalidated) => {
            if (!bluezProps.some(prop => prop in changed))
                return;

            if (allPropsReady()) {
                this._log.info(
                    `Pending detection properties ready path=${sanitizeDevPath(path)} ` +
                    `props=${bluezProps.join(',')}`
                );
                if (this._deviceMap.has(path)) {
                    const props = this._deviceMap.get(path);
                    props.bluezDeviceProxy.disconnect(deviceProps.bluezId);
                    props.bluezId = null;
                    props.bluezDeviceProxy = null;
                } else {
                    deviceProps.bluezDeviceProxy.disconnect(deviceProps.bluezId);
                    deviceProps.bluezId = null;
                    deviceProps.bluezDeviceProxy = null;
                }
                this._toggle.sync();
            }
        };

        deviceProps.bluezId = bluezDeviceProxy.connect('g-properties-changed', onPropsChanged);
        deviceProps.bluezDeviceProxy = bluezDeviceProxy;
    }


    updateEnhancedDevicesInstance() {
        for (const [path, deviceProps] of this._deviceMap.entries()) {
            if (deviceProps.type && deviceProps.connected && !deviceProps.enhancedDevice) {
                this._log.info(
                    `Creating enhanced device path=${sanitizeDevPath(path)} ` +
                    `type=${deviceProps.type}`
                );
                /* ----- Add device variant here _______ */
                if (deviceProps.type === DeviceTypeAirpods) {
                    deviceProps.enhancedDevice =
                        new AirpodsDevice(this._settings, path, deviceProps.alias, this._extPath,
                            this._profileManager, this.updateDeviceMapCb.bind(this));
                } else if (deviceProps.type === DeviceTypeSonyV1 ||
                        deviceProps.type === DeviceTypeSonyV2) {
                    deviceProps.enhancedDevice =
                        new SonyDevice(this._settings, path, deviceProps.alias, this._extPath,
                            this._profileManager, this.updateDeviceMapCb.bind(this));
                } else if (deviceProps.type === DeviceTypeGalaxyBuds ||
                        deviceProps.type === DeviceTypeGalaxyLegacy) {
                    deviceProps.enhancedDevice =
                        new GalaxyBudsDevice(this._settings, path, deviceProps.alias,
                            this._extPath, this._profileManager,
                            this.updateDeviceMapCb.bind(this));
                } else if (deviceProps.type === DeviceTypeNothingBuds) {
                    deviceProps.enhancedDevice =
                        new NothingBudsDevice(this._settings, path, deviceProps.alias,
                            this._extPath, this._profileManager,
                            this.updateDeviceMapCb.bind(this));
                } else if (deviceProps.type === DeviceTypeGoogleBuds) {
                    deviceProps.enhancedDevice =
                        new GoogleBudsDevice(this._settings, path, deviceProps.alias,
                            this._extPath, this._profileManager,
                            this.updateDeviceMapCb.bind(this));
                } else if (deviceProps.type === DeviceTypeRedmiBuds) {
                    deviceProps.enhancedDevice =
                        new RedmiBudsDevice(this._settings, path, deviceProps.alias,
                            this._extPath, this._profileManager,
                            this.updateDeviceMapCb.bind(this));
                } else if (deviceProps.type === DeviceTypeSenhBuds) {
                    deviceProps.enhancedDevice =
                        new SenhBudsDevice(this._settings, path, deviceProps.alias,
                            this._extPath, this._profileManager,
                            this.updateDeviceMapCb.bind(this));
                } else if (deviceProps.type === DeviceTypeBoseBuds) {
                    deviceProps.enhancedDevice =
                        new BoseBudsDevice(this._settings, path, deviceProps.alias,
                            this._extPath, this._profileManager,
                            this.updateDeviceMapCb.bind(this));
                } else if (deviceProps.type === DeviceTypeGfps) {
                    deviceProps.enhancedDevice =
                        new GfpsDevice(this._settings, path, deviceProps.alias,
                            this._extPath, this._profileManager,
                            this.updateDeviceMapCb.bind(this));
                } else if (deviceProps.type === DeviceTypeGattBas) {
                    deviceProps.enhancedDevice =
                        new GattBasDevices(this._settings, path, deviceProps.deviceIcon,
                            this.updateDeviceMapCb.bind(this));
                }
                /* ------------------------------------- */
            } else if (!deviceProps.connected && deviceProps.enhancedDevice) {
                this._destroyEnhancedDevice(path);
            }
        }
    }

    _ensureFileCopied(sourcePath, targetPath) {
        const source = Gio.File.new_for_path(sourcePath);
        const target = Gio.File.new_for_path(targetPath);

        try {
            if (target.query_exists(null)) {
                const fileType =
                    target.query_file_type(Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
                if (fileType === Gio.FileType.SYMBOLIC_LINK) {
                    // Removing previously installed symlink
                    target.delete(null);
                } else {
                    return;
                }
            }

            source.copy(target, Gio.FileCopyFlags.NONE, null, null);
        } catch {
            // Do nothing
        }
    }

    _createDesktopIconFiles() {
        const homeDir = GLib.get_home_dir();
        const appDir = `${homeDir}/.local/share/applications`;
        const iconDir = `${homeDir}/.local/share/icons`;
        const sourceDesktopFile = `${this._extPath}/script/moreSettings.desktop`;
        const targetDesktopFile =
            `${appDir}/com.github.maniacx.Bluetooth-Battery-Meter-More-Settings.desktop`;

        const sourceIconFile = `${this._extPath}/icons/hicolor/scalable/actions/bbm-logo.svg`;
        const targetIconFile = `${iconDir}/bluetooth-battery-meter-maniacx-github-logo.svg`;
        GLib.mkdir_with_parents(appDir, 0o755);
        GLib.mkdir_with_parents(iconDir, 0o755);
        this._ensureFileCopied(sourceDesktopFile, targetDesktopFile);
        this._ensureFileCopied(sourceIconFile, targetIconFile);
    }

    _destroyEnhancedDevice(path) {
        if (!this._deviceMap.has(path))
            return;

        const deviceProps = this._deviceMap.get(path);

        if (deviceProps.bluezId && deviceProps.bluezDeviceProxy) {
            deviceProps.bluezDeviceProxy.disconnect(deviceProps.bluezId);
            deviceProps.bluezDeviceProxy = null;
            deviceProps.bluezId = null;
        }

        deviceProps.dataHandler = null;
        deviceProps.enhancedDevice?.destroy();
        deviceProps.enhancedDevice = null;
    }

    _removedEnhancedDevice(path) {
        if (!this._deviceMap.has(path))
            return;

        this._destroyEnhancedDevice(path);
        this._deviceMap.delete(path);
    }

    destroy() {
        const paths = Array.from(this._deviceMap.keys());
        for (const path of paths)
            this._removedEnhancedDevice(path);

        this._profileManager = null;
    }
});
