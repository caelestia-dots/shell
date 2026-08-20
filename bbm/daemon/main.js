#!/usr/bin/env -S gjs -m
'use strict';
import GLib from 'gi://GLib';
import GLibUnix from 'gi://GLibUnix';
import Gio from 'gi://Gio';

// Promisify async GIO methods used throughout lib/ (mirrors what extension.js does at startup)
Gio._promisify(Gio.DBusProxy, 'new');
Gio._promisify(Gio.DBusProxy, 'new_for_bus');
Gio._promisify(Gio.DBusProxy.prototype, 'call');
Gio._promisify(Gio.DBusConnection.prototype, 'call');
Gio._promisify(Gio.InputStream.prototype, 'read_bytes_async');
Gio._promisify(Gio.OutputStream.prototype, 'write_all_async');

import {Orchestrator} from './orchestrator.js';

// import.meta.url is a file:// URI in GJS; GLib.filename_from_uri converts it to a path
const daemonDir = GLib.path_get_dirname(GLib.filename_from_uri(import.meta.url)[0]);

const loop = new GLib.MainLoop(null, false);
const orchestrator = new Orchestrator(daemonDir);

orchestrator.start().catch(e => {
    console.error('BBM Daemon: failed to start:', e.message, e.stack ?? '');
    loop.quit();
});

GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, 15 /* SIGTERM */, () => {
    console.log('BBM Daemon: shutting down');
    orchestrator.destroy();
    loop.quit();
    return GLib.SOURCE_REMOVE;
});

GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, 2 /* SIGINT */, () => {
    console.log('BBM Daemon: interrupted');
    orchestrator.destroy();
    loop.quit();
    return GLib.SOURCE_REMOVE;
});

loop.run();
