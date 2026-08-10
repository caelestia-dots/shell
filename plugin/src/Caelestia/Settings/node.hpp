#pragma once

#include <qjsonvalue.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::settings {

struct RejectedOption {
    Q_GADGET
    QML_VALUE_TYPE(rejectedOption)

    Q_PROPERTY(QString key MEMBER key)
    Q_PROPERTY(QVariant value MEMBER value)
    Q_PROPERTY(QString reason MEMBER reason)

public:
    QString key;
    QVariant value;
    QString reason;

    bool operator==(const RejectedOption& other) const;
    bool operator!=(const RejectedOption& other) const;
    friend size_t qHash(const RejectedOption& option, size_t seed) noexcept;
};

struct SyncResult {
    Q_GADGET
    QML_VALUE_TYPE(syncResult)

    Q_PROPERTY(QSet<RejectedOption> rejected MEMBER rejected)
    Q_PROPERTY(QSet<QString> unknown MEMBER unknown)

public:
    QSet<RejectedOption> rejected;
    QSet<QString> unknown;
};

class Node;

class SaveSuppressor {
public:
    explicit SaveSuppressor(Node* node);
    ~SaveSuppressor();

private:
    Node* m_node;
};

class Node : public QObject {
    Q_OBJECT

public:
    explicit Node(QObject* parent = nullptr);

    bool saveSuppressed() const;

    virtual QJsonValue toJson() const = 0;
    virtual SyncResult syncJson(const QJsonValue& json) = 0;

signals:
    void needsSave();

protected:
    virtual void connectNotifiers() const = 0;
    static int basePropertyOffset();

private:
    bool m_suppressSave;

    friend class SaveSuppressor;
};

} // namespace caelestia::settings
