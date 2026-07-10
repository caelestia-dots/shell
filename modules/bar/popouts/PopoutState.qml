import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent
    // The access point a credentials popout was opened for. It has to live here
    // rather than on the network popout, whose Loader unloads as soon as the
    // dialog becomes the current popout.
    property var pendingNetwork: null

    signal detachRequested(mode: string)
}
