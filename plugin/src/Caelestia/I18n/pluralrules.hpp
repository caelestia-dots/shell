#pragma once

#include <qbytearrayview.h>
#include <qlist.h>

namespace caelestia::i18n {

// A gettext `Plural-Forms` rule, compiled from a catalog header
class PluralRules {
public:
    // Returns false when the header has no usable rule, leaving the default in place
    bool parse(QByteArrayView header);
    [[nodiscard]] quint32 evaluate(int n) const;

private:
    enum class Op : quint8 {
        Const,
        N,
        Not,
        Mul,
        Div,
        Mod,
        Add,
        Sub,
        Lt,
        Gt,
        Le,
        Ge,
        Eq,
        Ne,
        And,
        Or,
        Cond
    };

    struct Node {
        Op op = Op::Const;
        quint32 value = 0;
        qsizetype a = -1;
        qsizetype b = -1;
        qsizetype c = -1;
    };

    QList<Node> m_nodes;
    quint32 m_nplurals = 2;
    qsizetype m_root = -1;

    // Cursor over the expression, only meaningful while parsing
    QByteArrayView m_expr;
    qsizetype m_pos = 0;
    bool m_failed = false;

    void reset();
    [[nodiscard]] quint32 eval(qsizetype node, quint32 n) const;

    // Recursive descent over the C expression subset gettext allows, lowest precedence first
    qsizetype addNode(Op op, qsizetype a = -1, qsizetype b = -1, qsizetype c = -1);
    qsizetype addConst(quint32 value);
    void skipSpace();
    [[nodiscard]] char peek(qsizetype offset = 0) const;
    bool consume(QByteArrayView token);

    qsizetype parseTernary();
    qsizetype parseOr();
    qsizetype parseAnd();
    qsizetype parseEquality();
    qsizetype parseRelational();
    qsizetype parseAdditive();
    qsizetype parseMultiplicative();
    qsizetype parseUnary();
    qsizetype parsePrimary();
};

} // namespace caelestia::i18n
