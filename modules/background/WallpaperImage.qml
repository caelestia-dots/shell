import QtQuick
import qs.components.images

CachingImage {
    readonly property bool ready: status === Image.Ready
}
