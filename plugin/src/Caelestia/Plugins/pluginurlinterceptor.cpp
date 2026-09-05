#include "pluginurlinterceptor.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qstandardpaths.h>

Q_LOGGING_CATEGORY(lcPluginSeal, "caelestia.plugins.seal", QtInfoMsg)

namespace caelestia::plugins {

namespace {

// Declares no types, so serving it for any directory is safe and it can live outside the tree
// it seals. A qmldir that did declare types would have to be served from its own directory.
constexpr auto kSealModule = "CaelestiaSealedPlugin";

} // namespace

PluginUrlInterceptor::PluginUrlInterceptor(QObject* parent)
    : QObject(parent)
    , m_seal(createSeal()) {}

QUrl PluginUrlInterceptor::createSeal() {
    const auto dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QStringLiteral("/plugin-seal");
    const auto emptyDir = dir + QStringLiteral("/empty");

    if (!QDir().mkpath(emptyDir)) {
        qCWarning(lcPluginSeal) << "Failed to create" << emptyDir
                                << "- unable to seal plugin directories, hot reload may not work as expected";
        return {};
    }

    const auto content = QStringLiteral("module %1\nprefer %2/\n").arg(QLatin1String(kSealModule), emptyDir).toUtf8();
    const auto path = dir + QStringLiteral("/qmldir");

    QFile file(path);
    if (file.open(QIODevice::ReadOnly)) {
        if (file.readAll() == content)
            return QUrl::fromLocalFile(path);
        file.close();
    }

    if (!file.open(QIODevice::WriteOnly)) {
        qCWarning(lcPluginSeal) << "Failed to write" << path << file.errorString()
                                << "- unable to seal plugin directories, hot reload may not work as expected";
        return {};
    }

    file.write(content);
    return QUrl::fromLocalFile(path);
}

void PluginUrlInterceptor::setRoots(const QStringList& roots) {
    QStringList next;
    next.reserve(roots.size() * 2);

    // Stored with the separator so the prefix match cannot spill into a sibling directory
    // sharing a name prefix, and so intercept() stays a plain comparison.
    for (const auto& root : roots) {
        const auto clean = QDir::cleanPath(root);
        next.append(clean + u'/');

        // Use canonical path to resolve symlinks
        const auto canonical = QFileInfo(clean).canonicalFilePath();
        if (!canonical.isEmpty() && canonical != clean)
            next.append(canonical + u'/');
    }

    next.removeDuplicates();

    QMutexLocker locker(&m_mutex);
    m_roots = std::move(next);
}

QUrl PluginUrlInterceptor::intercept(const QUrl& url, DataType type) {
    if (type != QmldirFile || m_seal.isEmpty() || !url.isLocalFile())
        return url;

    const auto path = url.toLocalFile();

    QMutexLocker locker(&m_mutex);
    for (const auto& root : std::as_const(m_roots))
        if (path.startsWith(root))
            return m_seal;

    return url;
}

} // namespace caelestia::plugins
