import QtQuick

Item {
    property alias visibilities: media.visibilities
    readonly property alias needsKeyboard: media.needsKeyboard

    implicitWidth: media.implicitWidth
    implicitHeight: media.nonAnimHeight

    Media {
        id: media
    }
}
