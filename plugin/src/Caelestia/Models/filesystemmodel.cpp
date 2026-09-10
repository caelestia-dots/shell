#include "filesystemmodel.hpp"

#include <qdiriterator.h>
#include <qtconcurrentrun.h>

#include <algorithm>
#include <optional>
#include <utility>

namespace caelestia::models {

using Qt::StringLiterals::operator""_s;
using Qt::StringLiterals::operator""_ba;

FileSystemEntry::FileSystemEntry(const QString& path, QString relativePath, QObject* parent)
    : QObject(parent)
    , m_fileInfo(path)
    , m_path(path)
    , m_relativePath(std::move(relativePath))
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
        const QImageReader reader(m_path);
        m_isImage = reader.canRead();
        m_isImageInitialised = true;
    }
    return m_isImage;
}

QString FileSystemEntry::mimeType() const {
    if (!m_mimeTypeInitialised) {
        static const QMimeDatabase k_db;
        m_mimeType = k_db.mimeTypeForFile(m_path).name();
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
    , m_filter(Filter::NoFilter) {
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
        return {};
    }
    return QVariant::fromValue(m_entries.at(index.row()));
}

QHash<int, QByteArray> FileSystemModel::roleNames() const {
    return { { Qt::UserRole, "modelData"_ba } };
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
    return { this, &m_entries };
}

void FileSystemModel::watchDirIfRecursive(const QString& path) {
    if (m_recursive && m_watchChanges) {
        const auto currentDir = m_dir;
        const bool showHidden = m_showHidden;
        auto future = QtConcurrent::run([showHidden, path]() {
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
        future.then(this, [currentDir, showHidden, this](const QStringList& paths) {
            if (currentDir == m_dir && showHidden == m_showHidden && !paths.isEmpty()) {
                // Ignore if dir or showHidden has changed
                m_watcher.addPaths(paths);
            }
        });
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

    auto future = QtConcurrent::run([=](QPromise<PathDiff>& promise) {
        const auto flags = recursive ? QDirIterator::Subdirectories : QDirIterator::NoIteratorFlags;
        const auto newPaths = scanDir(dir, filtersFor(filter, nameFilters, showHidden), flags, promise);
        if (!newPaths)
            return;

        promise.addResult({ .removed = oldPaths - *newPaths, .added = *newPaths - oldPaths });
    });

    if (m_futures.contains(dir))
        m_futures[dir].cancel();
    m_futures.insert(dir, future);

    future
        .then(this,
            [dir, this](const PathDiff& result) {
                m_futures.remove(dir);
                if (!result.removed.isEmpty() || !result.added.isEmpty())
                    applyChanges(result.removed, result.added);
            })
        .onCanceled(this, [dir, this]() {
            m_futures.remove(dir);
        });
}

FileSystemModel::ScanFilters FileSystemModel::filtersFor(
    Filter filter, const QStringList& nameFilters, bool showHidden) {
    ScanFilters filters;
    filters.nameFilters = nameFilters;

    if (filter == Filter::Images) {
        const auto formats = QImageReader::supportedImageFormats();
        for (const auto& format : formats)
            filters.nameFilters << u"*."_s + QString::fromUtf8(format);

        filters.filterFn = [](const QString& path) {
            return QImageReader(path).canRead();
        };
    }

    if (filter == Filter::Files || filter == Filter::Images)
        filters.filters = QDir::Files;
    else if (filter == Filter::Dirs)
        filters.filters = QDir::Dirs | QDir::NoDotAndDotDot;
    else
        filters.filters = QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot;

    if (showHidden)
        filters.filters |= QDir::Hidden;

    return filters;
}

std::optional<QSet<QString>> FileSystemModel::scanDir(const QString& dir, const ScanFilters& filters,
    QDirIterator::IteratorFlags flags, const QPromise<PathDiff>& promise) {
    std::optional<QDirIterator> iter;
    if (filters.nameFilters.isEmpty())
        iter.emplace(dir, filters.filters, flags);
    else
        iter.emplace(dir, filters.nameFilters, filters.filters, flags);

    QSet<QString> paths;
    while (iter->hasNext()) {
        if (promise.isCanceled())
            return std::nullopt;

        const QString path = iter->next();
        if (filters.filterFn && !filters.filterFn(path))
            continue;

        paths.insert(path);
    }

    if (promise.isCanceled())
        return std::nullopt;

    return paths;
}

void FileSystemModel::applyChanges(const QSet<QString>& removedPaths, const QSet<QString>& addedPaths) {
    QList<int> removedIndices;
    for (int i = 0; i < m_entries.size(); ++i) {
        if (removedPaths.contains(m_entries[i]->path())) {
            removedIndices << i;
        }
    }
    std::ranges::sort(removedIndices, std::greater<>());

    // Batch remove old entries
    int start = -1;
    int end = -1;
    for (const int idx : std::as_const(removedIndices)) {
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
    std::ranges::sort(newEntries, [this](const FileSystemEntry* a, const FileSystemEntry* b) {
        return compareEntries(a, b);
    });

    // Batch insert new entries (each run lands contiguously before m_entries[row])
    int i = 0;
    while (i < newEntries.size()) {
        const auto it = std::ranges::lower_bound(
            m_entries, newEntries[i], [this](const FileSystemEntry* a, const FileSystemEntry* b) {
                return compareEntries(a, b);
            });
        const auto row = static_cast<int>(it - m_entries.begin());

        // Extend the run while the next new entry still sorts before the existing element at row
        int j = i + 1;
        while (j < newEntries.size() && (row >= m_entries.size() || compareEntries(newEntries[j], m_entries[row]))) {
            ++j;
        }

        beginInsertRows(QModelIndex(), row, row + (j - i) - 1);
        for (int k = i; k < j; ++k) {
            m_entries.insert(row + (k - i), newEntries[k]);
        }
        endInsertRows();

        i = j;
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
