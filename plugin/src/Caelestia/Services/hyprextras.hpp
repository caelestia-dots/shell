#pragma once

#include <qlocalsocket.h>
#include <qobject.h>
#include <qpoint.h>
#include <qpointer.h>
#include <qqmlintegration.h>
#include <qvariant.h>

namespace caelestia::shell::services::hypr {

class HyprDevices;

class HyprExtras : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_MOC_INCLUDE("hyprdevices.hpp")

    Q_PROPERTY(QVariantHash options READ options NOTIFY optionsChanged)
    Q_PROPERTY(caelestia::shell::services::hypr::HyprDevices* devices READ devices CONSTANT)

public:
    explicit HyprExtras(QObject* parent = nullptr);

    [[nodiscard]] QVariantHash options() const;
    [[nodiscard]] HyprDevices* devices() const;

    Q_INVOKABLE void message(const QString& message);
    Q_INVOKABLE void batchMessage(const QStringList& messages);
    Q_INVOKABLE void batchRequest(const QStringList& requests, const QJSValue& callback);
    Q_INVOKABLE void applyOptions(const QVariantHash& options);
    Q_INVOKABLE void registerLayerRule(const QVariantMap& rule);

    Q_INVOKABLE void refreshOptions();
    Q_INVOKABLE void refreshDevices();

    Q_INVOKABLE void cursorPosition(const QJSValue& callback);

signals:
    void optionsChanged();

private:
    using SocketPtr = QPointer<QLocalSocket>;

    QString m_requestSocket;
    QString m_eventSocket;
    QLocalSocket* m_socket;
    bool m_socketValid;

    QVariantHash m_options;
    QStringList m_layerRules;
    HyprDevices* const m_devices;

    SocketPtr m_optionsRefresh;
    SocketPtr m_devicesRefresh;

    void socketError(QLocalSocket::LocalSocketError error) const;
    void socketStateChanged(QLocalSocket::LocalSocketState state);
    void readEvent();
    void handleEvent(const QString& event);
    void applyLayerRules();

    SocketPtr makeRequestJson(const QString& request, const std::function<void(bool, QJsonDocument)>& callback);
    SocketPtr makeRequest(const QString& request, const std::function<void(bool, QByteArray)>& callback);
};

} // namespace caelestia::shell::services::hypr
