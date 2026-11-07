#pragma once

#include <qqmlintegration.h>
#include <qsortfilterproxymodel.h>

namespace caelestia::shell::models {

class FilterModel : public QSortFilterProxyModel {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(QString propertyName READ propertyName WRITE setPropertyName NOTIFY propertyNameChanged)
    Q_PROPERTY(bool caseSensitive READ caseSensitive WRITE setCaseSensitive NOTIFY caseSensitiveChanged)

public:
    explicit FilterModel(QObject* parent = nullptr);

    [[nodiscard]] QString filter() const;
    void setFilter(const QString& filter);

    [[nodiscard]] QString propertyName() const;
    void setPropertyName(const QString& propertyName);

    [[nodiscard]] bool caseSensitive() const;
    void setCaseSensitive(bool caseSensitive);

    void setSourceModel(QAbstractItemModel* sourceModel) override;

    Q_INVOKABLE [[nodiscard]] int indexOf(QObject* entry) const;
    Q_INVOKABLE [[nodiscard]] QObject* entryAt(int row) const;

signals:
    void filterChanged();
    void propertyNameChanged();
    void caseSensitiveChanged();

protected:
    [[nodiscard]] bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;

private:
    QString m_filter;
    QByteArray m_propertyName;
    Qt::CaseSensitivity m_caseSensitivity;
    int m_role;
};

} // namespace caelestia::shell::models
