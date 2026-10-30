#pragma once

#include <qmetaobject.h>
#include <qmetatype.h>
#include <qvariant.h>

namespace util {

// Returns the meta enum for a type, or an invalid one if it has none
QMetaEnum metaEnumFor(const QMetaType& type);

// QFlags also passes the enumeration test, and 64 bit enums don't fit QMetaEnum's key API
bool isSupportedEnum(const QMetaType& type);

// Returns the enumerator name for a value, or nullptr if there is no such enumerator
const char* enumKeyFor(const QMetaEnum& metaEnum, const QVariant& value);

} // namespace util
