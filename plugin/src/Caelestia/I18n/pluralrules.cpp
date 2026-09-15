#include "pluralrules.hpp"

#include <qbytearray.h>

namespace caelestia::i18n {

namespace {

constexpr QByteArrayView k_headerKey = "Plural-Forms:";
constexpr QByteArrayView k_npluralsKey = "nplurals=";
constexpr QByteArrayView k_pluralKey = "plural=";

bool isSpace(char c) {
    return c == ' ' || c == '\t';
}

bool isDigit(char c) {
    return c >= '0' && c <= '9';
}

// gettext expressions are integer valued, so a comparison yields 1 or 0
quint32 fromBool(bool value) {
    return value ? 1 : 0;
}

// Fallback used when the header has no usable rule
quint32 defaultIndex(quint32 n) {
    return n == 1 ? 0 : 1;
}

// Trims the value of a `key=value;` pair out of a header line
QByteArrayView valueFor(QByteArrayView line, QByteArrayView key) {
    const auto start = line.indexOf(key);
    if (start < 0)
        return {};

    auto value = line.sliced(start + key.size());
    const auto end = value.indexOf(';');
    return end < 0 ? value : value.first(end);
}

} // namespace

bool PluralRules::parse(QByteArrayView header) {
    reset();

    const auto start = header.indexOf(k_headerKey);
    if (start < 0)
        return false;

    auto line = header.sliced(start + k_headerKey.size());
    const auto end = line.indexOf('\n');
    if (end >= 0)
        line = line.first(end);

    const auto nplurals = valueFor(line, k_npluralsKey).toByteArray().trimmed().toUInt();
    if (nplurals > 0)
        m_nplurals = nplurals;

    const auto expr = valueFor(line, k_pluralKey);
    if (expr.isEmpty())
        return false;

    m_expr = expr;
    m_pos = 0;
    m_failed = false;

    const auto root = parseTernary();
    skipSpace();

    if (m_failed || m_pos != m_expr.size()) {
        m_nodes.clear();
        return false;
    }

    m_root = root;
    return true;
}

quint32 PluralRules::evaluate(int n) const {
    const auto count = static_cast<quint32>(qMax(0, n));
    const auto index = m_root < 0 ? defaultIndex(count) : eval(m_root, count);
    return index < m_nplurals ? index : 0;
}

void PluralRules::reset() {
    m_nodes.clear();
    m_nplurals = 2;
    m_root = -1;
    m_expr = {};
    m_pos = 0;
    m_failed = false;
}

quint32 PluralRules::eval(qsizetype node, quint32 n) const {
    if (node < 0 || node >= m_nodes.size())
        return 0;

    const auto& [op, value, a, b, c] = m_nodes.at(node);
    switch (op) {
    case Op::Const:
        return value;
    case Op::N:
        return n;
    case Op::Not:
        return fromBool(eval(a, n) == 0);
    case Op::Mul:
        return eval(a, n) * eval(b, n);
    case Op::Div: {
        const auto divisor = eval(b, n);
        return divisor == 0 ? 0 : eval(a, n) / divisor;
    }
    case Op::Mod: {
        const auto divisor = eval(b, n);
        return divisor == 0 ? 0 : eval(a, n) % divisor;
    }
    case Op::Add:
        return eval(a, n) + eval(b, n);
    case Op::Sub:
        return eval(a, n) - eval(b, n);
    case Op::Lt:
        return fromBool(eval(a, n) < eval(b, n));
    case Op::Gt:
        return fromBool(eval(a, n) > eval(b, n));
    case Op::Le:
        return fromBool(eval(a, n) <= eval(b, n));
    case Op::Ge:
        return fromBool(eval(a, n) >= eval(b, n));
    case Op::Eq:
        return fromBool(eval(a, n) == eval(b, n));
    case Op::Ne:
        return fromBool(eval(a, n) != eval(b, n));
    case Op::And:
        return fromBool(eval(a, n) != 0 && eval(b, n) != 0);
    case Op::Or:
        return fromBool(eval(a, n) != 0 || eval(b, n) != 0);
    case Op::Cond:
        return eval(a, n) != 0 ? eval(b, n) : eval(c, n);
    }

    return 0;
}

qsizetype PluralRules::addNode(Op op, qsizetype a, qsizetype b, qsizetype c) {
    m_nodes.append({ .op = op, .a = a, .b = b, .c = c });
    return m_nodes.size() - 1;
}

qsizetype PluralRules::addConst(quint32 value) {
    m_nodes.append({ .op = Op::Const, .value = value });
    return m_nodes.size() - 1;
}

void PluralRules::skipSpace() {
    while (m_pos < m_expr.size() && isSpace(m_expr.at(m_pos)))
        ++m_pos;
}

char PluralRules::peek(qsizetype offset) const {
    const auto at = m_pos + offset;
    return at < m_expr.size() ? m_expr.at(at) : '\0';
}

bool PluralRules::consume(QByteArrayView token) {
    skipSpace();
    if (!m_expr.sliced(m_pos).startsWith(token))
        return false;

    m_pos += token.size();
    return true;
}

qsizetype PluralRules::parseTernary() {
    const auto cond = parseOr();
    if (!consume("?"))
        return cond;

    const auto lhs = parseTernary();
    if (!consume(":"))
        m_failed = true;

    return addNode(Op::Cond, cond, lhs, parseTernary());
}

qsizetype PluralRules::parseOr() {
    auto lhs = parseAnd();
    while (consume("||"))
        lhs = addNode(Op::Or, lhs, parseAnd());
    return lhs;
}

qsizetype PluralRules::parseAnd() {
    auto lhs = parseEquality();
    while (consume("&&"))
        lhs = addNode(Op::And, lhs, parseEquality());
    return lhs;
}

qsizetype PluralRules::parseEquality() {
    auto lhs = parseRelational();
    while (true) {
        if (consume("=="))
            lhs = addNode(Op::Eq, lhs, parseRelational());
        else if (consume("!="))
            lhs = addNode(Op::Ne, lhs, parseRelational());
        else
            return lhs;
    }
}

qsizetype PluralRules::parseRelational() {
    auto lhs = parseAdditive();
    while (true) {
        // Two char operators first, otherwise `<=` parses as `<` followed by a stray `=`
        if (consume("<="))
            lhs = addNode(Op::Le, lhs, parseAdditive());
        else if (consume(">="))
            lhs = addNode(Op::Ge, lhs, parseAdditive());
        else if (consume("<"))
            lhs = addNode(Op::Lt, lhs, parseAdditive());
        else if (consume(">"))
            lhs = addNode(Op::Gt, lhs, parseAdditive());
        else
            return lhs;
    }
}

qsizetype PluralRules::parseAdditive() {
    auto lhs = parseMultiplicative();
    while (true) {
        if (consume("+"))
            lhs = addNode(Op::Add, lhs, parseMultiplicative());
        else if (consume("-"))
            lhs = addNode(Op::Sub, lhs, parseMultiplicative());
        else
            return lhs;
    }
}

qsizetype PluralRules::parseMultiplicative() {
    auto lhs = parseUnary();
    while (true) {
        if (consume("*"))
            lhs = addNode(Op::Mul, lhs, parseUnary());
        else if (consume("/"))
            lhs = addNode(Op::Div, lhs, parseUnary());
        else if (consume("%"))
            lhs = addNode(Op::Mod, lhs, parseUnary());
        else
            return lhs;
    }
}

qsizetype PluralRules::parseUnary() {
    skipSpace();

    // `!=` is an operator, not a negated operand
    if (peek() == '!' && peek(1) != '=') {
        ++m_pos;
        return addNode(Op::Not, parseUnary());
    }

    return parsePrimary();
}

qsizetype PluralRules::parsePrimary() {
    skipSpace();

    if (consume("(")) {
        const auto node = parseTernary();
        if (!consume(")"))
            m_failed = true;
        return node;
    }

    if (peek() == 'n') {
        ++m_pos;
        return addNode(Op::N);
    }

    if (isDigit(peek())) {
        quint32 value = 0;
        while (isDigit(peek())) {
            value = value * 10 + static_cast<quint32>(peek() - '0');
            ++m_pos;
        }

        return addConst(value);
    }

    m_failed = true;
    return -1;
}

} // namespace caelestia::i18n
