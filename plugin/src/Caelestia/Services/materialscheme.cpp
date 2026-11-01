#include "materialscheme.hpp"

#include <qbytearray.h>
#include <qfuturewatcher.h>
#include <qstring.h>
#include <qtconcurrentrun.h>

#include "../Material/preview.hpp"

namespace caelestia::services {

namespace {

struct PreviewResult {
    QByteArray json;
    QString error;
};

} // namespace

MaterialScheme::MaterialScheme(QObject* parent)
    : QObject(parent) {}

void MaterialScheme::previewColours(const QString& wallpaper, const QJSValue& callback) {
    // The applied scheme is a small file, so it's read here rather than on the worker
    const material::SchemeState scheme = material::appliedScheme();

    auto* watcher = new QFutureWatcher<PreviewResult>(this);
    connect(watcher, &QFutureWatcher<PreviewResult>::finished, this, [watcher, callback] {
        const PreviewResult result = watcher->result();
        watcher->deleteLater();

        // The callback is a JS function, so it's only called from the thread the engine runs on
        if (callback.isCallable()) {
            callback.call({ QJSValue(QString::fromUtf8(result.json)), QJSValue(result.error) });
        }
    });

    watcher->setFuture(QtConcurrent::run([wallpaper, scheme] {
        PreviewResult result;
        result.json = material::previewJson(wallpaper, scheme, &result.error);
        return result;
    }));
}

} // namespace caelestia::services
