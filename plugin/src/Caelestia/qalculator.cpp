#include "qalculator.hpp"

#include <libqalculate/qalculate.h>

namespace caelestia {

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

} // namespace caelestia
