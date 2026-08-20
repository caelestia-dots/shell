'use strict';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';

import {createSettings} from './settings.js';
import {BluezEnumerator} from './bluezEnumerator.js';
import {DbusService} from './dbusService.js';
import {notifyProfileRegisteredError} from './notifier.js';
import {createDeviceRecord, updateRecordFromDataHandler} from './deviceRecord.js';
import {EnhancedDeviceSupportManager} from '../lib/enhancedDeviceSupportManager.js';

/**
 * Device lifecycle orchestrator.
 * Provides the duck-typed `toggle` interface that EnhancedDeviceSupportManager expects,
 * replacing the role played by BluetoothBatteryMeter (bluetoothToggle.js) in the extension.
 *
 * toggle interface consumed by EnhancedDeviceSupportManager:
 *   .settings, .extPath
 *   .airpodsEnabled, .sonyEnabled, .galaxyBudsEnabled, .nothingBudsEnabled,
 *   .googleBudsEnabled, .redmiBudsEnabled, .senhBudsEnabled, .boseBudsEnabled,
 *   .gfpsEnabled, .gattBasEnabled
 *   .notifyCb(type)
 *   .sync()
 */
export class Orchestrator {
    constructor(daemonDir) {
        this._daemonDir = daemonDir;

        // extPath is the root of the BBM installation — used by Device.js for icon lookups
        this._extPath = GLib.path_get_dirname(daemonDir);

        const schemaDir = GLib.build_filenamev([daemonDir, 'schemas']);
        this.settings = createSettings(schemaDir);

        // Expose the duck-typed toggle interface that EnhancedDeviceSupportManager reads
        this.extPath = this._extPath;
        this._loadEnabledFlags();

        // Callback for profile registration failures (replaces Notifier)
        this.notifyCb = notifyProfileRegisteredError;

        // address → {record, dataHandler, configChangedId, propsChangedId}
        this._addressMap = new Map();
        // bluezPath → address (for lookup on removal)
        this._pathToAddress = new Map();

        this._enumerator = null;
        this._dbusService = null;
        this._enhancedManager = null;

        this._syncRunning = false;
        this._syncPending = false;
    }

    _loadEnabledFlags() {
        this.airpodsEnabled = this.settings.get_boolean('enable-airpods-device');
        this.sonyEnabled = this.settings.get_boolean('enable-sony-device');
        this.galaxyBudsEnabled = this.settings.get_boolean('enable-galaxy-buds-device');
        this.nothingBudsEnabled = this.settings.get_boolean('enable-nothing-buds-device');
        this.googleBudsEnabled = this.settings.get_boolean('enable-google-buds-device');
        this.boseBudsEnabled = this.settings.get_boolean('enable-bose-buds-device');
        this.redmiBudsEnabled = this.settings.get_boolean('enable-redmi-buds-device');
        this.senhBudsEnabled = this.settings.get_boolean('enable-senh-buds-device');
        this.gfpsEnabled = this.settings.get_boolean('enable-gfps-device');
        this.gattBasEnabled = this.settings.get_boolean('enable-gattbas-device');
    }

    async start() {
        // D-Bus service acquires org.bbm bus name
        const iconBasePath = GLib.build_filenamev([this._extPath, 'icons', 'hicolor', 'scalable', 'actions']);
        this._dbusService = new DbusService(iconBasePath);
        await this._dbusService.start();

        // BlueZ enumerator replaces GnomeBluetooth.Client
        this._enumerator = new BluezEnumerator();
        this._enumerator.connect('device-added', (_e, path) => this._onDeviceAdded(path));
        this._enumerator.connect('device-removed', (_e, path) => this._onDeviceRemoved(path));
        this._enumerator.connect('device-lifecycle', (_e, path) => this.sync());
        this._enumerator.connect('device-changed', (_e, path) => {
            // Metadata-only change: update DeviceRecord if we track this device
            const address = this._pathToAddress.get(path);
            if (!address)
                return;
            const entry = this._addressMap.get(address);
            if (!entry)
                return;
            const info = this._enumerator.getDevices().get(path);
            if (info) {
                entry.record.alias = info.alias;
                entry.record.icon = info.icon;
                this._dbusService.emitDeviceChanged(address);
            }
        });

        // EnhancedDeviceSupportManager receives `this` as the `toggle` duck-type
        this._enhancedManager = new EnhancedDeviceSupportManager(this);

        // Initial sync over already-enumerated devices
        await this._enumerator.start();
        this.sync();

        console.log('BBM Daemon: started');
    }

    // Called by EnhancedDeviceSupportManager and BluezEnumerator on lifecycle events.
    sync() {
        if (this._syncRunning) {
            this._syncPending = true;
            return;
        }
        this._syncRunning = true;
        this._syncPending = false;

        for (const [path, info] of this._enumerator.getDevices()) {
            const result = this._enhancedManager.onDeviceSync(
                path, info.connected, info.icon, info.alias
            );
            // ESMD stores the dataHandler in its own map and calls toggle.sync();
            // we read it back from the return value here to announce to D-Bus clients.
            if (result?.dataHandler && !this._pathToAddress.has(path))
                this.updateDeviceMapCb(path, result.dataHandler);
        }
        this._enhancedManager.updateEnhancedDevicesInstance();

        this._syncRunning = false;
        if (this._syncPending)
            GLib.idle_add(GLib.PRIORITY_DEFAULT, () => { this.sync(); return GLib.SOURCE_REMOVE; });
    }

    /**
     * Called by EnhancedDeviceSupportManager when a device's protocol handshake
     * completes and a DataHandler is ready.
     * This is the moment we create the DeviceRecord and announce DeviceAdded.
     */
    updateDeviceMapCb(path, dataHandler) {
        if (this._pathToAddress.has(path))
            return; // Already announced; further updates come via configuration-changed signal

        const info = this._enumerator.getDevices().get(path);
        if (!info) {
            console.warn('BBM: updateDeviceMapCb called for unknown path:', path);
            return;
        }

        const {address, alias, icon, connected, paired} = info;

        // Create the canonical DeviceRecord
        const record = createDeviceRecord(address, alias, icon, connected, paired);
        updateRecordFromDataHandler(record, dataHandler);

        // Subscribe to DataHandler signals — update record and notify D-Bus clients
        const configId = dataHandler.connect('configuration-changed', () => {
            updateRecordFromDataHandler(record, dataHandler);
            this._dbusService.emitDeviceChanged(address);
        });
        const propsId = dataHandler.connect('properties-changed', () => {
            updateRecordFromDataHandler(record, dataHandler);
            this._dbusService.emitDeviceChanged(address);
        });

        this._addressMap.set(address, {record, dataHandler, configId, propsId});
        this._pathToAddress.set(path, address);

        // Announce to D-Bus clients
        this._dbusService.addDevice(address, record, dataHandler);

        // Trigger another sync so WidgetManagers (if any) are notified
        this.sync();
    }

    _onDeviceAdded(path) {
        // BlueZ enumeration found a new device — run sync to detect type
        this.sync();
    }

    _onDeviceRemoved(path) {
        const address = this._pathToAddress.get(path);
        if (address) {
            this._cleanupDevice(address, path);
        }
        this.sync();
    }

    _cleanupDevice(address, path) {
        const entry = this._addressMap.get(address);
        if (entry) {
            entry.dataHandler.disconnect(entry.configId);
            entry.dataHandler.disconnect(entry.propsId);
            this._addressMap.delete(address);
        }
        this._pathToAddress.delete(path);
        this._dbusService.removeDevice(address);
    }

    destroy() {
        if (this._enhancedManager) {
            this._enhancedManager.destroy();
            this._enhancedManager = null;
        }
        if (this._enumerator) {
            this._enumerator.destroy();
            this._enumerator = null;
        }
        if (this._dbusService) {
            this._dbusService.destroy();
            this._dbusService = null;
        }
        this._addressMap.clear();
        this._pathToAddress.clear();
    }
}
