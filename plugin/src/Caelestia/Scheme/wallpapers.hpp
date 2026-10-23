#pragma once

#include <qqmlintegration.h>

#include <caelestia/media/analysis.hpp>

namespace caelestia::shell::scheme {

class Wallpapers : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    /// Wallpapers follow the same commit model as Colours.
    Q_PROPERTY(bool committed READ committed NOTIFY committedChanged)

    Q_PROPERTY(QString current READ current WRITE setWallpaper NOTIFY currentChanged)
    Q_PROPERTY(QString currentCommitted READ currentCommitted NOTIFY currentCommittedChanged)

    Q_PROPERTY(QList<QColor> colours READ colours NOTIFY coloursChanged)

public:
    static Wallpapers* instance();
    static Wallpapers* create(QQmlEngine* engine, QJSEngine* jsEngine);

    [[nodiscard]] bool committed() const;

    [[nodiscard]] QString current() const;
    Q_INVOKABLE void setWallpaper(const QString& path, bool commit = false);

    [[nodiscard]] QString currentCommitted() const;

    [[nodiscard]] QList<QColor> colours() const;
    [[nodiscard]] const media::Analysis& analysis() const;

    Q_INVOKABLE void commit();
    Q_INVOKABLE void reset();

signals:
    void committedChanged();
    void currentChanged();
    void currentCommittedChanged();
    void coloursChanged();

    void analysisDone();

private:
    explicit Wallpapers(QObject* parent = nullptr);

    bool m_committed = false;
    QString m_current;
    QString m_currentCommitted;

    media::Analysis m_analysis;
};

} // namespace caelestia::shell::scheme
