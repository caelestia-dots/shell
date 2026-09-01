#include "qalculator.hpp"

#include <qtconcurrentrun.h>

#include <libqalculate/qalculate.h>

namespace caelestia {

using Qt::StringLiterals::operator""_s;

QMutex Qalculator::s_calculatorMutex;

Qalculator::Qalculator(QObject* parent)
    : QObject(parent) {
    if (!CALCULATOR) {
        // Calculator constructor sets the global `calculator` pointer (CALCULATOR macro),
        // but we need to assign it to a var so compiler doesn't flag it as a leak
        static const auto* s_instance = new Calculator();
        Q_UNUSED(s_instance)
        CALCULATOR->loadExchangeRates();
        CALCULATOR->loadGlobalDefinitions();
        CALCULATOR->loadLocalDefinitions();
    }
}

QString Qalculator::eval(const QString& expr, bool printExpr) {
    if (expr.isEmpty()) {
        return {};
    }

    const auto [formatted, raw] = evaluate(expr);
    return printExpr ? formatted : raw;
}

void Qalculator::evalAsync(const QString& expr) {
    const auto gen = ++m_generation;

    if (expr.isEmpty()) {
        clearResult();
        setBusy(false);
        return;
    }

    setBusy(true);

    QtConcurrent::run([expr] {
        return evaluate(expr);
    }).then(this, [this, gen](const QPair<QString, QString>& result) {
        applyResult(gen, result);
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

QPair<QString, QString> Qalculator::evaluate(const QString& expr) {
    const QMutexLocker locker(&s_calculatorMutex);

    const EvaluationOptions eo;
    const PrintOptions po;

    std::string parsed;
    const std::string result = CALCULATOR->calculateAndPrint(
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
        const auto errorStr = QString::fromStdString(error);
        return { errorStr, errorStr };
    }

    return { u"%1 = %2"_s.arg(parsed).arg(result), QString::fromStdString(result) };
}

void Qalculator::applyResult(quint64 gen, const QPair<QString, QString>& result) {
    if (gen != m_generation)
        return;

    const auto& [formatted, raw] = result;

    if (m_result != formatted) {
        m_result = formatted;
        emit resultChanged();
    }
    if (m_rawResult != raw) {
        m_rawResult = raw;
        emit rawResultChanged();
    }

    setBusy(false);
}

void Qalculator::clearResult() {
    if (!m_result.isEmpty()) {
        m_result.clear();
        emit resultChanged();
    }
    if (!m_rawResult.isEmpty()) {
        m_rawResult.clear();
        emit rawResultChanged();
    }
}

void Qalculator::setBusy(bool busy) {
    if (m_busy == busy)
        return;

    m_busy = busy;
    emit busyChanged();
}

} // namespace caelestia
