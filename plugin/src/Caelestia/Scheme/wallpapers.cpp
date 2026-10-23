#include "wallpapers.hpp"

#include <qdir.h>
#include <qfileinfo.h>

#include <caelestia/wallpaper/wallpaper.hpp>

#include "config/rootnodes.hpp"
#include "config/userpaths.hpp"

namespace caelestia::shell::scheme {

namespace {

QString wallpaperDir() {
    // TODO: migrate to lib ConfigPaths::wallpaperDir
    return config::ConfigSingleton::instance()->paths()->wallpaperDir();
}

} // namespace

Wallpapers::Wallpapers(QObject* parent)
    : QObject(parent)
    , m_model(new models::FileSystemModel(this)) {
    m_model->setRecursive(true);
    m_model->setFilter(models::FileSystemModel::Filter::Images | models::FileSystemModel::Filter::Videos);
    m_model->setPath(wallpaperDir());
    connect(config::ConfigSingleton::instance()->paths(), &config::UserPaths::wallpaperDirChanged, this, [this] {
        m_model->setPath(wallpaperDir());
    });

    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &Wallpapers::handleFileChanged);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &Wallpapers::handleDirectoryChanged);

    const auto dir = QFileInfo(wallpaper::statePath()).path();
    QDir().mkpath(dir);
    m_watcher.addPath(dir);
    watch(wallpaper::statePath());

    loadState();
}

Wallpapers* Wallpapers::instance() {
    static Wallpapers s_instance;
    return &s_instance;
}

Wallpapers* Wallpapers::create(QQmlEngine* engine, QJSEngine* jsEngine) {
    Q_UNUSED(engine);
    Q_UNUSED(jsEngine);

    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

bool Wallpapers::committed() const {
    return m_committed;
}

QString Wallpapers::current() const {
    return m_current;
}

QString Wallpapers::currentCommitted() const {
    return m_currentCommitted;
}

QList<QColor> Wallpapers::colours() const {
    return m_analysis.colours;
}

const media::Analysis& Wallpapers::analysis() const {
    return m_analysis;
}

models::FileSystemModel* Wallpapers::model() const {
    return m_model;
}

void Wallpapers::commit() {
    if (m_committed)
        return;

    wallpaper::set(m_current).then(this, [this] {
        applyState(m_current, true);
    });
}

void Wallpapers::reset() {
    if (m_committed)
        return;

    loadState();
}

void Wallpapers::setWallpaper(const QString& path, bool commit) {
    applyState(path, false);

    if (commit)
        this->commit();
}

QString Wallpapers::defaultWallpaper() {
    return wallpaper::defaultWallpaper();
}

QString Wallpapers::categoryFor(const models::FileSystemEntry* entry) {
    auto category = entry->parentDir().mid(wallpaperDir().size() + 1);
    if (const auto idx = category.indexOf(u'/'); idx != -1)
        return category.mid(0, idx);
    return category;
}

void Wallpapers::loadState() {
    bool ok = false;
    const auto path = wallpaper::currentWallpaper(&ok);
    applyState(ok ? path : wallpaper::defaultWallpaper(), true);
}

void Wallpapers::applyState(const QString& path, bool committed) {
    if (m_current != path) {
        m_current = path;
        emit currentChanged();

        media::analyseForPath(path).then(this, [this, path](const media::Analysis& analysis) {
            if (path != m_current)
                return;

            const auto oldColours = m_analysis.colours;
            m_analysis = analysis;

            if (oldColours != m_analysis.colours)
                emit coloursChanged();
            emit analysisDone();
        });
    }

    if (committed && m_currentCommitted != path) {
        m_currentCommitted = path;
        emit currentCommittedChanged();
    }

    if (!committed && m_committed) {
        m_committed = false;
        emit committedChanged();
    }
}

void Wallpapers::watch(const QString& path) {
    if (QFileInfo::exists(path) && !m_watcher.files().contains(path))
        m_watcher.addPath(path);
}

void Wallpapers::handleFileChanged(const QString& path) {
    watch(path);
    if (path == wallpaper::statePath())
        loadState();
}

void Wallpapers::handleDirectoryChanged() {
    const auto path = wallpaper::statePath();
    if (m_watcher.files().contains(path))
        return;

    watch(path);

    if (m_watcher.files().contains(path))
        handleFileChanged(path);
}

} // namespace caelestia::shell::scheme
