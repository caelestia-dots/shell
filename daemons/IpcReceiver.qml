import QtQuick
import Quickshell
import Caelestia.Ipc
import qs.components.annotation
import qs.components.filedialog
import qs.modules.overlays

Scope {
    id: root

    property PickRegionRequest regionRequest
    property ScreenshotRequest scRequest

    QtObject {
        id: dummy
    }

    IpcServer {
        onPickRegionRequested: req => {
            root.regionRequest = req;
            regionSelect.open = true;
        }

        onScreenshotRequested: req => {
            root.scRequest = req;
            capture.annotate = req.annotate;
            capture.region = req.region;
            capture.open = true;
        }

        onAnnotateRequested: req => {
            annotationComp.createObject(dummy, {
                request: req
            });
        }

        onPickFileRequested: req => {
            const props = {
                request: req,
                activeAsync: true
            };
            if (req.title)
                props.title = req.title;
            if (req.initialDir)
                props.initialDir = req.initialDir === "/" ? [""] : req.initialDir.split("/");
            if (req.initialName)
                props.initialName = req.initialName;
            if (req.nameFilters)
                props.nameFilters = req.nameFilters;
            if (req.filter)
                props.filters = req.filter;
            if (req.mode === PickFileMode.Save)
                props.save = true;

            fileDialogComp.createObject(dummy, props);
        }
    }

    RegionSelectOverlay {
        id: regionSelect

        onSelected: region => root.regionRequest?.respond(region)
        onCancelled: root.regionRequest?.reject()
    }

    Connections {
        function onCancelled(): void {
            regionSelect.open = false;
        }

        target: root.regionRequest
    }

    CaptureOverlay {
        id: capture

        onSaved: path => root.scRequest?.respond(path)
        onCopied: path => root.scRequest?.respondCopied(path)
        onFailed: root.scRequest?.reject(IpcError.Failed)
        onUnsupported: root.scRequest?.reject(IpcError.Failed)
        onCancelled: root.scRequest?.reject()
    }

    Connections {
        function onCancelled(): void {
            capture.open = false;
        }

        target: root.scRequest
    }

    Component {
        id: annotationComp

        AnnotationWindow {
            required property AnnotateRequest request

            file: request.file

            onSaved: path => {
                request.respond(path);
                destroy();
            }
            onCopied: path => {
                request.respondCopied(path);
                destroy();
            }
            onFailed: {
                request.reject(IpcError.Failed);
                destroy();
            }
            onCancelled: {
                request.reject();
                destroy();
            }
            Component.onCompleted: request.cancelled.connect(() => destroy())
        }
    }

    Component {
        id: fileDialogComp

        FileDialog {
            required property PickFileRequest request

            onAccepted: path => {
                request.respond(path);
                destroy();
            }
            onRejected: {
                request.reject();
                destroy();
            }
            Component.onCompleted: request.cancelled.connect(() => destroy())
        }
    }
}
