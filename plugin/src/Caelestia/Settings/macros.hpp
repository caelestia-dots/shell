#pragma once

#include <qvariant.h>

namespace caelestia::settings {

inline QVariantMap vmap(std::initializer_list<std::pair<QString, QVariant>> entries) {
    QVariantMap map;
    for (const auto& [key, value] : entries)
        map.insert(std::move(key), std::move(value));
    return map;
}

} // namespace caelestia::settings

// Declares a class to be a node class. This replaces the Q_OBJECT call at the top of the class.
#define CONFIG_NODE_NO_CTOR(Class, Base)                                                                               \
    Q_OBJECT                                                                                                           \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] const caelestia::settings::Schema& schema() const override {                                         \
        static const auto schema =                                                                                     \
            caelestia::settings::Schema::build(&staticMetaObject, Base::staticMetaObject.propertyCount());             \
        return schema;                                                                                                 \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    using Self = Class; // For use in the below macros

#define CONFIG_NODE(Class, Base)                                                                                       \
    CONFIG_NODE_NO_CTOR(Class, Base)                                                                                   \
    QML_ANONYMOUS                                                                                                      \
                                                                                                                       \
public:                                                                                                                \
    explicit Class(Class* fallback = nullptr, QObject* parent = nullptr)                                               \
        : Base(fallback, parent) {}                                                                                    \
                                                                                                                       \
private:

// Defines a property on a node.
#define CONFIG_PROPERTY(Type, name, defaultVal, ...)                                                                   \
    Q_PROPERTY(Type name READ name WRITE set_##name NOTIFY name##Changed)                                              \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type name() const {                                                                                  \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
    void set_##name(const Type& value) {                                                                               \
        if (!true /* TODO: validation */)                                                                              \
            return;                                                                                                    \
                                                                                                                       \
        if (forwardGlobalWrite(QStringLiteral(#name), QVariant::fromValue(value)))                                     \
            return; /* Skip writes to global only keys, they are forwarded to the global layer */                      \
                                                                                                                       \
        const auto needsNotify = value != m_##name;                                                                    \
        m_##name = value;                                                                                              \
        if (recordWrite(QStringLiteral(#name), needsNotify))                                                           \
            Q_EMIT name##Changed();                                                                                    \
    }                                                                                                                  \
                                                                                                                       \
    Q_SIGNAL void name##Changed();                                                                                     \
                                                                                                                       \
private:                                                                                                               \
    Type m_##name = fallbackValue(&Self::m_##name, Type(defaultVal));                                                  \
    inline static const bool s_register_##name =                                                                       \
        (caelestia::settings::Schema::annotate(&staticMetaObject, QStringLiteral(#name),                               \
             { .defaultValue = QVariant::fromValue(Type(defaultVal)), __VA_ARGS__ }),                                  \
            true);

// Defines a global property on a node. Shorthand for .globalOnly = true, and to keep compat with prev design.
#define CONFIG_GLOBAL_PROPERTY(Type, name, defaultVal, ...)                                                            \
    CONFIG_PROPERTY(Type, name, defaultVal, .globalOnly = true, __VA_ARGS__)

// Defines a subobject property on a node. Subobject properties are CONSTANT.
#define CONFIG_SUBOBJECT(Type, name)                                                                                   \
    Q_PROPERTY(Type* name READ name CONSTANT)                                                                          \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type* name() const {                                                                                 \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    Type* m_##name = new Type(fallbackValue(&Self::m_##name, nullptr), this);                                          \
    inline static const bool s_register_##name =                                                                       \
        (caelestia::settings::Schema::annotate(&staticMetaObject, QStringLiteral(#name), {}), true);

// Defines a list type for use with CONFIG_LIST.
#define CONFIG_LIST_TYPE(Element, Name)                                                                                \
    class Name : public caelestia::settings::ListNode {                                                                \
        Q_OBJECT                                                                                                       \
        QML_ANONYMOUS                                                                                                  \
                                                                                                                       \
    public:                                                                                                            \
        explicit Name(Name* fallback = nullptr, QObject* parent = nullptr)                                             \
            : caelestia::settings::ListNode(fallback, parent) {}                                                       \
                                                                                                                       \
        [[nodiscard]] Q_INVOKABLE Element* at(qsizetype index) { /* Format ugh */                                      \
            return static_cast<Element*>(elementAt(index));                                                            \
        }                                                                                                              \
        [[nodiscard]] Q_INVOKABLE Element* insert(const QVariantMap& props, qsizetype index = -1) {                    \
            return static_cast<Element*>(insertElement(props, index));                                                 \
        }                                                                                                              \
                                                                                                                       \
    protected:                                                                                                         \
        [[nodiscard]] caelestia::settings::Node* createElement(caelestia::settings::Node* fallback) override {         \
            return new Element(static_cast<Element*>(fallback), this);                                                 \
        }                                                                                                              \
    };

// Defines a list property on a node. List properties are CONSTANT.
#define CONFIG_LIST(Type, name, defaultVal, ...)                                                                       \
    Q_PROPERTY(Type* name READ name CONSTANT)                                                                          \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type* name() const {                                                                                 \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    Type* m_##name = new Type(fallbackValue(&Self::m_##name, nullptr), this);                                          \
    inline static const bool s_register_##name =                                                                       \
        (caelestia::settings::Schema::annotate(&staticMetaObject, QStringLiteral(#name),                               \
             { .defaultValue = QVariant::fromValue(QList<QVariantMap> defaultVal), __VA_ARGS__ }),                     \
            true);

// Defines a global list property on a node. Shorthand for .globalOnly = true.
#define CONFIG_GLOBAL_LIST(Type, name, defaultVal, ...)                                                                \
    CONFIG_LIST(Type, name, defaultVal, .globalOnly = true, __VA_ARGS__)
