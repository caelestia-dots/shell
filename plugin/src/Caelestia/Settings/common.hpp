#pragma once

#include <qjsonvalue.h>
#include <qloggingcategory.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::settings {

Q_DECLARE_LOGGING_CATEGORY(lcSettings)

class Node;

enum class WriteOrigin {
    Init,      // On init
    File,      // From the JSON file
    FileReset, // When option not present in file
    Layer,     // From the fallback layer
    Qml,       // From QML
    QmlReset,  // On option reset
};

class WriteScope {
public:
    explicit WriteScope(Node* node, WriteOrigin origin);
    ~WriteScope();

private:
    Node* m_root;
    WriteOrigin m_previous;

    Q_DISABLE_COPY_MOVE(WriteScope)
};

class DiagnosticType : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum Type {
        UnknownOption = 0,
        GlobalOption,
        TypeMismatch,
        InvalidValue,
    };
    Q_ENUM(Type)

    Q_INVOKABLE QString toString(Type t);
};

struct Diagnostic {
    Q_GADGET
    QML_VALUE_TYPE(diagnostic)

    Q_PROPERTY(DiagnosticType::Type type MEMBER type)
    Q_PROPERTY(QString option MEMBER option)
    Q_PROPERTY(QString message MEMBER message)

public:
    DiagnosticType::Type type = DiagnosticType::UnknownOption;
    QString option;
    QString message;

    static Diagnostic mismatch(const QString& expected, const QJsonValue& value, const QString& option = QString());

    bool operator==(const Diagnostic& other) const = default;
};

} // namespace caelestia::settings
