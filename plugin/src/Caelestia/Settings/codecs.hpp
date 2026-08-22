#pragma once

#include <qjsonvalue.h>
#include <qmetaobject.h>
#include <qvariant.h>

#include "common.hpp"

namespace caelestia::settings {

struct DecodeResult {
    QVariant value;
    std::optional<Diagnostic> error;
};

class ValueCodec {
public:
    explicit ValueCodec(const QMetaType& type)
        : m_type(type) {}

    virtual ~ValueCodec() = default;

    // Returns the shared codec for a type, or nullptr if the type is unsupported
    static ValueCodec* codecFor(const QMetaType& type);

    [[nodiscard]] virtual QJsonValue encode(const QVariant& value) const = 0;
    [[nodiscard]] virtual DecodeResult decode(const QJsonValue& value) const = 0;

protected:
    const QMetaType m_type;

    Q_DISABLE_COPY_MOVE(ValueCodec)
};

#define CODEC(Type)                                                                                                    \
    class Type##Codec : public ValueCodec {                                                                            \
    public:                                                                                                            \
        using ValueCodec::ValueCodec;                                                                                  \
        [[nodiscard]] QJsonValue encode(const QVariant& value) const override;                                         \
        [[nodiscard]] DecodeResult decode(const QJsonValue& value) const override;                                     \
    };

CODEC(Bool)
CODEC(Int)
CODEC(Real)
CODEC(String)
CODEC(VariantList)
CODEC(VariantMap)

#undef CODEC

class EnumCodec : public ValueCodec {
public:
    explicit EnumCodec(const QMetaType& type, const QMetaEnum& metaEnum);

    [[nodiscard]] QJsonValue encode(const QVariant& value) const override;
    [[nodiscard]] DecodeResult decode(const QJsonValue& value) const override;

private:
    const QMetaEnum m_metaEnum;
};

template <typename Container> class ListCodec : public ValueCodec {
    using Value = typename Container::value_type;

public:
    explicit ListCodec(const QMetaType& type, const ValueCodec* elementCodec);

    [[nodiscard]] QJsonValue encode(const QVariant& value) const override;
    [[nodiscard]] DecodeResult decode(const QJsonValue& value) const override;

private:
    const ValueCodec* m_elementCodec;
};

} // namespace caelestia::settings
