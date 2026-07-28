#pragma once

#include <qloggingcategory.h>
#include <qobject.h>
#include <qqmlabstracturlinterceptor.h>
#include <qstringlist.h>
#include <qurl.h>

Q_DECLARE_LOGGING_CATEGORY(lcPluginSeal)

namespace caelestia::plugins {

// Blocks QML implicit imports so plugin authors are forced to import the generated module explicitly.
// This works by intercepting all qmldir lookups and redirecting them to an empty qmldir instead.
class PluginUrlInterceptor : public QObject, public QQmlAbstractUrlInterceptor {
    Q_OBJECT

public:
    explicit PluginUrlInterceptor(QObject* parent = nullptr);

    // The plugin root directories whose subtrees are sealed. Must be up to date before anything
    // in a newly discovered plugin compiles.
    void setRoots(const QStringList& roots);

    [[nodiscard]] QUrl intercept(const QUrl& url, DataType type) override;

private:
    // Materialises the shared qmldir and its empty prefer target, returning the qmldir's URL.
    [[nodiscard]] static QUrl createSeal();

    QStringList m_roots;
    QUrl m_seal;
};

} // namespace caelestia::plugins
