#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qvariant.h>

namespace caelestia::services {

// Brightness of external monitors over DDC/CI, through libddcutil in-process. Replaces spawning
// `ddcutil` for every detect, read and change. When the library wasn't found at build time,
// `available` is false and callers keep using the ddcutil command.
class Ddc : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool available READ available CONSTANT)

public:
    explicit Ddc(QObject* parent = nullptr);

    // Read as a property, so it has to stay a member
    [[nodiscard]] bool available() const; // NOLINT(readability-convert-member-functions-to-static)

    // Monitors that answer DDC/CI, as { busNum, connector } entries (connector without "cardN-")
    [[nodiscard]] Q_INVOKABLE static QVariantList monitors();

    // Sets brightness (0-100) on the monitor on an I2C bus. Runs on a worker thread, since DDC/CI
    // is slow and a change can take a few hundred milliseconds.
    Q_INVOKABLE static void setBrightness(int busNum, int percent);

    // Current and maximum VCP 0x10 (brightness) values, or an empty map if the monitor didn't answer
    [[nodiscard]] Q_INVOKABLE static QVariantMap brightness(int busNum);
};

} // namespace caelestia::services
