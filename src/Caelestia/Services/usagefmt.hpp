#pragma once

#include <qqmlintegration.h>

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
    Q_INVOKABLE [[nodiscard]] FormatResult formatKib(qreal kib, qreal total) const;
};

} // namespace caelestia::services::usagefmt
