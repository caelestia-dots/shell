pragma Singleton

import QtQuick
import Caelestia
import Caelestia.Scheme

ColoursImpl {
    function layer(colour: color, layer: int): color {
        CUtils.dependency(__layerNeedsUpdate);
        return _layer(colour, layer);
    }
}
