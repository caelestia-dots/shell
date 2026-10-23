#include "wallpapers.hpp"

#include <caelestia/wallpaper/wallpaper.hpp>

namespace caelestia::shell::scheme {

Wallpapers::Wallpapers(QObject* parent)
    : QObject(parent) {}

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

void Wallpapers::setWallpaper(const QString& path, bool commit) {
    if (m_current == path)
        return;

    m_current = path;
    emit currentChanged();

    if (commit) {
        m_committed = false;
        this->commit();
    }
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

void Wallpapers::commit() {
    if (m_committed)
        return;

    wallpaper::set(m_current).then(this, [this] {
        if (m_current != m_currentCommitted) {
            m_currentCommitted = m_current;
            emit currentCommittedChanged();
        }
        if (!m_committed) {
            m_committed = true;
            emit committedChanged();
        }
    });
}

void Wallpapers::reset() {
    if (m_committed)
        return;

    // TODO
}

} // namespace caelestia::shell::scheme
