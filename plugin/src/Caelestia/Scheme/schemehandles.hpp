#pragma once

#include <qqmlintegration.h>
#include <qstring.h>

#include <caelestia/scheme/scheme.hpp>

#include "colours.hpp"

namespace caelestia::shell::scheme {

struct SchemeFlavourHandle {
    Q_GADGET
    QML_VALUE_TYPE(schemeFlavourEntry)

    Q_PROPERTY(QString flavour READ flavour CONSTANT)
    Q_PROPERTY(QList<caelestia::shell::scheme::Colours::Mode> modes READ modes CONSTANT)

public:
    explicit SchemeFlavourHandle() = default;
    explicit SchemeFlavourHandle(const lib::Flavour& flavour);

    [[nodiscard]] QString flavour() const;
    [[nodiscard]] QList<Colours::Mode> modes() const;

private:
    QString m_flavour;
    QList<Colours::Mode> m_modes;
};

struct SchemeHandle {
    Q_GADGET
    QML_VALUE_TYPE(schemeEntry)

    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QList<caelestia::shell::scheme::SchemeFlavourHandle> flavours READ flavours CONSTANT)

public:
    explicit SchemeHandle() = default;
    explicit SchemeHandle(const lib::Scheme& scheme);

    [[nodiscard]] QString name() const;
    [[nodiscard]] QList<SchemeFlavourHandle> flavours() const;

private:
    QString m_name;
    QList<SchemeFlavourHandle> m_flavours;
};

} // namespace caelestia::shell::scheme
