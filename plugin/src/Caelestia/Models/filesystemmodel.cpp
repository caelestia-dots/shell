#include "filesystemmodel.hpp"

#include <qdiriterator.h>
#include <qfuturewatcher.h>
#include <qtconcurrentrun.h>

namespace caelestia::models {

static bool isVideoFile(const QString& path) {
    static const QStringList videoExtensions = { "mp4", "mkv", "webm", "avi", "mov", "flv", "wmv" };
    const QString ext = QFileInfo(path).suffix().toLower();
    return videoExtensions.contains(ext);
}

FileSystemEntry::FileSystemEntry(const QString& path, const QString& relativePath, QObject* parent)
    : QObject(parent)
    , m_fileInfo(path)
    , m_path(path)
    , m_relativePath(relativePath)
    , m_isImageInitialised(false)
    , m_mimeTypeInitialised(false) {}

QString FileSystemEntry::path() const {
    return m_path;
};

QString FileSystemEntry::relativePath() const {
    return m_relativePath;
};

QString FileSystemEntry::name() const {
    return m_fileInfo.fileName();
};

QString FileSystemEntry::baseName() const {
    return m_fileInfo.baseName();
};

QString FileSystemEntry::parentDir() const {
    return m_fileInfo.absolutePath();
};

QString FileSystemEntry::suffix() const {
    return m_fileInfo.completeSuffix();
};

qint64 FileSystemEntry::size() const {
    return m_fileInfo.size();
};

bool FileSystemEntry::isDir() const {
    return m_fileInfo.isDir();
};

bool FileSystemEntry::isImage() const {
    if (!m_isImageInitialised) {
        QImageReader reader(m_path);
        m_isImage = reader.canRead();
        m_isImageInitialised = true;
    }
    return m_isImage;
}

QString FileSystemEntry::mimeType() const {
    if (!m_mimeTypeInitialised) {
        const QMimeDatabase db;
        m_mimeType = db.mimeTypeForFile(m_path).name();
        m_mimeTypeInitialised = true;
    }
    return m_mimeType;
}

void FileSystemEntry::updateRelativePath(const QDir& dir) {
    const auto relPath = dir.relativeFilePath(m_path);
    if (m_relativePath != relPath) {
        m_relativePath = relPath;
        emit relativePathChanged();
    }
}

FileSystemModel::FileSystemModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_recursive(false)
    , m_watchChanges(true)
    , m_showHidden(false)
    , m_filter(NoFilter) {
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &FileSystemModel::watchDirIfRecursive);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &FileSystemModel::updateEntriesForDir);
}

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

    for (const auto& entry : std::as_const(m_entries)) {
        entry->updateRelativePath(m_dir);
    }

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

bool FileSystemModel::watchChanges() const {
    return m_watchChanges;
}

void FileSystemModel::setWatchChanges(bool watchChanges) {
    if (m_watchChanges == watchChanges) {
        return;
    }

    m_watchChanges = watchChanges;
    emit watchChangesChanged();

    update();
}

bool FileSystemModel::showHidden() const {
    return m_showHidden;
}

void FileSystemModel::setShowHidden(bool showHidden) {
    if (m_showHidden == showHidden) {
        return;
    }

    m_showHidden = showHidden;
    emit showHiddenChanged();

    update();
}

bool FileSystemModel::sortReverse() const {
    return m_sortReverse;
}

void FileSystemModel::setSortReverse(bool sortReverse) {
    if (m_sortReverse == sortReverse) {
        return;
    }

    m_sortReverse = sortReverse;
    emit sortReverseChanged();

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

QStringList FileSystemModel::nameFilters() const {
    return m_nameFilters;
}

void FileSystemModel::setNameFilters(const QStringList& nameFilters) {
    if (m_nameFilters == nameFilters) {
        return;
    }

    m_nameFilters = nameFilters;
    emit nameFiltersChanged();

    update();
}

QQmlListProperty<FileSystemEntry> FileSystemModel::entries() {
    return QQmlListProperty<FileSystemEntry>(this, &m_entries);
}

void FileSystemModel::watchDirIfRecursive(const QString& path) {
    if (m_recursive && m_watchChanges) {
        const auto currentDir = m_dir;
        const bool showHidden = m_showHidden;
        const auto future = QtConcurrent::run([showHidden, path]() {
            QDir::Filters filters = QDir::Dirs | QDir::NoDotAndDotDot;
            if (showHidden) {
                filters |= QDir::Hidden;
            }

            QDirIterator iter(path, filters, QDirIterator::Subdirectories);
            QStringList dirs;
            while (iter.hasNext()) {
                dirs << iter.next();
            }
            return dirs;
        });
        const auto watcher = new QFutureWatcher<QStringList>(this);
        connect(watcher, &QFutureWatcher<QStringList>::finished, this, [currentDir, showHidden, watcher, this]() {
            const auto paths = watcher->result();
            if (currentDir == m_dir && showHidden == m_showHidden && !paths.isEmpty()) {
                // Ignore if dir or showHidden has changed
                m_watcher.addPaths(paths);
            }
            watcher->deleteLater();
        });
        watcher->setFuture(future);
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

    if (!m_watchChanges || m_path.isEmpty()) {
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
            endResetModel();
            emit entriesChanged();
        }

        return;
    }

    for (auto& future : m_futures) {
        future.cancel();
    }
    m_futures.clear();

    updateEntriesForDir(m_path);
}

void FileSystemModel::updateEntriesForDir(const QString& dir) {
    const auto recursive = m_recursive;
    const auto showHidden = m_showHidden;
    const auto filter = m_filter;
    const auto nameFilters = m_nameFilters;

    QSet<QString> oldPaths;
    for (const auto& entry : std::as_const(m_entries))
        oldPaths << entry->path();

    const auto future = QtConcurrent::run([=](QPromise<QPair<QSet<QString>, QSet<QString>>>& promise) {
        const auto flags = recursive ? QDirIterator::Subdirectories : QDirIterator::NoIteratorFlags;

        QSet<QString> newPaths;

        // Build name filters dynamically
        if (filter == Images || filter == Videos || filter == ImagesAndVideos) {
            QStringList extraNameFilters = nameFilters;

            if (filter == Images || filter == ImagesAndVideos) {
                const auto formats = QImageReader::supportedImageFormats();
                for (const auto& fmt : formats) {
                    extraNameFilters << "*." + QString::fromLatin1(fmt);
                }
            }

            if (filter == Videos || filter == ImagesAndVideos) {
                extraNameFilters << "*.mp4" << "*.mkv" << "*.webm"
                                 << "*.avi" << "*.mov" << "*.flv" << "*.wmv";
            }

            QDir::Filters dirFilters = QDir::Files;
            if (showHidden)
                dirFilters |= QDir::Hidden;

            QDirIterator iter(dir, extraNameFilters, dirFilters, flags);
            while (iter.hasNext()) {
                if (promise.isCanceled())
                    return;
                const QString path = iter.next();

                // Determine whether to keep file
                bool isImage = QImageReader(path).canRead();
                bool isVideo = isVideoFile(path);

                if (filter == Images && !isImage)
                    continue;
                if (filter == Videos && !isVideo)
                    continue;
                if (filter == ImagesAndVideos && !isImage && !isVideo)
                    continue;

                newPaths.insert(path);
            }

        } else {
            // fallback for Files / Dirs / All
            QDir::Filters dirFilters;
            if (filter == Files)
                dirFilters = QDir::Files;
            else if (filter == Dirs)
                dirFilters = QDir::Dirs | QDir::NoDotAndDotDot;
            else
                dirFilters = QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot;

            if (showHidden)
                dirFilters |= QDir::Hidden;

            QDirIterator iter(dir, nameFilters, dirFilters, flags);
            while (iter.hasNext()) {
                if (promise.isCanceled())
                    return;
                newPaths.insert(iter.next());
            }
        }

        if (!promise.isCanceled() && newPaths != oldPaths) {
            promise.addResult(qMakePair(oldPaths - newPaths, newPaths - oldPaths));
        }
    });

    if (m_futures.contains(dir))
        m_futures[dir].cancel();
    m_futures.insert(dir, future);

    const auto watcher = new QFutureWatcher<QPair<QSet<QString>, QSet<QString>>>(this);
    connect(watcher, &QFutureWatcher<QPair<QSet<QString>, QSet<QString>>>::finished, this, [this, dir, watcher]() {
        m_futures.remove(dir);

        if (!watcher->future().isResultReadyAt(0)) {
            watcher->deleteLater();
            return;
        }

        const auto result = watcher->result();
        applyChanges(result.first, result.second);

        watcher->deleteLater();
    });

    watcher->setFuture(future);
}

void FileSystemModel::applyChanges(const QSet<QString>& removedPaths, const QSet<QString>& addedPaths) {
    QList<int> removedIndices;
    for (int i = 0; i < m_entries.size(); ++i) {
        if (removedPaths.contains(m_entries[i]->path())) {
            removedIndices << i;
        }
    }
    std::sort(removedIndices.begin(), removedIndices.end(), std::greater<int>());

    // Batch remove old entries
    int start = -1;
    int end = -1;
    for (int idx : std::as_const(removedIndices)) {
        if (start == -1) {
            start = idx;
            end = idx;
        } else if (idx == end - 1) {
            end = idx;
        } else {
            beginRemoveRows(QModelIndex(), end, start);
            for (int i = start; i >= end; --i) {
                m_entries.takeAt(i)->deleteLater();
            }
            endRemoveRows();

            start = idx;
            end = idx;
        }
    }
    if (start != -1) {
        beginRemoveRows(QModelIndex(), end, start);
        for (int i = start; i >= end; --i) {
            m_entries.takeAt(i)->deleteLater();
        }
        endRemoveRows();
    }

    // Create new entries
    QList<FileSystemEntry*> newEntries;
    for (const auto& path : addedPaths) {
        newEntries << new FileSystemEntry(path, m_dir.relativeFilePath(path), this);
    }
    std::sort(newEntries.begin(), newEntries.end(), [this](const FileSystemEntry* a, const FileSystemEntry* b) {
        return compareEntries(a, b);
    });

    // Batch insert new entries
    int insertStart = -1;
    QList<FileSystemEntry*> batchItems;
    for (const auto& entry : std::as_const(newEntries)) {
        const auto it = std::lower_bound(
            m_entries.begin(), m_entries.end(), entry, [this](const FileSystemEntry* a, const FileSystemEntry* b) {
                return compareEntries(a, b);
            });
        const auto row = static_cast<int>(it - m_entries.begin());

        if (insertStart == -1) {
            insertStart = row;
            batchItems << entry;
        } else if (row == insertStart + batchItems.size()) {
            batchItems << entry;
        } else {
            beginInsertRows(QModelIndex(), insertStart, insertStart + static_cast<int>(batchItems.size()) - 1);
            for (int i = 0; i < batchItems.size(); ++i) {
                m_entries.insert(insertStart + i, batchItems[i]);
            }
            endInsertRows();

            insertStart = row;
            batchItems.clear();
            batchItems << entry;
        }
    }
    if (!batchItems.isEmpty()) {
        beginInsertRows(QModelIndex(), insertStart, insertStart + static_cast<int>(batchItems.size()) - 1);
        for (int i = 0; i < batchItems.size(); ++i) {
            m_entries.insert(insertStart + i, batchItems[i]);
        }
        endInsertRows();
    }

    emit entriesChanged();
}

bool FileSystemModel::compareEntries(const FileSystemEntry* a, const FileSystemEntry* b) const {
    if (a->isDir() != b->isDir()) {
        return m_sortReverse ^ a->isDir();
    }
    const auto cmp = a->relativePath().localeAwareCompare(b->relativePath());
    return m_sortReverse ? cmp > 0 : cmp < 0;
}

} // namespace caelestia::models
