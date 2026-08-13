#pragma once

#include <qobject.h>

#include "common.hpp"
#include "schema.hpp"

namespace caelestia::settings {

class Node : public QObject {
    Q_OBJECT

public:
    explicit Node(Node* fallback, QObject* parent = nullptr);

    [[nodiscard]] QString key() const; // The key of this in the parent node
    [[nodiscard]] QString path() const;
    [[nodiscard]] Node* parentNode() const;
    [[nodiscard]] Node* rootNode() const;
    [[nodiscard]] Node* fallbackNode() const;

    [[nodiscard]] bool isOverride(const QString& key) const;
    [[nodiscard]] const QSet<QString>& overrides() const;
    [[nodiscard]] bool hasOverrides() const; // Recursive

    [[nodiscard]] virtual const Schema& schema() const = 0;

    [[nodiscard]] virtual QVariant value(const QString& key) const;
    virtual bool setValue(const QString& key, const QVariant& value); // Returns whether the write was successful or not

signals:
    void optionChanged(const QString& key);

protected:
    // Returns true if the notify signal should be emitted
    bool recordWrite(const QString& key, const QVariant& value);

    [[nodiscard]] virtual QString keyOf(const Node* child) const = 0;

private:
    QSet<QString> m_overrides; // Overridden keys from file/qml writes
    Node* const m_rootNode;
    Node* const m_fallbackNode;
    WriteOrigin m_writeOrigin;

    void onFallbackNotify(const QString& key);

    friend class WriteScope;
};

} // namespace caelestia::settings
