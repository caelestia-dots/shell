#pragma once

#include <qhash.h>
#include <qobject.h>
#include <qstringview.h>

#include "node.hpp"

namespace caelestia::settings {

// Derived from Node and has ctor(path, fallback, parent)
template <typename T>
concept LayerType = std::derived_from<T, Node> && std::constructible_from<T, const QString&, T*, QObject*>;

template <LayerType T> class LayerRegistry {
public:
    explicit LayerRegistry(const QString& prefix, const QString& suffix, QObject* parent);

    [[nodiscard]] QString pathFor(const QString& name) const;
    [[nodiscard]] QString nameFor(T* layer) const;
    [[nodiscard]] T* get(const QString& name, T* fallback, bool* created = nullptr); // Created on demand

private:
    const QString m_prefix;
    const QString m_suffix;
    QObject* const m_parent;
    QHash<QString, T*> m_layers;
};

namespace detail {

inline QString stripTrailingSlashes(QStringView str) {
    while (str.endsWith(QLatin1Char('/')))
        str = str.left(str.length() - 1);
    return str.toString();
}

inline QString stripLeadingSlashes(QStringView str) {
    while (str.startsWith(QLatin1Char('/')))
        str = str.mid(1);
    return str.toString();
}

} // namespace detail

template <LayerType T>
LayerRegistry<T>::LayerRegistry(const QString& prefix, const QString& suffix, QObject* parent)
    : m_prefix(detail::stripTrailingSlashes(prefix))
    , m_suffix(detail::stripLeadingSlashes(suffix))
    , m_parent(parent) {}

template <LayerType T> QString LayerRegistry<T>::pathFor(const QString& name) const {
    return m_prefix + QLatin1Char('/') + name + QLatin1Char('/') + m_suffix;
}

template <LayerType T> QString LayerRegistry<T>::nameFor(T* layer) const {
    return m_layers.key(layer);
}

template <LayerType T> T* LayerRegistry<T>::get(const QString& name, T* fallback, bool* created) {
    if (auto* const layer = m_layers.value(name)) {
        if (created)
            *created = false;
        return layer;
    }

    if (created)
        *created = true;

    auto* const layer = new T(pathFor(name), fallback, m_parent);
    m_layers.insert(name, layer);
    return layer;
}

} // namespace caelestia::settings
