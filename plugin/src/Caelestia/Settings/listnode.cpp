#include "listnode.hpp"

#include <qjsonarray.h>
#include <qjsonobject.h>

namespace caelestia::settings {

namespace {

QString valuesKey() {
    return QStringLiteral("values");
}

void deleteNode(Node* node) {
    node->detachFallback();
    node->setParent(nullptr);
    node->deleteLater();
}

} // namespace

ListNode::ListNode(ListNode* fallback, QObject* parent, bool globalOnly)
    : Node(fallback, parent, globalOnly) {
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
    if (auto* const global = forwardGlobalMutation()) {
        global->remove(index);
        return;
    }

    const WriteScope scope(this, WriteOrigin::Qml);

    if (!validIndex(index)) {
        recordWrite(valuesKey(), false);
        return;
    }

    deleteNode(m_elements.takeAt(index));

    recordWrite(valuesKey(), true);
    emit countChanged();
    emit elementsChanged({}, { index }, {});
}

void ListNode::move(qsizetype from, qsizetype to) {
    if (auto* const global = forwardGlobalMutation()) {
        global->move(from, to);
        return;
    }

    const WriteScope scope(this, WriteOrigin::Qml);

    if (!validIndex(from) || !validIndex(to)) {
        recordWrite(valuesKey(), false);
        return;
    }

    m_elements.move(from, to);

    recordWrite(valuesKey(), true);
    emit elementsChanged({}, {}, { { from, to } });
}

void ListNode::clear() {
    if (auto* const global = forwardGlobalMutation()) {
        global->clear();
        return;
    }

    const WriteScope scope(this, WriteOrigin::Qml);

    if (m_elements.isEmpty()) {
        recordWrite(valuesKey(), false);
        return;
    }

    const auto len = m_elements.count();

    for (auto* const element : std::as_const(m_elements))
        deleteNode(element);
    m_elements.clear();

    recordWrite(valuesKey(), true);
    emit countChanged();

    NodeChanges removed(len);
    std::iota(removed.begin(), removed.end(), 0);
    emit elementsChanged(removed, {}, {});
}

QString ListNode::pathFor(const QString& key) const {
    return path() + QStringLiteral("[%1]").arg(key);
}

const Schema& ListNode::schema() const {
    // Offset +1 so count is not registered
    static const auto schema = Schema::build(&staticMetaObject, Node::staticMetaObject.propertyCount() + 1);
    return schema;
}

QVariant ListNode::value(const QString& key) const {
    if (key != valuesKey()) {
        qCCritical(lcSettings,
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
        qCCritical(lcSettings,
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
            insertNode(m_elements.count(), node);
    } else if (value.typeId() == qMetaTypeId<QList<QVariantMap>>()) {
        // On reset to defaults
        const auto list = value.value<QList<QVariantMap>>();
        for (qsizetype i = 0; i < list.count(); ++i)
            insertNode(i, list.at(i), fallbackFor(i));
    } else if (value.typeId() == QMetaType::QJsonArray) {
        // From syncJson
        const auto array = value.toJsonArray();
        for (const auto& json : array)
            insertNode(m_elements.count(), json.toObject(), *diagnostics);
    } else {
        qCCritical(lcSettings, "Unexpected type %s for list node %s, something is wrong.", value.typeName(),
            qUtf8Printable(path()));
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

void ListNode::resetToDefaults() {
    if (isNested()) {
        qCCritical(lcSettings, "List node %s has a parent list node, resetToDefaults should never be called on it.",
            qUtf8Printable(path()));
        return;
    }

    // Don't reset global only list nodes on overlays
    if (fallbackNode() && isGlobalOnly())
        return;

    const WriteScope scope(this, WriteOrigin::FileReset);
    setValue(valuesKey(), fallbackNode() ? fallbackNode()->value(valuesKey()) : QVariant::fromValue(defaultValue()));
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

    // Refuse syncs to global only list nodes on overlays
    if (fallbackNode() && isGlobalOnly()) {
        const auto p = path();
        qCWarning(lcSettings, "Global property definition %s found in overlay file, ignoring.", qUtf8Printable(p));
        diagnostics << Diagnostic{
            DiagnosticType::GlobalOption,
            p,
            QStringLiteral("Global properties should not be defined in overlay files"),
        };
        return false;
    }

    const WriteScope scope(this, WriteOrigin::File);
    setValue(valuesKey(), json, &diagnostics);

    return true;
}

bool ListNode::recordWrite(const QString& key, bool changed) {
    const auto wasOverride = isOverride(key);
    const auto notify = Node::recordWrite(key, changed);

    // Elements inside overridden lists have no fallbacks, so detach here
    if (!wasOverride && isOverride(key))
        for (auto* const element : std::as_const(m_elements))
            element->detachFallback();

    return notify;
}

QString ListNode::keyOf(const Node* node) const {
    return QString::number(m_elements.indexOf(const_cast<Node*>(node)));
}

Node* ListNode::elementAt(qsizetype index) const {
    if (!validIndex(index))
        return nullptr;
    return m_elements.at(index);
}

Node* ListNode::insertElement(const QVariantMap& props, qsizetype index) {
    if (auto* const global = forwardGlobalMutation())
        return global->insertElement(props, index);

    const WriteScope scope(this, WriteOrigin::Qml);

    if (!validIndex(index)) // Invalid index means append
        index = m_elements.count();

    auto* const element = insertNode(index, props, nullptr);

    recordWrite(valuesKey(), true);
    emit countChanged();
    emit elementsChanged({ index }, {}, {});

    return element;
}

QList<QVariantMap> ListNode::defaultValue() const {
    const auto* desc = getDescriptor();
    if (!desc)
        return {};
    return desc->defaultValue().value<QList<QVariantMap>>();
}

bool ListNode::isNested() const {
    return qobject_cast<ListNode*>(parentNode());
}

ListNode* ListNode::forwardGlobalMutation() const {
    if (!isGlobalOnly() || !fallbackNode())
        return nullptr;

    qCWarning(lcSettings,
        "Forwarding mutation of global list %s to the global layer. "
        "This should not be used, mutate global lists from the global layer instead.",
        qUtf8Printable(path()));

    return static_cast<ListNode*>(fallbackNode());
}

bool ListNode::validIndex(qsizetype index) const {
    return index >= 0 && index < m_elements.count();
}

const Descriptor* ListNode::getDescriptor() const {
    if (!parentNode()) { // List nodes should not be root nodes
        qCCritical(lcSettings, "List node %s has no parent, something is wrong.", qUtf8Printable(path()));
        return nullptr;
    }

    const auto* desc = parentNode()->schema().get(key());

    if (!desc) {
        qCCritical(lcSettings, "List node %s is not in parent schema, something is wrong.", qUtf8Printable(path()));
        return nullptr;
    }

    return desc;
}

Node* ListNode::fallbackFor(qsizetype index) const {
    if (isOverride(valuesKey()))
        return nullptr;

    const auto* fallback = static_cast<ListNode*>(fallbackNode());
    if (!fallback || !fallback->validIndex(index))
        return nullptr;

    return fallback->m_elements.at(index);
}

Node* ListNode::insertNode(qsizetype index, const QVariantMap& props, Node* fallback) {
    auto* const node = createElement(fallback);
    m_elements.insert(index, node);

    const WriteScope scope(node, WriteOrigin::Init);
    for (const auto& [key, val] : props.asKeyValueRange())
        node->setValue(key, val);

    return node;
}

Node* ListNode::insertNode(qsizetype index, Node* node) {
    auto* const copy = createElement(node);
    m_elements.insert(index, copy);

    const auto& schema = copy->schema();

    const WriteScope scope(copy, WriteOrigin::Init);
    for (const auto& desc : schema.descriptors())
        copy->setValue(desc.key, node->value(desc.key));

    return copy;
}

Node* ListNode::insertNode(qsizetype index, const QJsonObject& json, QList<Diagnostic>& diagnostics) {
    // Write origin will be file/file reset, which is correct.
    // This function should only be called from the JSON path of setValue.
    auto* const node = createElement(nullptr); // Nodes synced from JSON get no fallback as they are overrides
    m_elements.insert(index, node);

    node->syncJson(json, diagnostics);

    return node;
}

void ListNode::onFallbackListNotify(const NodeChanges& added, const NodeChanges& removed, const MoveChanges& moved) {
    if (isOverride(valuesKey()))
        return;

    const WriteScope scope(this, WriteOrigin::Layer);

    for (const auto index : removed | std::views::reverse)
        deleteNode(m_elements.takeAt(index));
    for (const auto index : added)
        insertNode(index, fallbackFor(index));
    for (const auto& move : moved)
        m_elements.move(move.first, move.second);

    if (!recordWrite(valuesKey(), true))
        return;

    if (!added.isEmpty() || !removed.isEmpty())
        emit countChanged();
    emit elementsChanged(added, removed, moved);
}

} // namespace caelestia::settings
