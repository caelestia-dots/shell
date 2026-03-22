#include "qalculator.hpp"

#include <libqalculate/qalculate.h>
#include <qfuturewatcher.h>
#include <qtconcurrentrun.h>

namespace caelestia {

QMutex Qalculator::s_calculatorMutex;

Qalculator::Qalculator(QObject* parent)
    : QObject(parent) {
    if (!CALCULATOR) {
        new Calculator();
        CALCULATOR->loadExchangeRates();
        CALCULATOR->loadGlobalDefinitions();
        CALCULATOR->loadLocalDefinitions();
    }
}

QString Qalculator::eval(const QString& expr, bool printExpr) const {
    if (expr.isEmpty()) {
        return QString();
    }

    QMutexLocker locker(&s_calculatorMutex);

    EvaluationOptions eo;
    PrintOptions po;

    std::string parsed;
    std::string result = CALCULATOR->calculateAndPrint(
        CALCULATOR->unlocalizeExpression(expr.toStdString(), eo.parse_options), 100, eo, po, &parsed);

    std::string error;
    while (CALCULATOR->message()) {
        if (!CALCULATOR->message()->message().empty()) {
            if (CALCULATOR->message()->type() == MESSAGE_ERROR) {
                error += "error: ";
            } else if (CALCULATOR->message()->type() == MESSAGE_WARNING) {
                error += "warning: ";
            }
            error += CALCULATOR->message()->message();
        }
        CALCULATOR->nextMessage();
    }
    if (!error.empty()) {
        return QString::fromStdString(error);
    }

    if (printExpr) {
        return QString("%1 = %2").arg(parsed).arg(result);
    }

    return QString::fromStdString(result);
}

void Qalculator::evalAsync(const QString& expr) {
    const quint64 gen = ++m_generation;

    if (expr.isEmpty()) {
        if (!m_result.isEmpty()) {
            m_result.clear();
            emit resultChanged();
        }
        if (!m_rawResult.isEmpty()) {
            m_rawResult.clear();
            emit rawResultChanged();
        }
        if (m_busy) {
            m_busy = false;
            emit busyChanged();
        }
        return;
    }

    if (!m_busy) {
        m_busy = true;
        emit busyChanged();
    }

    const auto future = QtConcurrent::run([expr]() -> QPair<QString, QString> {
        QMutexLocker locker(&s_calculatorMutex);

        EvaluationOptions eo;
        PrintOptions po;

        std::string parsed;
        std::string result = CALCULATOR->calculateAndPrint(
            CALCULATOR->unlocalizeExpression(expr.toStdString(), eo.parse_options), 100, eo, po, &parsed);

        std::string error;
        while (CALCULATOR->message()) {
            if (!CALCULATOR->message()->message().empty()) {
                if (CALCULATOR->message()->type() == MESSAGE_ERROR) {
                    error += "error: ";
                } else if (CALCULATOR->message()->type() == MESSAGE_WARNING) {
                    error += "warning: ";
                }
                error += CALCULATOR->message()->message();
            }
            CALCULATOR->nextMessage();
        }

        if (!error.empty()) {
            const QString errorStr = QString::fromStdString(error);
            return { errorStr, errorStr };
        }

        const QString rawStr = QString::fromStdString(result);
        return { QString("%1 = %2").arg(parsed).arg(result), rawStr };
    });

    auto* watcher = new QFutureWatcher<QPair<QString, QString>>(this);

    connect(watcher, &QFutureWatcher<QPair<QString, QString>>::finished, this, [this, watcher, gen]() {
        watcher->deleteLater();

        if (gen != m_generation) {
            return;
        }

        const auto [formatted, raw] = watcher->result();

        if (m_result != formatted) {
            m_result = formatted;
            emit resultChanged();
        }
        if (m_rawResult != raw) {
            m_rawResult = raw;
            emit rawResultChanged();
        }
        if (m_busy) {
            m_busy = false;
            emit busyChanged();
        }
    });

    watcher->setFuture(future);
}

QString Qalculator::result() const {
    return m_result;
}

QString Qalculator::rawResult() const {
    return m_rawResult;
}

bool Qalculator::busy() const {
    return m_busy;
}

} // namespace caelestia
