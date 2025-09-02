#pragma once

#include <QAbstractListModel>
#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QImageReader>
#include <QObject>
#include <qqmlintegration.h>

class FileSystemEntry : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("FileSystemEntry instances can only be retrieved from a FileSystemModel")

    Q_PROPERTY(QString path READ path CONSTANT)
    Q_PROPERTY(QString relativePath READ relativePath CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString parentDir READ parentDir CONSTANT)
    Q_PROPERTY(qint64 size READ size CONSTANT)
    Q_PROPERTY(bool isDir READ isDir CONSTANT)
    Q_PROPERTY(bool isImage READ isImage CONSTANT)

public:
    explicit FileSystemEntry(const QString& path, const QString& relativePath, QObject* parent = nullptr)
        : QObject(parent)
        , m_fileInfo(QFileInfo(path))
        , m_path(path)
        , m_relativePath(relativePath) {}

    QString path() const { return m_path; };
    QString relativePath() const { return m_relativePath; };

    QString name() const { return m_fileInfo.fileName(); };
    QString parentDir() const { return m_fileInfo.absolutePath(); };
    qint64 size() const { return m_fileInfo.size(); };
    bool isDir() const { return m_fileInfo.isDir(); };

    bool isImage() {
        if (!m_isImageInitialised) {
            QImageReader reader(m_path);
            m_isImage = reader.canRead();
            m_isImageInitialised = true;
        }
        return m_isImage;
    }

private:
    const QFileInfo m_fileInfo;

    const QString m_path;
    const QString m_relativePath;

    bool m_isImage;
    bool m_isImageInitialised;
};

class FileSystemModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(bool recursive READ recursive WRITE setRecursive NOTIFY recursiveChanged)
    Q_PROPERTY(Filter filter READ filter WRITE setFilter NOTIFY filterChanged)

    Q_PROPERTY(QList<FileSystemEntry*> entries READ entries NOTIFY entriesChanged)

public:
    enum Filter {
        NoFilter,
        Images,
        Files
    };
    Q_ENUM(Filter)

    explicit FileSystemModel(QObject* parent = nullptr)
        : QAbstractListModel(parent)
        , m_recursive(true)
        , m_filter(NoFilter) {
        connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &FileSystemModel::watchDirIfRecursive);
        connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &FileSystemModel::updateEntries);
    }

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString path() const;
    void setPath(const QString& path);

    bool recursive() const;
    void setRecursive(bool recursive);

    Filter filter() const;
    void setFilter(Filter filter);

    QList<FileSystemEntry*> entries() const;

signals:
    void pathChanged();
    void recursiveChanged();
    void filterChanged();
    void entriesChanged();

private:
    QDir m_dir;
    QFileSystemWatcher m_watcher;
    QList<FileSystemEntry*> m_entries;

    QString m_path;
    bool m_recursive;
    Filter m_filter;

    void watchDirIfRecursive(const QString& path);
    void update();
    void updateWatcher();
    void updateEntries();
};
