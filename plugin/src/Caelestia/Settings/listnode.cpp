#include "listnode.hpp"

#include <qjsonarray.h>
#include <qjsonobject.h>

namespace caelestia::settings {

namespace {

QString valuesKey() {
    return QStringLiteral("values");
}

void deleteNode(Node* node) {
    node->setParent(nullptr);
    node->deleteLater();
}

} // namespace

ListNode::ListNode(ListNode* fallback, QObject* parent)
    : Node(fallback, parent) {
    if (fallback) {
        // Disconnect generic fallback notify, lists use a custom one
        QObject::disconnect(fallback, &ListNode::optionChanged, this, nullptr);
        QObject::connect(fallback, &ListNode::elementsChanged, this, &ListNode::onFallbackListNotify);
    }
}

qsizetype ListNode::count() const {
    return m_elements.count();
}

QVariantList ListNode::values() const {
    QVariantList list;
    list.reserve(m_elements.count());
    for (auto* const element : m_elements)
        list << QVariant::fromValue(element);
    return list;
}

void ListNode::remove(qsizetype index) {
    const WriteScope scope(this, WriteOrigin::Qml);

    if (!validIndex(index)) {
        recordWrite(valuesKey(), false);
        return;
    }

    deleteNode(m_elements.takeAt(index));

    if (!recordWrite(valuesKey(), true))
        return;

    emit countChanged();
    emit elementsChanged({}, { index }, {});
}

void ListNode::move(qsizetype from, qsizetype to) {
    const WriteScope scope(this, WriteOrigin::Qml);

    if (!validIndex(from) || !validIndex(to)) {
        recordWrite(valuesKey(), false);
        return;
    }

    m_elements.move(from, to);
    if (recordWrite(valuesKey(), true))
        emit elementsChanged({}, {}, { { from, to } });
}

void ListNode::clear() {
    const WriteScope scope(this, WriteOrigin::Qml);

    if (m_elements.isEmpty()) {
        recordWrite(valuesKey(), false);
        return;
    }

    const auto len = m_elements.count();

    for (auto* const element : std::as_const(m_elements))
        deleteNode(element);
    m_elements.clear();

    if (!recordWrite(valuesKey(), true))
        return;

    emit countChanged();

    NodeChanges removed(len);
    std::iota(removed.begin(), removed.end(), 0);
    emit elementsChanged(removed, {}, {});
}

QString ListNode::pathFor(const QString& key) const {
    const auto p = path();
    return p + QStringLiteral("[%1]").arg(key);
}

const Schema& ListNode::schema() const {
    // Offset +1 so count is not registered
    static const auto schema = Schema::build(&staticMetaObject, Node::staticMetaObject.propertyCount() + 1);
    return schema;
}

QVariant ListNode::value(const QString& key) const {
    if (key != valuesKey()) {
        qCWarning(lcSettings,
            "Attempted to read %s on list node %s. List nodes only have a 'values' key, something is wrong.",
            qUtf8Printable(key), qUtf8Printable(path()));
        return QVariant();
    }

    return QVariant::fromValue(m_elements);
}

bool ListNode::setValue(const QString& key, const QVariant& value) {
    return setValue(key, value, nullptr);
}

bool ListNode::setValue(const QString& key, const QVariant& value, QList<Diagnostic>* diagnostics) {
    if (key != valuesKey()) {
        qCWarning(lcSettings,
            "Attempted to write %s on list node %s. List nodes only have a 'values' key, something is wrong.",
            qUtf8Printable(key), qUtf8Printable(path()));
        return false;
    }

    const auto len = m_elements.count();

    for (auto* const element : std::as_const(m_elements))
        deleteNode(element);
    m_elements.clear();

    if (value.typeId() == qMetaTypeId<QList<Node*>>()) {
        // On reset to fallback
        const auto nodes = value.value<QList<Node*>>();
        for (auto* const node : nodes)
            m_elements << createNode(node);
    } else if (value.typeId() == qMetaTypeId<QList<QVariantMap>>()) {
        // On reset to defaults
        const auto list = value.value<QList<QVariantMap>>();
        for (qsizetype i = 0; i < list.count(); ++i)
            m_elements << createNode(list.at(i), fallbackFor(i));
    } else if (value.typeId() == QMetaType::QJsonArray) {
        // From syncJson
        const auto array = value.toJsonArray();
        for (const auto& json : array)
            m_elements << createNode(json.toObject(), *diagnostics);
    } else {
        qCWarning(lcSettings, "Unexpected type %s for list node %s", value.typeName(), qUtf8Printable(path()));
        return false;
    }

    if (!recordWrite(valuesKey(), true))
        return false;

    if (len != m_elements.count())
        emit countChanged();

    NodeChanges added(m_elements.count());
    NodeChanges removed(len);
    std::iota(added.begin(), added.end(), 0);
    std::iota(removed.begin(), removed.end(), 0);
    emit elementsChanged(added, removed, {});

    return true;
}

QJsonValue ListNode::toJson(bool sparse) const {
    QJsonArray array;
    for (auto* const element : m_elements)
        array << element->toJson(sparse);
    return array;
}

bool ListNode::syncJson(const QJsonValue& json, QList<Diagnostic>& diagnostics) {
    if (!json.isArray()) {
        const auto d = Diagnostic::mismatch("an array", json, path());
        qCWarning(lcSettings, "Error decoding option %s: %s", qUtf8Printable(d.option), qUtf8Printable(d.message));
        diagnostics << d;
        return false;
    }

    const WriteScope scope(this, WriteOrigin::File);
    setValue(valuesKey(), json, &diagnostics);

    return true;
}

bool ListNode::validIndex(qsizetype index) const {
    return index >= 0 && index < m_elements.count();
}

Node* ListNode::fallbackFor(qsizetype index) const {
    if (isOverride(valuesKey()))
        return nullptr;

    const auto* fallback = static_cast<ListNode*>(fallbackNode());
    if (!fallback || !fallback->validIndex(index))
        return nullptr;

    return fallback->m_elements.at(index);
}

Node* ListNode::createNode(const QVariantMap& props, Node* fallback) const {
    auto* const node = createElement(fallback);

    const WriteScope scope(node, WriteOrigin::Init);
    for (const auto& [key, val] : props.asKeyValueRange())
        node->setValue(key, val);

    return node;
}

Node* ListNode::createNode(Node* node) const {
    auto* const copy = createElement(node);
    const auto& schema = copy->schema();

    const WriteScope scope(copy, WriteOrigin::Init);
    for (const auto& desc : schema.descriptors())
        copy->setValue(desc.key, node->value(desc.key));

    return copy;
}

Node* ListNode::createNode(const QJsonObject& json, QList<Diagnostic>& diagnostics) const {
    // Write origin will be file/file reset, which is correct.
    // This function should only be called from the JSON path of setValue.
    auto* const node = createElement(nullptr); // Nodes synced from JSON get no fallback as they are overrides
    node->syncJson(json, diagnostics);
    return node;
}

void ListNode::onFallbackListNotify(const NodeChanges& added, const NodeChanges& removed, const MoveChanges& moved) {
    if (isOverride(valuesKey()))
        return;

    const WriteScope scope(this, WriteOrigin::Layer);

    for (const auto index : added)
        m_elements.insert(index, createNode(fallbackFor(index)));
    for (const auto index : removed)
        deleteNode(m_elements.takeAt(index));
    for (const auto& move : moved)
        m_elements.move(move.first, move.second);

    if (!recordWrite(valuesKey(), true))
        return;

    if (!added.isEmpty() || !removed.isEmpty())
        emit countChanged();
    emit valuesChanged();
}

} // namespace caelestia::settings
