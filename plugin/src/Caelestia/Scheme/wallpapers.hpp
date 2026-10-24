#pragma once

#include <qfilesystemwatcher.h>
#include <qqmlintegration.h>

#include <caelestia/media/analysis.hpp>

#include "models/filesystemmodel.hpp"

namespace caelestia::shell::scheme {

class Wallpapers : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    /// Wallpapers follow the same commit model as Colours.
    Q_PROPERTY(bool committed READ committed NOTIFY committedChanged)

    Q_PROPERTY(QString current READ current NOTIFY currentChanged)
    Q_PROPERTY(QString currentCommitted READ currentCommitted NOTIFY currentCommittedChanged)

    Q_PROPERTY(QList<QColor> colours READ colours NOTIFY coloursChanged)

    Q_PROPERTY(caelestia::shell::models::FileSystemModel* model READ model CONSTANT)

public:
    static Wallpapers* instance();
    static Wallpapers* create(QQmlEngine* engine, QJSEngine* jsEngine);

    [[nodiscard]] bool committed() const;

    [[nodiscard]] QString current() const;

    [[nodiscard]] QString currentCommitted() const;

    [[nodiscard]] QList<QColor> colours() const;
    [[nodiscard]] const media::Analysis& analysis() const;

    [[nodiscard]] models::FileSystemModel* model() const;

    Q_INVOKABLE void commit();
    Q_INVOKABLE void reset();

    Q_INVOKABLE void setRandom(bool commit = true);
    Q_INVOKABLE void setWallpaper(const QString& path, bool commit = true);
    Q_INVOKABLE static QString defaultWallpaper();
    Q_INVOKABLE static QString categoryFor(const caelestia::shell::models::FileSystemEntry* entry);

signals:
    void committedChanged();
    void currentChanged();
    void currentCommittedChanged();
    void coloursChanged();

    void analysisDone(bool committed);

private:
    explicit Wallpapers(QObject* parent = nullptr);

    bool m_committed = true;
    QString m_current;
    QString m_currentCommitted;

    media::Analysis m_analysis;
    QFileSystemWatcher m_watcher;
    models::FileSystemModel* const m_model;

    void loadState();
    void applyState(const QString& path, bool committed);

    void watch(const QString& path);
    void handleFileChanged(const QString& path);
    void handleDirectoryChanged();
};

} // namespace caelestia::shell::scheme
