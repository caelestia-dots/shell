#pragma once

#include "configobject.hpp"

#include <qjsonarray.h>
#include <qqmlintegration.h>

namespace caelestia::config {

// A node whose state lives in an ordered list of elements. Element-typed members live
// in CONFIG_LIST_TYPE since QML only sees what moc sees, and moc can't see templates.
class ConfigList : public ConfigNode {
    Q_OBJECT

    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit ConfigList(QObject* parent = nullptr, const QVariantList& defaults = {});

    [[nodiscard]] int count() const;
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

private:
    void populate(const QJsonArray& arr);
    void appendItem(const QJsonValue& json);
    void destroyItems();
    void onItemChanged();
    void notifyChanged();

    QJsonArray m_defaults;
    QList<ConfigObject*> m_items;
    bool m_loaded = false;
};

} // namespace caelestia::config

// Declares a ConfigList subclass for an element type. A macro, not a template, since
// everything it adds carries the element type. Use at namespace scope after the element.
#define CONFIG_LIST_TYPE(Element, Name)                                                                                \
    class Name : public caelestia::config::ConfigList {                                                                \
        Q_OBJECT                                                                                                       \
        QML_ANONYMOUS                                                                                                  \
                                                                                                                       \
        Q_PROPERTY(QList<caelestia::config::Element*> values READ values NOTIFY valuesChanged)                         \
                                                                                                                       \
    public:                                                                                                            \
        explicit Name(QObject* parent = nullptr, const QVariantList& defaults = {})                                    \
            : caelestia::config::ConfigList(parent, defaults) {                                                        \
            resetToDefaults();                                                                                         \
        }                                                                                                              \
                                                                                                                       \
        [[nodiscard]] QList<caelestia::config::Element*> values() const {                                              \
            QList<caelestia::config::Element*> vals;                                                                   \
            vals.reserve(items().size());                                                                              \
            for (auto* const item : items())                                                                           \
                vals.append(static_cast<caelestia::config::Element*>(item));                                           \
            return vals;                                                                                               \
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
