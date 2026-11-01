#include <qtest.h>

#include "Services/lyrics.hpp"

using caelestia::services::Lyrics;

class TestLyrics : public QObject {
    Q_OBJECT

private slots:

    void basic() {
        const auto lines = Lyrics::parseLrc(QStringLiteral("[00:01.50]Hello\n[01:02]World\nno timestamp\n"));
        QCOMPARE(lines.size(), 2);
        QCOMPARE(lines[0].time, 1.5);
        QCOMPARE(lines[0].text, QStringLiteral("Hello"));
        QCOMPARE(lines[1].time, 62.0);
        QCOMPARE(lines[1].text, QStringLiteral("World"));
    }

    void sortsAndExpandsRepeatedTimestamps() {
        // One line with several timestamps becomes one entry per timestamp, all sorted
        const auto lines = Lyrics::parseLrc(QStringLiteral("[00:30]Chorus[00:10]\n[00:20]Verse\n"));
        QCOMPARE(lines.size(), 3);
        QCOMPARE(lines[0].time, 10.0);
        QCOMPARE(lines[0].text, QStringLiteral("Chorus"));
        QCOMPARE(lines[1].text, QStringLiteral("Verse"));
        QCOMPARE(lines[2].time, 30.0);
    }

    void dropsLeadingCredits() {
        const auto lines = Lyrics::parseLrc(QStringLiteral(
            "[00:00.00]Lyricist: Someone\n[00:02]作曲：某人\n[00:25]Composer of my heart\n[00:05]Real line\n"));
        // Credits in the first 20s are dropped; the same words later are kept
        QCOMPARE(lines.size(), 2);
        QCOMPARE(lines[0].text, QStringLiteral("Real line"));
        QCOMPARE(lines[1].text, QStringLiteral("Composer of my heart"));
    }

    void emptyInput() {
        QVERIFY(Lyrics::parseLrc({}).isEmpty());
        QVERIFY(Lyrics::parseLrc(QStringLiteral("just text\n")).isEmpty());
    }
};

QTEST_GUILESS_MAIN(TestLyrics)
#include "tst_lyrics.moc"
