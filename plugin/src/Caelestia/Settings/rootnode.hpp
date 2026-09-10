#pragma once

#include "common.hpp"
#include "objectnode.hpp"
#include "settingsfile.hpp"

namespace caelestia::settings {

class RootNode : public ObjectNode {
    Q_OBJECT

    Q_PROPERTY(QList<caelestia::settings::Diagnostic> diagnostics READ diagnostics NOTIFY diagnosticsChanged)

public:
    explicit RootNode(const QString& path, RootNode* fallback, QObject* parent = nullptr);

    [[nodiscard]] QList<Diagnostic> diagnostics() const;

    void load();

signals:
    void diagnosticsChanged();
    void treeLoaded(RootNode* self);
    void treeLoadFailed(RootNode* self, const QString& error);
    void treeSaveFailed(RootNode* self, const QString& error);

private:
    SettingsFile* const m_file;
    QList<Diagnostic> m_diagnostics;

    void reloadFromFile();
    void saveToFile();
};

} // namespace caelestia::settings
