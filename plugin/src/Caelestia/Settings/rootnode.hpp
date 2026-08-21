#pragma once

#include "common.hpp"
#include "objectnode.hpp"
#include "settingsfile.hpp"

namespace caelestia::settings {

class RootNode : public settings::ObjectNode {
    Q_OBJECT

    Q_PROPERTY(QList<caelestia::settings::Diagnostic> diagnostics READ diagnostics NOTIFY diagnosticsChanged)

public:
    explicit RootNode(const QString& path, RootNode* fallback, QObject* parent = nullptr);

    [[nodiscard]] QList<Diagnostic> diagnostics() const;

signals:
    void diagnosticsChanged();
    void loaded();
    void loadFailed(const QString& error);
    void saveFailed(const QString& error);

protected:
    // Should be called in subclass ctors to load on init
    void load();

private:
    settings::SettingsFile* const m_file;
    QList<Diagnostic> m_diagnostics;

    void reloadFromFile();
    void saveToFile();
};

} // namespace caelestia::settings
