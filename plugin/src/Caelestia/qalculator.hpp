#pragma once

#include <qmutex.h>
#include <qobject.h>
#include <qpair.h>
#include <qqmlintegration.h>

namespace caelestia {

class Qalculator : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString result READ result NOTIFY resultChanged)
    Q_PROPERTY(QString rawResult READ rawResult NOTIFY rawResultChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit Qalculator(QObject* parent = nullptr);

    [[nodiscard]] Q_INVOKABLE static QString eval(const QString& expr, bool printExpr = true);
    Q_INVOKABLE void evalAsync(const QString& expr);

    [[nodiscard]] QString result() const;
    [[nodiscard]] QString rawResult() const;
    [[nodiscard]] bool busy() const;

signals:
    void resultChanged();
    void rawResultChanged();
    void busyChanged();

private:
    static QMutex s_calculatorMutex;

    [[nodiscard]] static QPair<QString, QString> evaluate(const QString& expr);

    void applyResult(quint64 gen, const QPair<QString, QString>& result);
    void clearResult();
    void setBusy(bool busy);

    QString m_result;
    QString m_rawResult;
    bool m_busy = false;
    quint64 m_generation = 0;
};

} // namespace caelestia
