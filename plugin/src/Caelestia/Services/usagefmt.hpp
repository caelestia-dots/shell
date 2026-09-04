#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>

namespace caelestia::services::usagefmt {

struct FormatResult {
    Q_GADGET
    QML_ANONYMOUS

    Q_PROPERTY(qreal value MEMBER value CONSTANT)
    Q_PROPERTY(qreal total MEMBER total CONSTANT)
    Q_PROPERTY(QString unit MEMBER unit CONSTANT)

public:
    qreal value;
    qreal total;
    QString unit;
};

class UsageFmt : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    [[nodiscard]] Q_INVOKABLE static FormatResult formatKib(qreal kib, qreal total);
};

} // namespace caelestia::services::usagefmt
