'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

const BUS_NAME = 'org.bbm';
const OBJECT_PATH = '/org/bbm';
const INTERFACE_NAME = 'org.bbm.Manager';

const INTERFACE_XML = `
<node>
  <interface name="org.bbm.Manager">
    <method name="GetDevices">
      <arg type="as" direction="out" name="addresses"/>
    </method>
    <method name="GetDeviceData">
      <arg type="s" direction="in" name="address"/>
      <arg type="a{sv}" direction="out" name="data"/>
    </method>
    <method name="SendUIAction">
      <arg type="s" direction="in" name="address"/>
      <arg type="s" direction="in" name="widgetId"/>
      <arg type="i" direction="in" name="value"/>
    </method>
    <method name="GetIconPath">
      <arg type="s" direction="out" name="path"/>
    </method>
    <signal name="DeviceAdded">
      <arg type="s" name="address"/>
    </signal>
    <signal name="DeviceRemoved">
      <arg type="s" name="address"/>
    </signal>
    <signal name="DeviceChanged">
      <arg type="s" name="address"/>
    </signal>
  </interface>
</node>`;

/**
 * Owns the org.bbm bus name on the session bus and serves the Manager interface.
 * All D-Bus clients see only DeviceRecords — never protocol objects or DataHandlers.
 */
export class DbusService {
    constructor(iconBasePath = '') {
        this._iconBasePath = iconBasePath;
        // Map<address, {record, dataHandler}>
        this._devices = new Map();
        this._sessionBus = null;
        this._busNameId = null;
        this._registrationId = null;
        this._connection = null;
        this._nodeInfo = Gio.DBusNodeInfo.new_for_xml(INTERFACE_XML);
    }

    start() {
        return new Promise((resolve, reject) => {
            this._busNameId = Gio.bus_own_name(
                Gio.BusType.SESSION,
                BUS_NAME,
                Gio.BusNameOwnerFlags.NONE,
                (conn) => {
                    this._connection = conn;
                    try {
                        this._registrationId = conn.register_object(
                            OBJECT_PATH,
                            this._nodeInfo.interfaces[0],
                            this._handleMethodCall.bind(this),
                            null, // get_property
                            null  // set_property
                        );
                        console.log('BBM: D-Bus service registered at', OBJECT_PATH);
                        resolve();
                    } catch (e) {
                        reject(e);
                    }
                },
                null, // name_acquired (not needed; bus_acquired fires first)
                (conn, name) => {
                    console.warn('BBM: lost bus name:', name);
                }
            );
        });
    }

    // Called by orchestrator when a device's protocol handshake completes.
    addDevice(address, record, dataHandler) {
        this._devices.set(address, {record, dataHandler});
        this._emitSignal('DeviceAdded', new GLib.Variant('(s)', [address]));
    }

    // Called by orchestrator when a device disconnects/is removed.
    removeDevice(address) {
        this._devices.delete(address);
        this._emitSignal('DeviceRemoved', new GLib.Variant('(s)', [address]));
    }

    // Called by orchestrator whenever a DeviceRecord is updated.
    emitDeviceChanged(address) {
        this._emitSignal('DeviceChanged', new GLib.Variant('(s)', [address]));
    }

    _emitSignal(name, params) {
        if (!this._connection)
            return;
        try {
            this._connection.emit_signal(
                null, OBJECT_PATH, INTERFACE_NAME, name, params
            );
        } catch (e) {
            console.warn('BBM: failed to emit signal', name, e.message);
        }
    }

    _handleMethodCall(_conn, _sender, _path, _iface, method, params, invocation) {
        try {
            switch (method) {
            case 'GetDevices':
                this._handleGetDevices(invocation);
                break;
            case 'GetDeviceData':
                this._handleGetDeviceData(params.deepUnpack()[0], invocation);
                break;
            case 'SendUIAction': {
                const [address, widgetId, value] = params.deepUnpack();
                this._handleSendUIAction(address, widgetId, value, invocation);
                break;
            }
            case 'GetIconPath':
                invocation.return_value(new GLib.Variant('(s)', [this._iconBasePath]));
                break;
            default:
                invocation.return_error_literal(
                    Gio.DBusError,
                    Gio.DBusError.UNKNOWN_METHOD,
                    `Unknown method: ${method}`
                );
            }
        } catch (e) {
            invocation.return_error_literal(
                Gio.DBusError,
                Gio.DBusError.FAILED,
                e.message
            );
        }
    }

    _handleGetDevices(invocation) {
        const addresses = [...this._devices.keys()];
        invocation.return_value(new GLib.Variant('(as)', [addresses]));
    }

    _handleGetDeviceData(address, invocation) {
        const entry = this._devices.get(address);
        if (!entry) {
            invocation.return_value(new GLib.Variant('(a{sv})', [{}]));
            return;
        }
        const dict = this._buildDataDict(entry.record);
        invocation.return_value(new GLib.Variant('(a{sv})', [dict]));
    }

    _handleSendUIAction(address, widgetId, value, invocation) {
        const entry = this._devices.get(address);
        if (entry?.dataHandler)
            entry.dataHandler.emitUIAction(widgetId, value);
        invocation.return_value(null);
    }

    _buildDataDict(record) {
        const v = (type, val) => new GLib.Variant(type, val);
        const dict = {
            'Address':       v('s', record.address),
            'Alias':         v('s', record.alias),
            'Icon':          v('s', record.icon ?? ''),
            'Connected':     v('b', record.connected),
            'Paired':        v('b', record.paired),
            'ComputedLevel': v('i', record.computedLevel),
        };

        for (let i = 0; i < 3; i++) {
            const n = i + 1;
            const bat = record.batteries[i];
            dict[`Battery${n}Level`]  = v('i', bat.level);
            dict[`Battery${n}Status`] = v('s', bat.status);
            dict[`Battery${n}Icon`]   = v('s', bat.icon ?? '');
        }

        for (let t = 0; t < 2; t++) {
            const n = t + 1;
            const toggle = record.toggles[t];
            dict[`Toggle${n}Title`]       = v('s', toggle.title);
            dict[`Toggle${n}Buttons`]     = v('as', toggle.buttons);
            dict[`Toggle${n}ButtonIcons`] = v('as', toggle.buttonIcons);
            dict[`Toggle${n}State`]       = v('i', toggle.state);
            dict[`Toggle${n}Visible`]     = v('b', toggle.visible);
        }

        dict['AncLevelTitle']      = v('s', record.ancLevel.title);
        dict['AncLevelButtons']    = v('as', record.ancLevel.buttons);
        dict['AncLevelState']      = v('i', record.ancLevel.state);
        dict['OptionsBoxVisible']  = v('i', record.optionsBoxVisible);

        return dict;
    }

    destroy() {
        if (this._connection && this._registrationId) {
            this._connection.unregister_object(this._registrationId);
            this._registrationId = null;
        }
        if (this._busNameId) {
            Gio.bus_unown_name(this._busNameId);
            this._busNameId = null;
        }
        this._devices.clear();
        this._connection = null;
    }
}
