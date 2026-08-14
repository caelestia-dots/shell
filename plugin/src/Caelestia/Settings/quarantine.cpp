#include "quarantine.hpp"

#include <qjsonobject.h>

namespace caelestia::settings {

void ObjectQuarantine::insert(const QString& key, const QJsonValue& value) {
    m_quarantine.insert(key, value);
}

bool ObjectQuarantine::remove(const QString& key) {
    return m_quarantine.remove(key);
}

bool ObjectQuarantine::isEmpty() const {
    return m_quarantine.isEmpty();
}

QJsonValue ObjectQuarantine::apply(const QJsonValue& json) const {
    auto result = json.toObject();
    for (const auto& [key, value] : m_quarantine.asKeyValueRange())
        if (!result.contains(key)) // Don't clobber existing values
            result.insert(key, value);
    return result;
}

} // namespace caelestia::settings
