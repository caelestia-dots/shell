import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent
    property bool locked: false

    signal detachRequested(mode: string)
}
