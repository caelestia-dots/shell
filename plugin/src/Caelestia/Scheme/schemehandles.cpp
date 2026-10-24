#include "schemehandles.hpp"

#include <algorithm>

namespace caelestia::shell::scheme {
namespace {

template <typename From, typename To> QList<To> map(const QList<From>& list, const std::function<To(From)>& mapFn) {
    QList<To> result;
    result.reserve(list.size());
    std::ranges::transform(list, std::back_inserter(result), mapFn);
    return result;
}

} // namespace

SchemeFlavourHandle::SchemeFlavourHandle(const lib::Flavour& flavour)
    : m_flavour(flavour.name())
    , m_modes(map<lib::Mode, Colours::Mode>(flavour.modes(), [](auto mode) {
        return static_cast<Colours::Mode>(mode);
    })) {}

QString SchemeFlavourHandle::flavour() const {
    return m_flavour;
}

QList<Colours::Mode> SchemeFlavourHandle::modes() const {
    return m_modes;
}

SchemeHandle::SchemeHandle(const lib::Scheme& scheme)
    : m_name(scheme.name())
    , m_flavours(map<lib::Flavour, SchemeFlavourHandle>(scheme.flavours(), [](const auto& flavour) {
        return SchemeFlavourHandle(flavour);
    })) {}

QString SchemeHandle::name() const {
    return m_name;
}

QList<SchemeFlavourHandle> SchemeHandle::flavours() const {
    return m_flavours;
}

} // namespace caelestia::shell::scheme
