#pragma once

#include <qjsonvalue.h>
#include <qobject.h>

namespace caelestia::settings {

struct RejectedOption {
    QString key;
    QVariant value;
    QString reason;
};

struct SyncResult {
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
