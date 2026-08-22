#pragma once

#include "node.hpp"

namespace caelestia::settings {

class ListNode : public Node {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(qsizetype count READ count NOTIFY countChanged)
    Q_PROPERTY(QVariantList values READ values NOTIFY elementsChanged)

    using NodeChanges = QList<qsizetype>;
    using MoveChanges = QList<QPair<qsizetype, qsizetype>>;

public:
    explicit ListNode(ListNode* fallback, QObject* parent = nullptr, bool globalOnly = false);

    [[nodiscard]] qsizetype count() const;
    [[nodiscard]] QVariantList values() const;

    Q_INVOKABLE void remove(qsizetype index);
    Q_INVOKABLE void move(qsizetype from, qsizetype to);
    Q_INVOKABLE void clear();

    [[nodiscard]] QString pathFor(const QString& key) const override;
    [[nodiscard]] const Schema& schema() const override;
    [[nodiscard]] QVariant value(const QString& key) const override;
    bool setValue(const QString& key, const QVariant& value) override;
    bool setValue(const QString& key, const QVariant& value, QList<Diagnostic>* diagnostics);
    void resetToDefaults() override;

    [[nodiscard]] QJsonValue toJson(bool sparse = true) const override;
    bool syncJson(const QJsonValue& json, QList<Diagnostic>& diagnostics) override;

signals:
    void countChanged();
    void elementsChanged(const NodeChanges& added, const NodeChanges& removed, const MoveChanges& moved);

protected:
    bool recordWrite(const QString& key, bool changed) override;
    [[nodiscard]] QString keyOf(const Node* child) const override;

    [[nodiscard]] Node* elementAt(qsizetype index) const;
    [[nodiscard]] Node* insertElement(const QVariantMap& props, qsizetype index = -1);
    [[nodiscard]] virtual Node* createElement(Node* fallback) = 0;

private:
    QList<Node*> m_elements;

    [[nodiscard]] QList<QVariantMap> defaultValue() const;
    [[nodiscard]] bool isNested() const;

    // Returns the global list to mutate instead of this one, or nullptr to mutate this one
    [[nodiscard]] ListNode* forwardGlobalMutation() const;

    [[nodiscard]] bool validIndex(qsizetype index) const;
    [[nodiscard]] const Descriptor* getDescriptor() const;
    [[nodiscard]] Node* fallbackFor(qsizetype index) const;

    Node* insertNode(qsizetype index, const QVariantMap& props, Node* fallback);
    Node* insertNode(qsizetype index, Node* node);
    Node* insertNode(qsizetype index, const QJsonObject& json, QList<Diagnostic>& diagnostics);

    void onFallbackListNotify(const NodeChanges& added, const NodeChanges& removed, const MoveChanges& moved);
};

} // namespace caelestia::settings
