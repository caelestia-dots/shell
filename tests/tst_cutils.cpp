#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qtemporarydir.h>
#include <qtest.h>

#include "cutils.hpp"

using caelestia::CUtils;

namespace {

bool writeFile(const QString& path, const QByteArray& contents) {
    QFile file(path);
    return file.open(QIODevice::WriteOnly) && file.write(contents) == contents.size();
}

QByteArray readFile(const QString& path) {
    QFile file(path);
    return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray();
}

} // namespace

class TestCUtils : public QObject {
    Q_OBJECT

private slots:

    void copyFileCreatesTarget();
    void copyFileOverwritesExistingTarget();
    void copyFileKeepsTargetWithoutOverwrite();
    void copyFileFailsWhenRemoveFails();
};

void TestCUtils::copyFileCreatesTarget() {
    const QTemporaryDir dir;
    QVERIFY(dir.isValid());

    const QString source = dir.filePath(QStringLiteral("source.txt"));
    const QString target = dir.filePath(QStringLiteral("target.txt"));
    QVERIFY(writeFile(source, "new"));

    QVERIFY(CUtils::copyFile(QUrl::fromLocalFile(source), QUrl::fromLocalFile(target)));
    QCOMPARE(readFile(target), QByteArray("new"));
}

void TestCUtils::copyFileOverwritesExistingTarget() {
    const QTemporaryDir dir;
    QVERIFY(dir.isValid());

    const QString source = dir.filePath(QStringLiteral("source.txt"));
    const QString target = dir.filePath(QStringLiteral("target.txt"));
    QVERIFY(writeFile(source, "new"));
    QVERIFY(writeFile(target, "old"));

    QVERIFY(CUtils::copyFile(QUrl::fromLocalFile(source), QUrl::fromLocalFile(target), true));
    QCOMPARE(readFile(target), QByteArray("new"));
}

void TestCUtils::copyFileKeepsTargetWithoutOverwrite() {
    const QTemporaryDir dir;
    QVERIFY(dir.isValid());

    const QString source = dir.filePath(QStringLiteral("source.txt"));
    const QString target = dir.filePath(QStringLiteral("target.txt"));
    QVERIFY(writeFile(source, "new"));
    QVERIFY(writeFile(target, "old"));

    QVERIFY(!CUtils::copyFile(QUrl::fromLocalFile(source), QUrl::fromLocalFile(target), false));
    QCOMPARE(readFile(target), QByteArray("old"));
}

void TestCUtils::copyFileFailsWhenRemoveFails() {
    const QTemporaryDir dir;
    QVERIFY(dir.isValid());

    const QString source = dir.filePath(QStringLiteral("source.txt"));
    const QString target = dir.filePath(QStringLiteral("target-dir"));
    QVERIFY(writeFile(source, "new"));
    QVERIFY(QDir().mkpath(target));
    QVERIFY(writeFile(target + QStringLiteral("/keep.txt"), "keep"));
    QVERIFY(QFile::exists(target));

    // Removing a non-empty directory fails, so the overwrite path must bail out
    QVERIFY(!CUtils::copyFile(QUrl::fromLocalFile(source), QUrl::fromLocalFile(target), true));
    QVERIFY(QFileInfo(target).isDir());
    QCOMPARE(readFile(target + QStringLiteral("/keep.txt")), QByteArray("keep"));
}

QTEST_GUILESS_MAIN(TestCUtils)
#include "tst_cutils.moc"
