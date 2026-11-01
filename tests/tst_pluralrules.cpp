#include <qtest.h>

#include "I18n/pluralrules.hpp"

using caelestia::i18n::PluralRules;

class TestPluralRules : public QObject {
    Q_OBJECT

private slots:

    void defaultRule() {
        // Without a parsed header the germanic default (n != 1) applies
        const PluralRules rules;
        QCOMPARE(rules.evaluate(1), 0u);
        QCOMPARE(rules.evaluate(0), 1u);
        QCOMPARE(rules.evaluate(2), 1u);
    }

    void germanic() {
        PluralRules rules;
        QVERIFY(rules.parse("Plural-Forms: nplurals=2; plural=(n != 1);\n"));
        QCOMPARE(rules.evaluate(1), 0u);
        QCOMPARE(rules.evaluate(5), 1u);
    }

    void french() {
        PluralRules rules;
        QVERIFY(rules.parse("Plural-Forms: nplurals=2; plural=(n > 1);\n"));
        QCOMPARE(rules.evaluate(0), 0u);
        QCOMPARE(rules.evaluate(1), 0u);
        QCOMPARE(rules.evaluate(2), 1u);
    }

    void russian() {
        PluralRules rules;
        QVERIFY(rules.parse("Plural-Forms: nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && "
                            "(n%100<10 || n%100>=20) ? 1 : 2);\n"));
        QCOMPARE(rules.evaluate(1), 0u);
        QCOMPARE(rules.evaluate(21), 0u);
        QCOMPARE(rules.evaluate(11), 2u);
        QCOMPARE(rules.evaluate(3), 1u);
        QCOMPARE(rules.evaluate(14), 2u);
        QCOMPARE(rules.evaluate(25), 2u);
    }

    void neverOutOfRange() {
        // A rule that yields more forms than declared must not index past nplurals
        PluralRules rules;
        if (rules.parse("Plural-Forms: nplurals=2; plural=n;\n"))
            QVERIFY(rules.evaluate(7) < 2u);
    }

    void rejectsGarbage() {
        PluralRules rules;
        QVERIFY(!rules.parse("Content-Type: text/plain; charset=UTF-8\n"));
        QVERIFY(!rules.parse("Plural-Forms: nplurals=2; plural=(n != ;\n"));
        // The default stays in place after a failed parse
        QCOMPARE(rules.evaluate(1), 0u);
        QCOMPARE(rules.evaluate(2), 1u);
    }
};

QTEST_GUILESS_MAIN(TestPluralRules)
#include "tst_pluralrules.moc"
