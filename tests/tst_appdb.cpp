#include <qsignalspy.h>
#include <qtest.h>

#include "Models/appdb.hpp"

using namespace Qt::StringLiterals;
using caelestia::models::AppDb;
using caelestia::models::AppEntry;

// Stand-in for a Quickshell DesktopEntry, with the properties AppEntry reads
class FakeEntry : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString id MEMBER id CONSTANT)
    Q_PROPERTY(QString name MEMBER name NOTIFY changed)
    Q_PROPERTY(QString comment MEMBER comment NOTIFY changed)
    Q_PROPERTY(QString execString MEMBER execString NOTIFY changed)
    Q_PROPERTY(QString startupClass MEMBER startupClass NOTIFY changed)
    Q_PROPERTY(QString genericName MEMBER genericName NOTIFY changed)
    Q_PROPERTY(QStringList categories MEMBER categories NOTIFY changed)
    Q_PROPERTY(QStringList keywords MEMBER keywords NOTIFY changed)

public:
    FakeEntry(QString entryId, QString entryName, QObject* parent)
        : QObject(parent)
        , id(std::move(entryId))
        , name(std::move(entryName)) {}

    QString id;
    QString name;
    QString comment;
    QString execString;
    QString startupClass;
    QString genericName;
    QStringList categories;
    QStringList keywords;

signals:
    void changed();
};

class TestAppDb : public QObject {
    Q_OBJECT

    static QStringList names(AppDb& db) {
        auto list = db.apps();
        QStringList out;
        for (qsizetype i = 0; i < list.count(&list); ++i)
            out << list.at(&list, i)->name();
        return out;
    }

private slots:

    void ordering() {
        AppDb db;
        db.setPath({}); // In memory
        db.setFavouriteApps({});

        QObject owner;
        const QObjectList entries{
            new FakeEntry(QStringLiteral("c.desktop"), QStringLiteral("Charlie"), &owner),
            new FakeEntry(QStringLiteral("a.desktop"), QStringLiteral("alpha"), &owner),
            new FakeEntry(QStringLiteral("b.desktop"), QStringLiteral("Bravo"), &owner),
        };

        QSignalSpy spy(&db, &AppDb::appsChanged);
        db.setEntries(entries);
        QTRY_VERIFY(spy.count() > 0); // Entries are applied after a short debounce

        // Alphabetical (locale aware, so case doesn't split the list)
        QCOMPARE(names(db), (QStringList{ u"alpha"_s, u"Bravo"_s, u"Charlie"_s }));
        // Reading again gives the same, cached order
        QCOMPARE(names(db), (QStringList{ u"alpha"_s, u"Bravo"_s, u"Charlie"_s }));

        // More launches move an app up
        db.incrementFrequency(QStringLiteral("b.desktop"));
        QCOMPARE(names(db), (QStringList{ u"Bravo"_s, u"alpha"_s, u"Charlie"_s }));

        // Favourites come first regardless of frequency
        db.setFavouriteApps({ QStringLiteral("c.desktop") });
        QCOMPARE(names(db), (QStringList{ u"Charlie"_s, u"Bravo"_s, u"alpha"_s }));

        // Removed entries disappear
        spy.clear();
        db.setEntries(entries.mid(1));
        QTRY_VERIFY(spy.count() > 0);
        QCOMPARE(names(db), (QStringList{ u"Bravo"_s, u"alpha"_s }));
    }

    void favouritesAcceptRegex() {
        AppDb db;
        db.setPath({});
        db.setFavouriteApps({ QStringLiteral("^org\\.kde\\..*$") });

        QObject owner;
        QSignalSpy spy(&db, &AppDb::appsChanged);
        db.setEntries({
            new FakeEntry(QStringLiteral("firefox.desktop"), QStringLiteral("Firefox"), &owner),
            new FakeEntry(QStringLiteral("org.kde.dolphin.desktop"), QStringLiteral("Dolphin"), &owner),
        });
        QTRY_VERIFY(spy.count() > 0);
        QCOMPARE(names(db).first(), QStringLiteral("Dolphin"));
    }
};

QTEST_GUILESS_MAIN(TestAppDb)
#include "tst_appdb.moc"
