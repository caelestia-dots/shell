#include "ddc.hpp"

#include <qalgorithms.h>
#include <qdir.h>
#include <qfileinfo.h>
#include <qloggingcategory.h>
#include <qtconcurrentrun.h>

#include <tuple>

#ifdef CAELESTIA_HAS_DDCUTIL
#include <ddcutil_c_api.h>
#endif

namespace {

Q_LOGGING_CATEGORY(lcDdc, "caelestia.services.ddc", QtInfoMsg)

// VCP feature code for brightness
constexpr int k_vcpBrightness = 0x10;

// Maps DRM connectors to their DDC bus through sysfs: /sys/class/drm/cardN-CONNECTOR/ddc is a
// link to /sys/bus/i2c/devices/i2c-BUS. Returns {connector -> bus} with the "cardN-" prefix stripped.
QVariantMap connectorBuses() {
    QVariantMap result;
    const QDir drm(QStringLiteral("/sys/class/drm"));
    const auto entries = drm.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const auto& entry : entries) {
        const QFileInfo ddc(drm.filePath(entry + QStringLiteral("/ddc")));
        if (!ddc.exists())
            continue;

        const auto target = QFileInfo(ddc.canonicalFilePath()).fileName(); // "i2c-N"
        if (!target.startsWith(QStringLiteral("i2c-")))
            continue;

        bool ok = false;
        const int bus = target.mid(4).toInt(&ok);
        if (!ok)
            continue;

        const auto dash = entry.indexOf(QLatin1Char('-'));
        const auto connector = dash >= 0 ? entry.mid(dash + 1) : entry;
        result.insert(connector, bus);
    }
    return result;
}

} // namespace

#ifdef CAELESTIA_HAS_DDCUTIL

namespace caelestia::services {

namespace {

// Opens the display on an I2C bus for the duration of one operation
class OpenDisplay {
public:
    explicit OpenDisplay(int busNum) {
        DDCA_Display_Info_List* list = nullptr;
        if (ddca_get_display_info_list2(false, &list) != 0 || list == nullptr)
            return;

        for (int i = 0; i < list->ct; ++i) {
            const auto& info = list->info[i];
            if (info.path.io_mode == DDCA_IO_I2C && info.path.path.i2c_busno == busNum) {
                ddca_open_display2(info.dref, false, &m_handle);
                break;
            }
        }
        ddca_free_display_info_list(list);
    }

    ~OpenDisplay() {
        if (m_handle != nullptr)
            ddca_close_display(m_handle);
    }

    OpenDisplay(const OpenDisplay&) = delete;
    OpenDisplay& operator=(const OpenDisplay&) = delete;

    [[nodiscard]] DDCA_Display_Handle handle() const { return m_handle; }

private:
    DDCA_Display_Handle m_handle = nullptr;
};

} // namespace

Ddc::Ddc(QObject* parent)
    : QObject(parent) {
    // Failure just means no DDC support; the monitors list will be empty
    if (ddca_init2(nullptr, DDCA_SYSLOG_NOTICE, DDCA_INIT_OPTIONS_NONE, nullptr) != 0)
        qCWarning(lcDdc) << "ddca_init2 failed, DDC/CI brightness is unavailable";
}

bool Ddc::available() const { // NOLINT(readability-convert-member-functions-to-static)
    return true;
}

QVariantList Ddc::monitors() {
    QVariantList result;
    const auto buses = connectorBuses();

    DDCA_Display_Info_List* list = nullptr;
    if (ddca_get_display_info_list2(false, &list) != 0 || list == nullptr)
        return result;

    for (int i = 0; i < list->ct; ++i) {
        const auto& info = list->info[i];
        if (info.path.io_mode != DDCA_IO_I2C)
            continue;

        const int bus = info.path.path.i2c_busno;
        // Only keep displays whose connector we can name, which is what the shell matches on
        for (auto it = buses.constBegin(); it != buses.constEnd(); ++it) {
            if (it.value().toInt() == bus) {
                result.append(
                    QVariantMap{ { QStringLiteral("busNum"), bus }, { QStringLiteral("connector"), it.key() } });
                break;
            }
        }
    }
    ddca_free_display_info_list(list);
    return result;
}

void Ddc::setBrightness(int busNum, int percent) {
    const auto value = static_cast<uint8_t>(qBound(0, percent, 100));
    // The future is dropped: the write is fire and forget
    std::ignore = QtConcurrent::run([busNum, value] {
        const OpenDisplay display(busNum);
        if (display.handle() == nullptr) {
            qCWarning(lcDdc) << "setBrightness: no DDC display on bus" << busNum;
            return;
        }
        if (ddca_set_non_table_vcp_value(display.handle(), k_vcpBrightness, 0, value) != 0)
            qCWarning(lcDdc) << "setBrightness: failed on bus" << busNum;
    });
}

QVariantMap Ddc::brightness(int busNum) {
    const OpenDisplay display(busNum);
    if (display.handle() == nullptr)
        return {};

    DDCA_Non_Table_Vcp_Value value{};
    if (ddca_get_non_table_vcp_value(display.handle(), k_vcpBrightness, &value) != 0)
        return {};

    return QVariantMap{
        { QStringLiteral("current"), (static_cast<unsigned>(value.sh) << 8U) | static_cast<unsigned>(value.sl) },
        { QStringLiteral("max"), (static_cast<unsigned>(value.mh) << 8U) | static_cast<unsigned>(value.ml) },
    };
}

} // namespace caelestia::services

#else // CAELESTIA_HAS_DDCUTIL

namespace caelestia::services {

Ddc::Ddc(QObject* parent)
    : QObject(parent) {}

bool Ddc::available() const {
    return false;
}

QVariantList Ddc::monitors() {
    return {};
}

void Ddc::setBrightness(int /*busNum*/, int /*percent*/) {}

QVariantMap Ddc::brightness(int /*busNum*/) {
    return {};
}

} // namespace caelestia::services

#endif
