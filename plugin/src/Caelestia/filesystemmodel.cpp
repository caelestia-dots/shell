#include "filesystemmodel.hpp"

#include <QAbstractListModel>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QImageReader>
#include <QObject>
#include <qqmlintegration.h>

int FileSystemModel::rowCount(const QModelIndex& parent) const {
    if (parent != QModelIndex()) {
        return 0;
    }
    return static_cast<int>(m_entries.size());
}

QVariant FileSystemModel::data(const QModelIndex& index, int role) const {
    if (role != Qt::UserRole || !index.isValid() || index.row() >= m_entries.size()) {
        return QVariant();
    }
    return QVariant::fromValue(m_entries.at(index.row()));
}

QHash<int, QByteArray> FileSystemModel::roleNames() const {
    return { { Qt::UserRole, "modelData" } };
}

QString FileSystemModel::path() const {
    return m_path;
}

void FileSystemModel::setPath(const QString& path) {
    if (m_path == path) {
        return;
    }

    m_path = path;
    emit pathChanged();

    m_dir.setPath(m_path);
    update();
}

bool FileSystemModel::recursive() const {
    return m_recursive;
}

void FileSystemModel::setRecursive(bool recursive) {
    if (m_recursive == recursive) {
        return;
    }

    m_recursive = recursive;
    emit recursiveChanged();

    update();
}

FileSystemModel::Filter FileSystemModel::filter() const {
    return m_filter;
}

void FileSystemModel::setFilter(Filter filter) {
    if (m_filter == filter) {
        return;
    }

    m_filter = filter;
    emit filterChanged();

    update();
}

QList<FileSystemEntry*> FileSystemModel::entries() const {
    return m_entries;
}

void FileSystemModel::watchDirIfRecursive(const QString& path) {
    if (m_recursive) {
        QDirIterator iter(path, QDir::Dirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
        while (iter.hasNext()) {
            m_watcher.addPath(iter.next());
        }
    }
}

void FileSystemModel::update() {
    updateWatcher();
    updateEntries();
}

void FileSystemModel::updateWatcher() {
    if (!m_watcher.directories().isEmpty()) {
        m_watcher.removePaths(m_watcher.directories());
    }

    if (m_path.isEmpty()) {
        return;
    }

    m_watcher.addPath(m_path);
    watchDirIfRecursive(m_path);
}

void FileSystemModel::updateEntries() {
    if (m_path.isEmpty()) {
        if (!m_entries.isEmpty()) {
            beginResetModel();
            qDeleteAll(m_entries);
            m_entries.clear();
            emit entriesChanged();
            endResetModel();
        }

        return;
    }

    const auto flags = m_recursive ? QDirIterator::Subdirectories : QDirIterator::NoIteratorFlags;

    std::optional<QDirIterator> iter;

    if (m_filter == Images) {
        QStringList filters;
        for (const auto& format : QImageReader::supportedImageFormats()) {
            filters << "*." + format;
        }

        iter.emplace(m_path, filters, QDir::Files, flags);
    } else if (m_filter == Files) {
        iter.emplace(m_path, QDir::Files, flags);
    } else {
        iter.emplace(m_path, QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot, flags);
    }

    QSet<QString> newPaths;
    while (iter->hasNext()) {
        QString path = iter->next();

        if (m_filter == Images) {
            QImageReader reader(path);
            if (!reader.canRead()) {
                continue;
            }
        }

        newPaths.insert(path);
    }

    QSet<QString> oldPaths;
    for (const auto& entry : m_entries) {
        oldPaths.insert(entry->path());
    }

    if (newPaths == oldPaths) {
        return;
    }

    const QSet<QString> removedPaths = oldPaths - newPaths;
    const QSet<QString> addedPaths = newPaths - oldPaths;

    beginResetModel();

    const int numEntries = static_cast<int>(m_entries.size());
    for (int i = numEntries - 1; i >= 0; --i) {
        if (removedPaths.contains(m_entries[i]->path())) {
            delete m_entries.takeAt(i);
        }
    }

    for (const auto& path : addedPaths) {
        m_entries << new FileSystemEntry(path, m_dir.relativeFilePath(path), this);
    }

    std::sort(m_entries.begin(), m_entries.end(), [](const FileSystemEntry* a, const FileSystemEntry* b) {
        return a->relativePath().localeAwareCompare(b->relativePath()) < 0;
    });

    emit entriesChanged();

    endResetModel();
}
