#include "filtermodel.hpp"

#include <qobject.h>

namespace caelestia::shell::models {

using Qt::StringLiterals::operator""_ba;

FilterModel::FilterModel(QObject* parent)
    : QSortFilterProxyModel(parent)
    , m_caseSensitivity(Qt::CaseInsensitive)
    , m_role(Qt::UserRole) {}

QString FilterModel::filter() const {
    return m_filter;
}

void FilterModel::setFilter(const QString& filter) {
    if (m_filter == filter)
        return;

    beginFilterChange();
    m_filter = filter;
    emit filterChanged();
    endFilterChange(Direction::Rows);
}

QString FilterModel::propertyName() const {
    return QString::fromUtf8(m_propertyName);
}

void FilterModel::setPropertyName(const QString& propertyName) {
    const auto name = propertyName.toUtf8();
    if (m_propertyName == name)
        return;

    beginFilterChange();
    m_propertyName = name;
    emit propertyNameChanged();
    endFilterChange(Direction::Rows);
}

bool FilterModel::caseSensitive() const {
    return m_caseSensitivity == Qt::CaseSensitive;
}

void FilterModel::setCaseSensitive(bool caseSensitive) {
    const auto sensitivity = caseSensitive ? Qt::CaseSensitive : Qt::CaseInsensitive;
    if (m_caseSensitivity == sensitivity)
        return;

    beginFilterChange();
    m_caseSensitivity = sensitivity;
    emit caseSensitiveChanged();
    endFilterChange(Direction::Rows);
}

void FilterModel::setSourceModel(QAbstractItemModel* sourceModel) {
    QSortFilterProxyModel::setSourceModel(sourceModel);
    m_role = sourceModel ? sourceModel->roleNames().key("modelData"_ba, Qt::UserRole) : Qt::UserRole;
}

int FilterModel::indexOf(QObject* entry) const {
    if (!entry)
        return -1;

    const int count = rowCount();
    for (int row = 0; row < count; ++row) {
        if (entryAt(row) == entry)
            return row;
    }
    return -1;
}

QObject* FilterModel::entryAt(int row) const {
    return index(row, 0).data(m_role).value<QObject*>();
}

bool FilterModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const {
    if (m_filter.isEmpty())
        return true;

    auto value = sourceModel()->index(sourceRow, 0, sourceParent).data(m_role);
    if (!m_propertyName.isEmpty()) {
        const auto* const object = value.value<QObject*>();
        value = object ? object->property(m_propertyName.constData()) : QVariant();
    }

    return value.toString().contains(m_filter, m_caseSensitivity);
}

} // namespace caelestia::shell::models
