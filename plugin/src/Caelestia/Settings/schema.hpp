#pragma once

#include <qhash.h>
#include <qlist.h>
#include <qmetaobject.h>
#include <qmetatype.h>
#include <qstring.h>
#include <qtmetamacros.h>
#include <qvariant.h>

namespace caelestia::settings {

struct Descriptor {
    Q_GADGET

public:
    QString key;
    QMetaType type;
    int metaIndex = -1;
    bool isNode = false;

    QVariant defaultValue;
    // Global only properties do not work on list items. Either the entire list is global only,
    // or the entire list is not.
    bool globalOnly = false;
};

class Schema {
public:
    static const Schema build(const QMetaObject* meta, int baseOffset);
    static void annotate(const QMetaObject* meta, const QString& key, Descriptor descriptor);

    [[nodiscard]] const Descriptor* get(const QString& key) const;

private:
    explicit Schema();

    QList<Descriptor> m_descriptors;
    QHash<QString, qsizetype> m_keyToIndex;
};

} // namespace caelestia::settings
