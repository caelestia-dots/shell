#pragma once

#include "configobject.hpp"

#include <qjsonarray.h>
#include <qqmlintegration.h>
#include <qvariantlist.h>

namespace caelestia::config {

// A node whose state lives in an ordered list of elements. Element-typed members live
// in CONFIG_LIST_TYPE since QML only sees what moc sees, and moc can't see templates.
class ConfigList : public ConfigNode {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QVariantList values READ values NOTIFY valuesChanged)

public:
    explicit ConfigList(QObject* parent = nullptr, const QVariantList& defaults = {});

    [[nodiscard]] int count() const;
    [[nodiscard]] QVariantList values() const;
    [[nodiscard]] ConfigObject* itemAt(int index) const;
    [[nodiscard]] const QList<ConfigObject*>& items() const;

    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void move(int from, int to);
    Q_INVOKABLE void clear();

    void loadFromJson(const QJsonValue& json) override;
    [[nodiscard]] QJsonValue toJson() const override;
    void clearLoadedKeys() override;
    [[nodiscard]] QStringList unknownKeys() const override;
    void resyncFromGlobal() override;

signals:
    void countChanged();
    void valuesChanged();

protected:
    // Supplied by CONFIG_LIST_TYPE, not callable from a ConfigList ctor (vtable incomplete)
    [[nodiscard]] virtual ConfigObject* createItem() = 0;

    // Called by the generated subclass ctor, once createItem() is callable
    void resetToDefaults();

    ConfigObject* insertItem(const QVariantMap& props, int index);

    // Elements regardless of loaded state, unlike toJson()
    [[nodiscard]] QJsonArray elementsToJson() const;

    void syncValuesFromGlobal() override;
    void onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) override;
    [[nodiscard]] QString childPath(const ConfigNode* child) const override;

private:
    void populate(const QJsonArray& arr);
    // Whether json is the same element as current, differing only in the values of its keys
    [[nodiscard]] static bool sameElement(const ConfigObject* item, const QJsonValue& current, const QJsonValue& json);
    void appendItem(const QJsonValue& json);
    void destroyItems();
    void destroyItem(ConfigObject* item);
    void rejectGlobalOnlyElement(const ConfigObject* item) const;
    void connectItem(ConfigNode* node);
    void disconnectItem(ConfigNode* node);
    void onItemChanged();
    void notifyChanged();

    QJsonArray m_defaults;
    QList<ConfigObject*> m_items;
    bool m_loaded = false;
    // A rejected non list value, kept verbatim so saving doesn't drop it from the file.
    // Separate from ConfigObject::m_extras, which would report it as an unknown option.
    QJsonValue m_rejectedJson = QJsonValue::Undefined;
};

} // namespace caelestia::config

// Declares a ConfigList subclass for an element type. A macro, not a template, since
// everything it adds carries the element type. Use at namespace scope after the element.
#define CONFIG_LIST_TYPE(Element, Name)                                                                                \
    class Name : public caelestia::config::ConfigList {                                                                \
        Q_OBJECT                                                                                                       \
        QML_ANONYMOUS                                                                                                  \
                                                                                                                       \
    public:                                                                                                            \
        explicit Name(QObject* parent = nullptr, const QVariantList& defaults = {})                                    \
            : caelestia::config::ConfigList(parent, defaults) {                                                        \
            resetToDefaults();                                                                                         \
        }                                                                                                              \
                                                                                                                       \
        Q_INVOKABLE caelestia::config::Element* at(int index) const {                                                  \
            return static_cast<caelestia::config::Element*>(itemAt(index));                                            \
        }                                                                                                              \
        Q_INVOKABLE caelestia::config::Element* insert(const QVariantMap& props, int index = -1) {                     \
            return static_cast<caelestia::config::Element*>(insertItem(props, index));                                 \
        }                                                                                                              \
                                                                                                                       \
    protected:                                                                                                         \
        [[nodiscard]] caelestia::config::ConfigObject* createItem() override {                                         \
            return new caelestia::config::Element(this);                                                               \
        }                                                                                                              \
    };

// Declares a CONSTANT config list property, constructed inline with its defaults.
// Passing `this` is safe here, bases are built before members and ConfigList only stores the parent.
#define CONFIG_LIST(Type, name, ...)                                                                                   \
    Q_PROPERTY(caelestia::config::Type* name READ name CONSTANT)                                                       \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type* name() const {                                                                                 \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    Type* m_##name = new Type(this __VA_OPT__(, __VA_ARGS__));

// Like CONFIG_LIST but warns on read when accessed on a per-monitor overlay.
// Global-only belongs on the list, never on a property of its element type.
#define CONFIG_GLOBAL_LIST(Type, name, ...)                                                                            \
    Q_PROPERTY(caelestia::config::Type* name READ name CONSTANT)                                                       \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type* name() const {                                                                                 \
        if (isOverlay())                                                                                               \
            qCWarning(caelestia::config::lcConfig, "Reading global-only option '%s' on per-monitor overlay",           \
                qUtf8Printable(propertyPath(QStringLiteral(#name))));                                                  \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    Type* m_##name = new Type(this __VA_OPT__(, __VA_ARGS__));                                                         \
    const bool m_##name##_go = [this] {                                                                                \
        markGlobalOnly(QStringLiteral(#name));                                                                         \
        return true;                                                                                                   \
    }();

namespace caelestia::config {

class ListEntry : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, id)
    CONFIG_PROPERTY(bool, enabled, true)

public:
    explicit ListEntry(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    [[nodiscard]] QStringList identityKeys() const override { return { QStringLiteral("id") }; }
};

CONFIG_LIST_TYPE(ListEntry, EntryList)

} // namespace caelestia::config

// Shorthand for declaring an ID'd entry (bar entries/status icons, quick toggles, etc)
#define LIST_ENTRY(id, enabled) vmap({ { u"id"_s, u## #id##_s }, { u"enabled"_s, enabled } })
