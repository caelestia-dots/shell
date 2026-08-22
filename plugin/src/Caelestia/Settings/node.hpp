#pragma once

#include <qjsonvalue.h>
#include <qobject.h>

#include "changebatcher.hpp"
#include "common.hpp"
#include "quarantine.hpp"
#include "schema.hpp"

namespace caelestia::settings {

class Node : public QObject {
    Q_OBJECT

public:
    // Global only nodes are inherited, anything inside one is also global only
    explicit Node(Node* fallback, QObject* parent = nullptr, bool globalOnly = false);

    [[nodiscard]] QString key() const; // The key of this in the parent node
    [[nodiscard]] QString path() const;
    [[nodiscard]] virtual QString pathFor(const QString& key) const;
    [[nodiscard]] Node* parentNode() const;
    [[nodiscard]] Node* rootNode() const;
    [[nodiscard]] Node* fallbackNode() const;
    void detachFallback(); // Recursive, unlinks this and its children from the fallback layer

    [[nodiscard]] Q_INVOKABLE bool isGlobalOnly() const;
    [[nodiscard]] bool isOverride(const QString& key) const;
    [[nodiscard]] const QSet<QString>& overrides() const;
    [[nodiscard]] bool hasContent() const; // Recursive

    [[nodiscard]] virtual const Schema& schema() const = 0;

    [[nodiscard]] virtual QVariant value(const QString& key) const;
    virtual bool setValue(const QString& key, const QVariant& value); // Returns whether the write was successful or not
    virtual void resetToDefaults(); // Recursive, resets to fallbacks then defaults if not overridden

    [[nodiscard]] virtual QJsonValue toJson(bool sparse = true) const = 0;
    // Returns false if the entire node was rejected
    virtual bool syncJson(const QJsonValue& json, QList<Diagnostic>& diagnostics) = 0;
    [[nodiscard]] const Quarantine* quarantine() const;

signals:
    void optionChanged(const QString& key);

protected:
    // Null means empty, otherwise it has content
    std::unique_ptr<Quarantine> m_quarantine;

    // Returns true if the write should be skipped afterwards
    bool forwardGlobalWrite(const QString& key, const QVariant& value);
    // Returns true if the notify signal should be emitted
    virtual bool recordWrite(const QString& key, bool changed);

    [[nodiscard]] bool removeQuarantined(const QString& key);
    [[nodiscard]] ChangeBatcher* batcher() const;

    [[nodiscard]] virtual QString keyOf(const Node* child) const;

    template <typename C, typename T>
    [[nodiscard]] T fallbackValue(T C::* member, std::type_identity_t<T> defaultValue) const;

private:
    QSet<QString> m_overrides; // Overridden keys from file/qml writes
    Node* const m_rootNode;
    Node* m_fallbackNode;    // No fallback node either means global tree or inside overridden list
    const bool m_globalOnly; // Own flag or inherited from the parent node

    // For root node use only
    WriteOrigin m_writeOrigin;
    ChangeBatcher* const m_batcher;

    void onFallbackNotify(const QString& key);

    friend class WriteScope;
};

template <typename C, typename T> T Node::fallbackValue(T C::* member, std::type_identity_t<T> defaultValue) const {
    const auto* fallback = static_cast<const C*>(m_fallbackNode);
    return fallback ? fallback->*member : defaultValue;
}

} // namespace caelestia::settings
