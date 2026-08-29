#pragma once

#include "service.hpp"

#include <qfilesystemwatcher.h>
#include <qqmlintegration.h>
#include <qstring.h>

namespace caelestia::services {

class BatteryControl : public Service {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isSupported READ isSupported NOTIFY isSupportedChanged)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)
    Q_PROPERTY(int threshold READ threshold NOTIFY thresholdChanged)
    Q_PROPERTY(QString path READ path NOTIFY pathChanged)

public:
    explicit BatteryControl(QObject* parent = nullptr);

    [[nodiscard]] bool isSupported() const;
    [[nodiscard]] bool enabled() const;
    [[nodiscard]] int threshold() const;
    [[nodiscard]] QString path() const;

    Q_INVOKABLE void toggle();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setEnabled(bool enabled);
    Q_INVOKABLE void setThreshold(int threshold);

signals:
    void isSupportedChanged();
    void enabledChanged();
    void thresholdChanged();
    void pathChanged();

private:
    void detectInterface();
    void refreshState();
    bool writeValue(const QString& val);

    QString m_path;
    bool m_isConservationMode = false;
    bool m_isSupported = false;
    bool m_enabled = false;
    int m_threshold = 100;
    QFileSystemWatcher* m_watcher = nullptr;
};

} // namespace caelestia::services
