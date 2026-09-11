pragma Singleton

import QtQuick
import Caelestia.Config
import Caelestia.I18n

QtObject {
    // Converts a temperature in Celsius to the given TemperatureUnit
    function toTemperature(celsius: real, unit: int): real {
        if (Number(unit) === TemperatureUnit.Fahrenheit)
            return celsius * 9 / 5 + 32;
        if (Number(unit) === TemperatureUnit.Kelvin)
            return celsius + 273.15;
        return celsius;
    }

    // Formats an already converted temperature with the given TemperatureUnit's suffix
    function formatTemp(value: var, unit: int, compact = false): string {
        if (compact)
            return Number(unit) === TemperatureUnit.Kelvin ? String(value) : Tr.trCtx("%1°", "temperature").arg(value);

        if (Number(unit) === TemperatureUnit.Fahrenheit)
            return Tr.trCtx("%1°F", "temperature").arg(value);
        if (Number(unit) === TemperatureUnit.Kelvin)
            return Tr.trCtx("%1 K", "temperature").arg(value);
        return Tr.trCtx("%1°C", "temperature").arg(value);
    }

    // Converts and formats a sensor temperature given in Celsius
    function formatSensorTemp(celsius: real): string {
        const unit = GlobalConfig.services.sensorUnits;
        return formatTemp(Math.round(toTemperature(celsius, unit)), unit);
    }

    // Formats an already scaled value with the given data unit suffix
    function withDataUnit(value: var, unit: string): string {
        const formats = {
            "B": Tr.tr("%1 B"),
            "KB": Tr.tr("%1 KB"),
            "MB": Tr.tr("%1 MB"),
            "GB": Tr.tr("%1 GB"),
            "TB": Tr.tr("%1 TB"),
            "KiB": Tr.tr("%1 KiB"),
            "MiB": Tr.tr("%1 MiB"),
            "GiB": Tr.tr("%1 GiB"),
            "TiB": Tr.tr("%1 TiB"),
            "B/s": Tr.tr("%1 B/s"),
            "KB/s": Tr.tr("%1 KB/s"),
            "MB/s": Tr.tr("%1 MB/s"),
            "GB/s": Tr.tr("%1 GB/s"),
            "TB/s": Tr.tr("%1 TB/s"),
            "KiB/s": Tr.tr("%1 KiB/s"),
            "MiB/s": Tr.tr("%1 MiB/s"),
            "GiB/s": Tr.tr("%1 GiB/s"),
            "TiB/s": Tr.tr("%1 TiB/s")
        };
        return (formats[unit] ?? ("%1 " + unit)).arg(value);
    }

    function _scaleBytes(bytes: real, refBytes: real): var {
        const binary = Number(GlobalConfig.services.dataUnits) === DataUnit.Binary;
        const units = binary ? ["B", "KiB", "MiB", "GiB", "TiB"] : ["B", "KB", "MB", "GB", "TB"];
        const k = binary ? 1024 : 1000;

        let value = isFinite(bytes) && bytes > 0 ? bytes : 0;
        let ref = isFinite(refBytes) && refBytes > 0 ? refBytes : 0;
        let i = 0;
        while (ref >= k && i < units.length - 1) {
            value /= k;
            ref /= k;
            i++;
        }

        return {
            value,
            unit: units[i]
        };
    }

    // Scales and formats a raw byte count
    function formatBytes(bytes: real, rate = false): string {
        const s = _scaleBytes(bytes, bytes);
        return withDataUnit(s.value.toFixed(s.value < 10 && s.unit !== "B" ? 1 : 0), s.unit + (rate ? "/s" : ""));
    }

    // Formats a used/total pair given in KiB, both scaled to the total's magnitude
    function formatKibUsage(usedKib: real, totalKib: real): string {
        const refBytes = totalKib * 1024;
        const used = _scaleBytes(usedKib * 1024, refBytes);
        const total = _scaleBytes(refBytes, refBytes);
        // TRANSLATORS: %1 = used amount, %2 = total amount with unit
        return Tr.trCtx("%1 / %2", "used / total amount").arg(+used.value.toFixed(1)).arg(withDataUnit(+total.value.toFixed(1), total.unit));
    }
}
