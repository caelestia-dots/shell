#include "rootnode.hpp"

#include <qjsonobject.h>

namespace caelestia::settings {

RootNode::RootNode(const QString& path, RootNode* fallback, QObject* parent)
    : ObjectNode(fallback, parent)
    , m_file(new SettingsFile(path, this)) {
    QObject::connect(batcher(), &ChangeBatcher::dirtied, this, &RootNode::saveToFile);
    QObject::connect(m_file, &SettingsFile::changed, this, &RootNode::reloadFromFile);
    QObject::connect(m_file, &SettingsFile::readFailed, this, [this](const QString& error) {
        emit treeLoadFailed(this, error);
    });
    QObject::connect(m_file, &SettingsFile::writeFailed, this, [this](const QString& error) {
        emit treeSaveFailed(this, error);
    });
}

void RootNode::load() {
    if (m_file->load() != SettingsFile::LoadResult::Changed)
        reloadFromFile();
}

QList<Diagnostic> RootNode::diagnostics() const {
    return m_diagnostics;
}

void RootNode::reloadFromFile() {
    const auto oldDiagnostics = m_diagnostics;
    m_diagnostics.clear();

    const auto data = m_file->read();
    syncJson(data ? data.value() : QJsonObject(), m_diagnostics);

    if (m_diagnostics != oldDiagnostics)
        emit diagnosticsChanged();

    emit treeLoaded(this);
}

void RootNode::saveToFile() {
    m_file->write(toJson());
}

} // namespace caelestia::settings
