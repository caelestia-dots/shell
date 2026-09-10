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
}
