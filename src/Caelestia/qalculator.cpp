#include "qalculator.hpp"

#include <libqalculate/qalculate.h>
#include <qtconcurrentrun.h>

namespace caelestia {

QMutex Qalculator::s_calculatorMutex;

Qalculator::Qalculator(QObject* parent)
    : QObject(parent) {
    if (!CALCULATOR) {
        // Calculator constructor sets the global `calculator` pointer (CALCULATOR macro),
        // but we need to assign it to a var so compiler doesn't flag it as a leak
        static const auto* const instance = new Calculator();
        Q_UNUSED(instance)
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

    QtConcurrent::run([expr]() -> QPair<QString, QString> {
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
    }).then(this, [this, gen](QPair<QString, QString> result) {
        if (gen != m_generation) {
            return;
        }

        const auto& [formatted, raw] = result;

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
