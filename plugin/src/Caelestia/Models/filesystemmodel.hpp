#pragma once

#include <qabstractitemmodel.h>
#include <qdir.h>
#include <qfilesystemwatcher.h>
#include <qfuture.h>
#include <qimagereader.h>
#include <qmimedatabase.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>

namespace caelestia::models {

class FileSystemEntry : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("FileSystemEntry instances can only be retrieved from a FileSystemModel")

    Q_PROPERTY(QString path READ path CONSTANT)
    Q_PROPERTY(QString relativePath READ relativePath NOTIFY relativePathChanged)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString baseName READ baseName CONSTANT)
    Q_PROPERTY(QString parentDir READ parentDir CONSTANT)
    Q_PROPERTY(QString suffix READ suffix CONSTANT)
    Q_PROPERTY(qint64 size READ size CONSTANT)
    Q_PROPERTY(bool isDir READ isDir CONSTANT)
    Q_PROPERTY(bool isImage READ isImage CONSTANT)
    Q_PROPERTY(QString mimeType READ mimeType CONSTANT)

public:
    explicit FileSystemEntry(const QString& path, const QString& relativePath, QObject* parent = nullptr);

    [[nodiscard]] QString path() const;
    [[nodiscard]] QString relativePath() const;
    [[nodiscard]] QString name() const;
    [[nodiscard]] QString baseName() const;
    [[nodiscard]] QString parentDir() const;
    [[nodiscard]] QString suffix() const;
    [[nodiscard]] qint64 size() const;
    [[nodiscard]] bool isDir() const;
    [[nodiscard]] bool isImage() const;
    [[nodiscard]] QString mimeType() const;

    void updateRelativePath(const QDir& dir);

signals:
    void relativePathChanged();

private:
    const QFileInfo m_fileInfo;

    const QString m_path;
    QString m_relativePath;

    mutable bool m_isImage;
    mutable bool m_isImageInitialised;

    mutable QString m_mimeType;
    mutable bool m_mimeTypeInitialised;
};

class FileSystemModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(bool recursive READ recursive WRITE setRecursive NOTIFY recursiveChanged)
    Q_PROPERTY(bool watchChanges READ watchChanges WRITE setWatchChanges NOTIFY watchChangesChanged)
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
    Q_PROPERTY(bool sortReverse READ sortReverse WRITE setSortReverse NOTIFY sortReverseChanged)
    Q_PROPERTY(Filter filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(QStringList nameFilters READ nameFilters WRITE setNameFilters NOTIFY nameFiltersChanged)

    Q_PROPERTY(QQmlListProperty<caelestia::models::FileSystemEntry> entries READ entries NOTIFY entriesChanged)

public:
    enum Filter {
        NoFilter,
        Images,
        Files,
        Dirs
    };
    Q_ENUM(Filter)

    explicit FileSystemModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    [[nodiscard]] QString path() const;
    void setPath(const QString& path);

    [[nodiscard]] bool recursive() const;
    void setRecursive(bool recursive);

    [[nodiscard]] bool watchChanges() const;
    void setWatchChanges(bool watchChanges);

    [[nodiscard]] bool showHidden() const;
    void setShowHidden(bool showHidden);

    [[nodiscard]] bool sortReverse() const;
    void setSortReverse(bool sortReverse);

    [[nodiscard]] Filter filter() const;
    void setFilter(Filter filter);

    [[nodiscard]] QStringList nameFilters() const;
    void setNameFilters(const QStringList& nameFilters);

    [[nodiscard]] QQmlListProperty<FileSystemEntry> entries();

signals:
    void pathChanged();
    void recursiveChanged();
    void watchChangesChanged();
    void showHiddenChanged();
    void sortReverseChanged();
    void filterChanged();
    void nameFiltersChanged();
    void entriesChanged();

private:
    QDir m_dir;
    QFileSystemWatcher m_watcher;
    QList<FileSystemEntry*> m_entries;
    QHash<QString, QFuture<QPair<QSet<QString>, QSet<QString>>>> m_futures;

    QString m_path;
    bool m_recursive;
    bool m_watchChanges;
    bool m_showHidden;
    bool m_sortReverse;
    Filter m_filter;
    QStringList m_nameFilters;

    void watchDirIfRecursive(const QString& path);
    void update();
    void updateWatcher();
    void updateEntries();
    void updateEntriesForDir(const QString& dir);
    void applyChanges(const QSet<QString>& removedPaths, const QSet<QString>& addedPaths);
    [[nodiscard]] bool compareEntries(const FileSystemEntry* a, const FileSystemEntry* b) const;
};

} // namespace caelestia::models
