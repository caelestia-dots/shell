#include "schemeopener.hpp"

#include <qloggingcategory.h>

namespace {

Q_LOGGING_CATEGORY(lcSchemeOpener, "caelestia.scheme.opener", QtInfoMsg)

} // namespace

namespace caelestia::shell::scheme {

using Qt::StringLiterals::operator""_s;

SchemeOpener::SchemeOpener(QObject* parent)
    : QObject(parent)
    , m_palette(new ColourPalette(this)) {
    connectResolveSchemeUpdates(this, [this](bool committed) {
        Q_UNUSED(committed);
        if (m_name == u"dynamic")
            resolve();
    });
}

QString SchemeOpener::name() const {
    return m_name;
}

void SchemeOpener::setName(const QString& name) {
    if (m_name == name)
        return;

    m_name = name;
    emit nameChanged();
    resolve();
}

QString SchemeOpener::flavour() const {
    return m_flavour;
}

void SchemeOpener::setFlavour(const QString& flavour) {
    if (m_flavour == flavour)
        return;

    m_flavour = flavour;
    emit flavourChanged();
    resolve();
}

Colours::Mode SchemeOpener::mode() const {
    return m_mode;
}

void SchemeOpener::setMode(Colours::Mode mode) {
    if (m_mode == mode)
        return;

    m_mode = mode;
    emit modeChanged();
    resolve();
}

bool SchemeOpener::smart() const {
    return m_smart;
}

void SchemeOpener::setSmart(bool smart) {
    if (m_smart == smart)
        return;

    m_smart = smart;
    emit smartChanged();
    resolve();
}

ColourPalette* SchemeOpener::palette() const {
    return m_palette;
}

void SchemeOpener::classBegin() {}

void SchemeOpener::componentComplete() {
    m_complete = true;
    resolve();
}

void SchemeOpener::resolve() {
    if (!m_complete || m_name.isEmpty())
        return;

    const auto generation = ++m_generation;
    resolveScheme(m_name, m_flavour, static_cast<lib::Mode>(m_mode), m_smart)
        .then(this,
            [this, generation](const lib::SchemeData& data) {
                if (generation == m_generation)
                    m_palette->setColours(data.colours);
            })
        .onFailed(this, [name = m_name, flavour = m_flavour](const std::exception& e) {
            qCWarning(lcSchemeOpener) << "Failed to resolve scheme" << u"%1 (%2)"_s.arg(name, flavour) << e.what();
        });
}

} // namespace caelestia::shell::scheme
