'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

const LOG_INFO = false;
const LOG_BYTES = false;

const LOG_DIR = GLib.build_filenamev([GLib.get_tmp_dir(), 'bluetooth_battery_meter']);
export const LOG_PATH = `${LOG_DIR}/service.log`;
const LOG_HISTORY_PATH = `${LOG_DIR}/service-history.log`;
const MAX_LOG_BYTES = 1024 * 1024;
const FULL_SANITIZE_LOG = true;

GLib.mkdir_with_parents(LOG_DIR, 0o755);

const logFile = Gio.File.new_for_path(LOG_PATH);
const historyFile = Gio.File.new_for_path(LOG_HISTORY_PATH);

function enforceLogSizeLimit() {
    try {
        const info = logFile.query_info('standard::size', Gio.FileQueryInfoFlags.NONE, null);
        if (info.get_size() >= MAX_LOG_BYTES) {
            if (historyFile.query_exists(null))
                historyFile.delete(null);

            logFile.move(historyFile, Gio.FileCopyFlags.OVERWRITE, null, null);
        }
    } catch {
        // Do nothing
    }
}

function WriteLogLine(prefix, msg) {
    enforceLogSizeLimit();
    const line = `[${new Date().toISOString()}] ${prefix}: ${msg}\n\n`;
    const stream = logFile.append_to(Gio.FileCreateFlags.NONE, null);
    const bytes = new GLib.Bytes(line);
    stream.write_bytes(bytes, null);
    stream.flush(null);
    stream.close(null);
}

export function createLogger(tag) {
    return {
        info: LOG_INFO
            ? (...args) => WriteLogLine('INF', `[${tag}] ${args.join(' ')}`)
            : () => {},
        error: (err, msg = '') => {
            const text = `${msg} ${err instanceof Error ? err.stack : String(err)}`.trim();
            WriteLogLine('ERR', `[${tag}] ${text}`);
        },
        bytes: LOG_BYTES
            ? (...args) => WriteLogLine('BYT', `[${tag}] ${args.join(' ')}`)
            : () => {},
    };
}

export function sanitizeDevPath(path) {
    return path.replace(
        /dev_(?:[0-9A-Fa-f]{2}_){5}([0-9A-Fa-f]{2})/,
        FULL_SANITIZE_LOG ? 'dev_XX_XX_XX_XX_XX_XX' : 'dev_XX_XX_XX_XX_XX_$1'
    );
}

export function getDeviceIdentifier(devicePath) {
    return FULL_SANITIZE_LOG ? 'XX' : devicePath.slice(-2);
}

export function hexBytes(value) {
    if (typeof value === 'number') {
        let hex = value.toString(16);

        if (hex.length % 2)
            hex = `0${hex}`;

        return `0x${hex}`;
    }

    if (Array.isArray(value) || ArrayBuffer.isView(value))
        return Array.from(value, b => b.toString(16).padStart(2, '0')).join(' ');

    return '';
}

