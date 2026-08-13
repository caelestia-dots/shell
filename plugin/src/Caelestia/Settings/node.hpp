#pragma once

#include <qobject.h>

#include "common.hpp"

namespace caelestia::settings {

class Node : public QObject {
    Q_OBJECT

public:
    explicit Node(Node* fallback, QObject* parent = nullptr);

    [[nodiscard]] QString key() const; // The key of this in the parent node
    [[nodiscard]] QString path() const;
    [[nodiscard]] Node* parentNode() const;
    [[nodiscard]] Node* rootNode() const;

    [[nodiscard]] bool isOverride(const QString& key) const;
    [[nodiscard]] const QSet<QString>& overrides() const;
    [[nodiscard]] bool hasOverrides() const; // Recursive

    [[nodiscard]] Node* fallbackNode() const;
    void pullFallback();

signals:
    void optionChanged(const QString& key);

protected:
    // Returns true if the notify signal should be emitted
    bool recordWrite(const QString& key, const QVariant& value);

    [[nodiscard]] virtual QString keyOf(const Node* child) const = 0;

private:
    QSet<QString> m_overrides; // Overridden keys from file/qml writes
    Node* m_rootNode;
    Node* m_fallbackNode;
    WriteOrigin m_writeOrigin;

    void onFallbackNotify(const QString& key);

    friend class WriteScope;
};

} // namespace caelestia::settings
