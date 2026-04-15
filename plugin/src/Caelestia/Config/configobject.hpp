#pragma once

#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qmap.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qset.h>
#include <qtimer.h>
#include <qvariant.h>

namespace caelestia::config {

inline QVariantMap vmap(std::initializer_list<std::pair<QString, QVariant>> entries) {
    QVariantMap map;
    for (const auto& [key, value] : entries)
        map.insert(std::move(key), std::move(value));
    return map;
}

} // namespace caelestia::config

// Declares a serialized config property with getter, setter (change-detected), signal, and member.
#define CONFIG_PROPERTY(Type, name, ...)                                                                               \
    Q_PROPERTY(Type name READ name WRITE set_##name NOTIFY name##Changed)                                              \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type name() const {                                                                                  \
        return m_##name;                                                                                               \
    }                                                                                                                  \
    void set_##name(const Type& val) {                                                                                 \
        if (caelestia::config::ConfigObject::updateMember(m_##name, val)) {                                            \
            markPropertyLoaded(QStringLiteral(#name));                                                                 \
            Q_EMIT name##Changed();                                                                                    \
            notifyPropertyChanged(QStringLiteral(#name), QVariant::fromValue(m_##name));                               \
        }                                                                                                              \
    }                                                                                                                  \
    Q_SIGNAL void name##Changed();                                                                                     \
                                                                                                                       \
private:                                                                                                               \
    Type m_##name __VA_OPT__(= __VA_ARGS__);

// Declares a CONSTANT sub-object property. Initialize the member in the constructor.
#define CONFIG_SUBOBJECT(Type, name)                                                                                   \
    Q_PROPERTY(caelestia::config::Type* name READ name CONSTANT)                                                       \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type* name() const {                                                                                 \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    Type* m_##name = nullptr;

// Like CONFIG_PROPERTY but warns on read/write when accessed on a per-monitor overlay.
#define CONFIG_GLOBAL_PROPERTY(Type, name, ...)                                                                        \
    Q_PROPERTY(Type name READ name WRITE set_##name NOTIFY name##Changed)                                              \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type name() const {                                                                                  \
        if (isOverlay())                                                                                               \
            qCWarning(caelestia::config::lcConfig, "Reading global-only option '%s' on per-monitor overlay",           \
                qUtf8Printable(propertyPath(QStringLiteral(#name))));                                                  \
        return m_##name;                                                                                               \
    }                                                                                                                  \
    void set_##name(const Type& val) {                                                                                 \
        if (isOverlay())                                                                                               \
            qCWarning(caelestia::config::lcConfig, "Writing global-only option '%s' on per-monitor overlay",           \
                qUtf8Printable(propertyPath(QStringLiteral(#name))));                                                  \
        if (caelestia::config::ConfigObject::updateMember(m_##name, val)) {                                            \
            markPropertyLoaded(QStringLiteral(#name));                                                                 \
            Q_EMIT name##Changed();                                                                                    \
            notifyPropertyChanged(QStringLiteral(#name), QVariant::fromValue(m_##name));                               \
        }                                                                                                              \
    }                                                                                                                  \
    Q_SIGNAL void name##Changed();                                                                                     \
                                                                                                                       \
private:                                                                                                               \
    Type m_##name __VA_OPT__(= __VA_ARGS__);                                                                           \
    const bool m_##name##_go = [this] {                                                                                \
        markGlobalOnly(QStringLiteral(#name));                                                                         \
        return true;                                                                                                   \
    }();

namespace caelestia::config {

Q_DECLARE_LOGGING_CATEGORY(lcConfig)

class ConfigObject : public QObject {
    Q_OBJECT

public:
    explicit ConfigObject(QObject* parent = nullptr);

    void loadFromJson(const QJsonObject& obj);
    [[nodiscard]] QJsonObject toJsonObject() const;

    // Per-monitor overlay support (Qt Resolve Mask pattern).
    void syncFromGlobal(ConfigObject* global);
    void resyncFromGlobal();
    void clearLoadedKeys();

    [[nodiscard]] bool isPropertyLoaded(const QString& name) const;
    [[nodiscard]] QString propertyPath(const QString& name) const;
    [[nodiscard]] bool isOverlay() const;
    // Returns true only on overlays — global singleton always returns false.
    [[nodiscard]] bool isGlobalOnly(const QString& name) const;

    Q_INVOKABLE void resetOption(const QString& name);

    template <typename T> static bool updateMember(T& member, const T& value) {
        if constexpr (std::is_floating_point_v<T>) {
            if (qFuzzyCompare(member + 1.0, value + 1.0))
                return false;
        } else {
            if (member == value)
                return false;
        }
        member = value;
        return true;
    }

signals:
    void propertiesChanged(const QMap<QString, QVariant>& changed);

protected:
    void markPropertyLoaded(const QString& name);
    void markGlobalOnly(const QString& name);
    void notifyPropertyChanged(const QString& name, const QVariant& value);

private:
    void onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed);
    void emitBatchedChanges();

    // Per-monitor overlay state
    ConfigObject* m_global = nullptr;
    QSet<QString> m_loadedKeys;
    QSet<QString> m_globalOnlyKeys;
    QMap<QString, QVariant> m_pendingChanges;
    QTimer* m_batchTimer = nullptr;
};

} // namespace caelestia::config
