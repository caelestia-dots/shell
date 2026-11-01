#include <qjsonvalue.h>
#include <qtest.h>

#include "Settings/listnode.hpp"

using namespace caelestia::settings;

class TestListElement : public Node {
    Q_OBJECT

public:
    explicit TestListElement(Node* fallback = nullptr, QObject* parent = nullptr)
        : Node(fallback, parent) {}

    [[nodiscard]] const Schema& schema() const override {
        static const auto k_schema = Schema::build(&staticMetaObject, Node::staticMetaObject.propertyCount(), true);
        return k_schema;
    }

    [[nodiscard]] QJsonValue toJson(bool sparse) const override {
        Q_UNUSED(sparse)
        return {};
    }

    bool syncJson(const QJsonValue& json, QList<Diagnostic>& diagnostics) override {
        Q_UNUSED(json)
        Q_UNUSED(diagnostics)
        return true;
    }
};

class TestListNode : public ListNode {
    Q_OBJECT

public:
    explicit TestListNode(ListNode* fallback = nullptr, QObject* parent = nullptr)
        : ListNode(fallback, parent) {}

protected:
    [[nodiscard]] Node* createElement(Node* fallback) override {
        return new TestListElement(static_cast<TestListElement*>(fallback), this);
    }
};

class TstListNode : public QObject {
    Q_OBJECT

private slots:

    void setValueReportsReplacedIndices();
    void clearReportsEveryIndex();
};

void TstListNode::setValueReportsReplacedIndices() {
    TestListNode list;
    QList<qsizetype> added;
    QList<qsizetype> removed;
    QObject::connect(&list, &ListNode::elementsChanged, &list,
        [&added, &removed](const QList<qsizetype>& addedIndices, const QList<qsizetype>& removedIndices,
            const QList<QPair<qsizetype, qsizetype>>& movedIndices) {
            Q_UNUSED(movedIndices)
            added = addedIndices;
            removed = removedIndices;
        });

    const QVariantList first{ QVariantMap{}, QVariantMap{}, QVariantMap{} };
    QVERIFY(list.setValue(QStringLiteral("values"), first));
    QCOMPARE(list.count(), qsizetype(3));
    QCOMPARE(added, (QList<qsizetype>{ 0, 1, 2 }));
    QVERIFY(removed.isEmpty());

    const QVariantList second{ QVariantMap{}, QVariantMap{} };
    QVERIFY(list.setValue(QStringLiteral("values"), second));
    QCOMPARE(list.count(), qsizetype(2));
    QCOMPARE(added, (QList<qsizetype>{ 0, 1 }));
    QCOMPARE(removed, (QList<qsizetype>{ 0, 1, 2 }));
}

void TstListNode::clearReportsEveryIndex() {
    TestListNode list;
    const QVariantList values{ QVariantMap{}, QVariantMap{}, QVariantMap{} };
    QVERIFY(list.setValue(QStringLiteral("values"), values));

    QList<qsizetype> added;
    QList<qsizetype> removed;
    QObject::connect(&list, &ListNode::elementsChanged, &list,
        [&added, &removed](const QList<qsizetype>& addedIndices, const QList<qsizetype>& removedIndices,
            const QList<QPair<qsizetype, qsizetype>>& movedIndices) {
            Q_UNUSED(movedIndices)
            added = addedIndices;
            removed = removedIndices;
        });

    list.clear();
    QCOMPARE(list.count(), qsizetype(0));
    QVERIFY(added.isEmpty());
    QCOMPARE(removed, (QList<qsizetype>{ 0, 1, 2 }));
}

QTEST_GUILESS_MAIN(TstListNode)
#include "tst_listnode.moc"
