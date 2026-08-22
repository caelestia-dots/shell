#pragma once

#include <qobject.h>
#include <qvariant.h>

#include "listnode.hpp" // IWYU pragma: keep
#include "schema.hpp"   // IWYU pragma: keep

namespace caelestia::settings {

inline QVariantMap vmap(std::initializer_list<std::pair<QString, QVariant>> entries) {
    QVariantMap map;
    for (const auto& [key, value] : entries)
        map.insert(std::move(key), std::move(value));
    return map;
}

namespace detail {

template <typename T> inline bool compare(const T& a, const T& b) {
    return a == b;
}

template <std::floating_point T> bool compare(const T& a, const T& b) {
    return qFuzzyCompare(a + T(1), b + T(1));
}

template <std::floating_point T> bool compare(const QList<T>& a, const QList<T>& b) {
    if (a.size() != b.size())
        return false;

    for (qsizetype i = 0; i < a.size(); ++i)
        if (!compare(a.at(i), b.at(i)))
            return false;
    return true;
}

} // namespace detail

} // namespace caelestia::settings

// Helper macro to prevent splitting initialiser lists
#define DEFAULT_ARG(...) __VA_ARGS__

// Declares a class to be a node class. This replaces the Q_OBJECT call at the top of the class.
#define SETTINGS_NODE_NO_CTOR(Class, Base)                                                                             \
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

#define SETTINGS_NODE(Class, Base)                                                                                     \
    SETTINGS_NODE_NO_CTOR(Class, Base)                                                                                 \
    QML_ANONYMOUS                                                                                                      \
                                                                                                                       \
public:                                                                                                                \
    explicit Class(Class* fallback = nullptr, QObject* parent = nullptr, bool globalOnly = false)                      \
        : Base(fallback, parent, globalOnly) {}                                                                        \
                                                                                                                       \
private:

// Defines a property on a node.
#define SETTINGS_PROPERTY(Type, name, defaultVal, ...)                                                                 \
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
        const auto needsNotify = !caelestia::settings::detail::compare(value, m_##name);                               \
        m_##name = value;                                                                                              \
        if (recordWrite(QStringLiteral(#name), needsNotify))                                                           \
            Q_EMIT name##Changed();                                                                                    \
    }                                                                                                                  \
                                                                                                                       \
    Q_SIGNAL void name##Changed();                                                                                     \
                                                                                                                       \
private:                                                                                                               \
    Type m_##name = fallbackValue(&Self::m_##name, caelestia::settings::DefaultSpec::resolve<Type>(this, defaultVal)); \
    inline static const bool s_register_##name =                                                                       \
        (caelestia::settings::Schema::annotate(&staticMetaObject, QStringLiteral(#name),                               \
             { .defaultValue = caelestia::settings::DefaultSpec::create<Type>(defaultVal), __VA_ARGS__ }),             \
            true);

// Defines a global property on a node. Shorthand for .globalOnly = true.
#define SETTINGS_GLOBAL_PROPERTY(Type, name, defaultVal, ...)                                                          \
    SETTINGS_PROPERTY(Type, name, DEFAULT_ARG(defaultVal), .globalOnly = true, __VA_ARGS__)

// Defines a subobject property on a node. Subobject properties are CONSTANT.
#define SETTINGS_SUBOBJECT_IMPL(Type, name, global)                                                                    \
    Q_PROPERTY(Type* name READ name CONSTANT)                                                                          \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type* name() const {                                                                                 \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    Type* m_##name = new Type(fallbackValue(&Self::m_##name, nullptr), this, global);                                  \
    inline static const bool s_register_##name =                                                                       \
        (caelestia::settings::Schema::annotate(                                                                        \
             &staticMetaObject, QStringLiteral(#name), { .defaultValue = {}, .globalOnly = global }),                  \
            true);

#define SETTINGS_SUBOBJECT(Type, name) SETTINGS_SUBOBJECT_IMPL(Type, name, false)

// Defines a global subobject on a node. Everything inside it is global only.
#define SETTINGS_GLOBAL_SUBOBJECT(Type, name) SETTINGS_SUBOBJECT_IMPL(Type, name, true)

// Defines a list type for use with SETTINGS_LIST.
#define SETTINGS_LIST_TYPE(Element, Name)                                                                              \
    class Name : public caelestia::settings::ListNode {                                                                \
        Q_OBJECT                                                                                                       \
        QML_ANONYMOUS                                                                                                  \
                                                                                                                       \
    public:                                                                                                            \
        explicit Name(Name* fallback = nullptr, QObject* parent = nullptr, bool globalOnly = false)                    \
            : caelestia::settings::ListNode(fallback, parent, globalOnly) {}                                           \
                                                                                                                       \
        [[nodiscard]] Q_INVOKABLE Element* at(qsizetype index) const { /* Format ugh */                                \
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
#define SETTINGS_LIST_IMPL(Type, name, global, defaultVal, ...)                                                        \
    Q_PROPERTY(Type* name READ name CONSTANT)                                                                          \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type* name() const {                                                                                 \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    Type* m_##name = new Type(fallbackValue(&Self::m_##name, nullptr), this, global);                                  \
    inline static const bool s_register_##name =                                                                       \
        (caelestia::settings::Schema::annotate(&staticMetaObject, QStringLiteral(#name),                               \
             { .defaultValue = caelestia::settings::DefaultSpec::create<QList<QVariantMap>>(defaultVal),               \
                 .globalOnly = global,                                                                                 \
                 __VA_ARGS__ }),                                                                                       \
            true);

#define SETTINGS_LIST(Type, name, defaultVal, ...)                                                                     \
    SETTINGS_LIST_IMPL(Type, name, false, DEFAULT_ARG(defaultVal), __VA_ARGS__)

// Defines a global list on a node. Everything inside it is global only.
#define SETTINGS_GLOBAL_LIST(Type, name, defaultVal, ...)                                                              \
    SETTINGS_LIST_IMPL(Type, name, true, DEFAULT_ARG(defaultVal), __VA_ARGS__)
