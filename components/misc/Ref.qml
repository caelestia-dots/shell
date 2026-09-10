import QtQuick

QtObject {
    required property var service

    Component.onCompleted: service.refCount++
    Component.onDestruction: service.refCount--
}
