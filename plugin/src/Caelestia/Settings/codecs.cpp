#include "codecs.hpp"

#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qmetaobject.h>

namespace caelestia::settings {

namespace {

QString jsonTypeName(const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::Null:
        return QStringLiteral("null");
    case QJsonValue::Bool:
        return QStringLiteral("a boolean");
    case QJsonValue::Double:
        return QStringLiteral("a number");
    case QJsonValue::String:
        return QStringLiteral("a string");
    case QJsonValue::Array:
        return QStringLiteral("an array");
    case QJsonValue::Object:
        return QStringLiteral("an object");
    default:
        return QStringLiteral("nothing");
    }
}

// We don't know the option or layer here so they aren't set, they should be set by the caller
DecodeResult error(DiagnosticType::Type type, const QString& message) {
    Diagnostic error;
    error.type = type;
    error.message = message;
    return { QVariant(), error };
}

DecodeResult mismatch(const QString& expected, const QJsonValue& value) {
    return error(
        DiagnosticType::TypeMismatch, QStringLiteral("Expected %1, got %2").arg(expected, jsonTypeName(value)));
}

template <typename Container> ValueCodec* makeListCodec(const QMetaType& type) {
    const auto* elementCodec = ValueCodec::codecFor(QMetaType::fromType<typename Container::value_type>());
    return elementCodec ? new ListCodec<Container>(type, elementCodec) : nullptr;
}

using ListFactory = ValueCodec* (*)(const QMetaType&);

const QHash<int, ListFactory>& listFactories() {
    static const QHash<int, ListFactory> factories{
        { QMetaType::fromType<QStringList>().id(), &makeListCodec<QStringList> },
        { QMetaType::fromType<QList<qreal>>().id(), &makeListCodec<QList<qreal>> },
    };
    return factories;
}

} // namespace

ValueCodec* ValueCodec::codecFor(const QMetaType& type) {
    // Cache for codecs, keyed by type id
    static QHash<int, ValueCodec*> registry;

    // Cached lookup
    if (const auto it = registry.constFind(type.id()); it != registry.constEnd())
        return *it;

    ValueCodec* codec = nullptr;
    switch (type.id()) {
    case QMetaType::Bool:
        codec = new BoolCodec(type);
        break;
    case QMetaType::Int:
        codec = new IntCodec(type);
        break;
    case QMetaType::Double:
        codec = new RealCodec(type);
        break;
    case QMetaType::QString:
        codec = new StringCodec(type);
        break;
    case QMetaType::QVariantList:
        codec = new VariantListCodec(type);
        break;
    case QMetaType::QVariantMap:
        codec = new VariantMapCodec(type);
        break;
    default:
        if (const auto factory = listFactories().constFind(type.id()); factory != listFactories().constEnd())
            codec = (*factory)(type);
        else if (type.flags().testFlag(QMetaType::IsEnumeration))
            codec = new EnumCodec(type);
        break;
    }

    // Cache codec
    if (codec)
        registry.insert(type.id(), codec);

    return codec;
}

QJsonValue BoolCodec::encode(const QVariant& value) const {
    return value.toBool();
}

DecodeResult BoolCodec::decode(const QJsonValue& value) const {
    // 1 and "true" are not booleans
    if (!value.isBool())
        return mismatch(QStringLiteral("a boolean"), value);

    return { value.toBool(), std::nullopt };
}

QJsonValue IntCodec::encode(const QVariant& value) const {
    return value.toInt();
}

DecodeResult IntCodec::decode(const QJsonValue& value) const {
    if (!value.isDouble())
        return mismatch(QStringLiteral("an integer"), value);

    const auto num = value.toDouble();

    double integral;
    if (std::modf(num, &integral) != 0.0)
        return error(DiagnosticType::InvalidValue, QStringLiteral("Expected an integer, got the real %1").arg(num));

    constexpr auto min = std::numeric_limits<int>::min();
    constexpr auto max = std::numeric_limits<int>::max();
    if (num < static_cast<double>(min) || num > static_cast<double>(max)) {
        const auto message = QStringLiteral("Integer %1 is out of range, expected between %2 and %3")
                                 .arg(num, 0, 'f', 0)
                                 .arg(min)
                                 .arg(max);
        return error(DiagnosticType::InvalidValue, message);
    }

    return { static_cast<int>(num), std::nullopt };
}

QJsonValue RealCodec::encode(const QVariant& value) const {
    return value.toDouble();
}

DecodeResult RealCodec::decode(const QJsonValue& value) const {
    if (!value.isDouble())
        return mismatch(QStringLiteral("a number"), value);

    return { QVariant::fromValue<qreal>(value.toDouble()), std::nullopt };
}

QJsonValue StringCodec::encode(const QVariant& value) const {
    return value.toString();
}

DecodeResult StringCodec::decode(const QJsonValue& value) const {
    if (!value.isString())
        return mismatch(QStringLiteral("a string"), value);

    return { value.toString(), std::nullopt };
}

QJsonValue VariantListCodec::encode(const QVariant& value) const {
    return QJsonArray::fromVariantList(value.toList());
}

DecodeResult VariantListCodec::decode(const QJsonValue& value) const {
    if (!value.isArray())
        return mismatch(QStringLiteral("an array"), value);

    return { value.toArray().toVariantList(), std::nullopt };
}

QJsonValue VariantMapCodec::encode(const QVariant& value) const {
    return QJsonObject::fromVariantMap(value.toMap());
}

DecodeResult VariantMapCodec::decode(const QJsonValue& value) const {
    if (!value.isObject())
        return mismatch(QStringLiteral("an object"), value);

    return { value.toObject().toVariantMap(), std::nullopt };
}

QJsonValue EnumCodec::encode(const QVariant& value) const {
    const auto* meta = m_type.metaObject();
    const auto metaEnum = meta->enumerator(meta->indexOfEnumerator(m_type.name()));
    return QString::fromUtf8(metaEnum.valueToKey(value.toUInt()));
}

DecodeResult EnumCodec::decode(const QJsonValue& value) const {
    const auto* meta = m_type.metaObject();
    const auto metaEnum = meta->enumerator(meta->indexOfEnumerator(m_type.name()));

    for (int i = 0; i < metaEnum.keyCount(); ++i) {
        if (QString::compare(QString::fromUtf8(metaEnum.key(i)), value.toString(), Qt::CaseInsensitive) == 0)
            return { metaEnum.value(i), std::nullopt };
    }

    QStringList options;
    for (int i = 0; i < metaEnum.keyCount(); ++i)
        options << QString::fromUtf8(metaEnum.key(i));

    return error(DiagnosticType::InvalidValue,
        QStringLiteral("Invalid enum value %1. Expected one of %2").arg(value.toString(), options.join(", ")));
}

template <typename Container>
ListCodec<Container>::ListCodec(const QMetaType& type, const ValueCodec* elementCodec)
    : ValueCodec(type)
    , m_elementCodec(elementCodec) {}

template <typename Container> QJsonValue ListCodec<Container>::encode(const QVariant& value) const {
    QJsonArray array;
    const auto list = value.value<Container>();
    for (const auto& element : list)
        array.append(m_elementCodec->encode(QVariant::fromValue(element)));
    return array;
}

template <typename Container> DecodeResult ListCodec<Container>::decode(const QJsonValue& value) const {
    if (!value.isArray())
        return mismatch(QStringLiteral("an array"), value);

    const auto array = value.toArray();
    Container list;
    list.reserve(array.size());

    for (qsizetype i = 0; i < array.size(); ++i) {
        auto result = m_elementCodec->decode(array.at(i));

        // Reject the entire list if any element is invalid
        if (result.error) {
            result.error->message = QStringLiteral("Element %1: %2").arg(i).arg(result.error->message);
            return result;
        }

        list.append(result.value.value<Value>());
    }

    return { QVariant::fromValue(list), std::nullopt };
}

// Instantiated for types as needed
template class ListCodec<QStringList>;
template class ListCodec<QList<qreal>>;

} // namespace caelestia::settings
