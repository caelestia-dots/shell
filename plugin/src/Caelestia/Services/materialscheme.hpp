#pragma once

#include <qjsvalue.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::services {

// Wallpaper colour previews, made in process from the CLI's cache and the applied scheme. Replaces
// running `caelestia wallpaper -p` for every wallpaper the pointer rests on.
class MaterialScheme : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit MaterialScheme(QObject* parent = nullptr);

    // Calls back with (json, error) once the colours are made. json is the preview's JSON (the
    // CLI's output), empty when it failed. Runs on a worker thread; the callback is on the UI thread.
    Q_INVOKABLE void previewColours(const QString& wallpaper, const QJSValue& callback);
};

} // namespace caelestia::services
