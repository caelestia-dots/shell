#pragma once

#include <qdbusargument.h>
#include <qjsvalue.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtimer.h>
#include <qvariant.h>

namespace caelestia::services {

// Reads network state straight from NetworkManager over D-Bus. Replaces running `nmcli` for every
// refresh: one snapshot call gathers devices, Wi-Fi access points and saved profiles, and
// NetworkManager's property signals say when to take the next one.
class NetworkDbus : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool available READ available NOTIFY availableChanged)

public:
    explicit NetworkDbus(QObject* parent = nullptr);

    // Read as a property, so it has to stay a member
    [[nodiscard]] bool available() const; // NOLINT(readability-convert-member-functions-to-static)

    // Everything the shell shows about the network, in one call:
    //   available, wifiEnabled,
    //   wifiDevices:      [{ iface, state, connection, aps: [{ ssid, bssid, strength, frequency, active, security }] }]
    //   ethernetDevices:  [{ iface, state, connection, connected }]
    //   savedConnections: [{ id, uuid, type, ssid, keyMgmt, autoconnect }]
    // State strings follow nmcli's ("connected", "disconnected", "connecting", ...).
    [[nodiscard]] Q_INVOKABLE QVariantMap snapshot() const;

    // Address details of a device's active connection: { mac, ip, prefix, gateway, dns: [] }
    Q_INVOKABLE static QVariantMap deviceDetails(const QString& iface);

    // Asks the Wi-Fi device to scan now
    Q_INVOKABLE static void requestScan(const QString& iface);

    Q_INVOKABLE static void setWifiEnabled(bool enabled);

    // Brings up a saved profile by its name. `iface` picks the device; empty means the first device
    // of the profile's type. The callback gets { success, error, needsPassword } once the device is
    // activated, or has failed or timed out.
    Q_INVOKABLE void activate(const QString& connectionId, const QString& iface, const QJSValue& callback);

    // Takes a device down (or the profile's device, when `connectionId` is given)
    Q_INVOKABLE void deactivate(const QString& connectionId, const QString& iface, const QJSValue& callback);

    // Creates a Wi-Fi profile named after the SSID (replacing any existing one with that name) and
    // activates it. Without a password, a secured network reports needsPassword.
    Q_INVOKABLE void connectWifi(const QString& ssid, const QString& bssid, const QString& password, bool hidden,
        const QString& keyMgmt, const QJSValue& callback);

    // Deletes every saved profile with this name
    Q_INVOKABLE void forget(const QString& connectionId, const QJSValue& callback);

    // Whether a saved profile connects on its own
    [[nodiscard]] Q_INVOKABLE static bool autoconnect(const QString& connectionId);

    // Turns autoconnect on or off. Turning it off also drops the stored Wi-Fi password, so the next
    // manual connection asks for it again.
    Q_INVOKABLE static bool setAutoconnect(const QString& connectionId, bool enabled);

    // IPv4 settings of a saved profile: { method, address ("ip/prefix"), gateway, dns: [], ignoreAutoDns }.
    // Method is "auto", "auto-dns" (DHCP addresses with custom DNS) or "manual".
    [[nodiscard]] Q_INVOKABLE static QVariantMap ipv4Config(const QString& connectionId);

    // Writes IPv4 settings to a saved profile; changes apply the next time it's brought up
    Q_INVOKABLE static bool setIpv4Config(const QString& connectionId, const QVariantMap& config);

    // Brings up whichever profile NetworkManager picks for a device (`device connect`)
    Q_INVOKABLE void connectDevice(const QString& iface, const QJSValue& callback);

signals:
    // Emitted (debounced) whenever NetworkManager reports a change to anything we show
    void changed();
    void availableChanged();

private slots:
    void scheduleChanged();

private:
    void connectSignals();
    void watchActivation(const QString& activePath, const QJSValue& callback) const;
    static QString profilePath(const QString& connectionId);
    static QString devicePathFor(const QString& iface, const QString& connectionType);

    QTimer m_debounce;
    bool m_connected = false;
};

} // namespace caelestia::services
