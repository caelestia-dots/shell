pragma Singleton

import QtQuick
import Caelestia
import Caelestia.Scheme

ColoursImpl {
    enum Mode {
        Light,
        Dark
    }

    function layer(colour: color, layer: int): color {
        CUtils.dependency(__layerNeedsUpdate);
        return _layer(colour, layer);
    }
}
