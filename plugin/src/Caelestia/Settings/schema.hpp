#pragma once

#include <qhash.h>
#include <qlist.h>
#include <qmetaobject.h>
#include <qmetatype.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qvariant.h>

namespace caelestia::settings {

struct Annotation {
    QVariant defaultValue;
    // Global only properties do not work on list items. Either the entire list is global only,
    // or the entire list is not.
    bool globalOnly = false;
};

namespace detail {

// Return trivially copyable types (e.g. bool) by value and others (e.g. QVariant) by const ref
template <typename T>
using AnnotationReturn = std::conditional_t<std::is_trivially_copyable_v<T> && sizeof(T) <= sizeof(void*), T, const T&>;

} // namespace detail

#define ANNOTATION(Type, name)                                                                                         \
    Q_PROPERTY(Type name READ name)                                                                                    \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] detail::AnnotationReturn<Type> name() const {                                                        \
        return annotation.name;                                                                                        \
    }                                                                                                                  \
                                                                                                                       \
private:

struct Descriptor {
    Q_GADGET
    QML_VALUE_TYPE(descriptor)

    Q_PROPERTY(QString key MEMBER key)
    Q_PROPERTY(QString type READ typeString)
    Q_PROPERTY(int metaIndex MEMBER metaIndex)
    Q_PROPERTY(bool isNode MEMBER isNode)

    ANNOTATION(QVariant, defaultValue)
    ANNOTATION(bool, globalOnly)

public:
    QString key;
    QMetaType type;
    int metaIndex;
    bool isNode;
    Annotation annotation;

    [[nodiscard]] QString typeString() const { return type.name(); }
};

#undef ANNOTATION

class Schema {
public:
    static Schema build(const QMetaObject* meta, int baseOffset, bool includeReadOnly = false);
    static void annotate(const QMetaObject* meta, const QString& key, Annotation annotation);

    [[nodiscard]] const QList<Descriptor>& descriptors() const;
    [[nodiscard]] const Descriptor* get(const QString& key) const;

private:
    explicit Schema() = default;

    QList<Descriptor> m_descriptors;
    QHash<QString, qsizetype> m_keyToIndex;
};

} // namespace caelestia::settings
