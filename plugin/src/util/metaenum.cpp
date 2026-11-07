#include "util/metaenum.hpp"

namespace util {

QMetaEnum metaEnumFor(const QMetaType& type) {
    const auto* meta = type.metaObject();
    if (!meta)
        return {};

    // Metatype names are scoped (Class::Enum) but enumerators are registered unscoped
    auto name = QByteArray(type.name());
    if (const auto scope = name.lastIndexOf("::"); scope >= 0)
        name = name.mid(scope + 2);

    return meta->enumerator(meta->indexOfEnumerator(name.constData()));
}

bool isSupportedEnum(const QMetaType& type) {
    if (!type.flags().testFlag(QMetaType::IsEnumeration))
        return false;

    const auto metaEnum = metaEnumFor(type);
    return metaEnum.isValid() && !metaEnum.is64Bit();
}

const char* enumKeyFor(const QMetaEnum& metaEnum, const QVariant& value) {
    // Qt sign extends negative enumerators, so the value has to be widened before it is reinterpreted
    return metaEnum.valueToKey(static_cast<quint64>(value.toLongLong()));
}

} // namespace util
