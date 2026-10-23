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

    Q_PROPERTY(QString current READ current WRITE setCurrent NOTIFY currentChanged)
    Q_PROPERTY(QString currentCommitted READ currentCommitted NOTIFY currentCommittedChanged)

    Q_PROPERTY(QList<QColor> colours READ colours NOTIFY coloursChanged)

public:
    static Wallpapers* instance();
    static Wallpapers* create(QQmlEngine* engine, QJSEngine* jsEngine);

    [[nodiscard]] bool committed() const;

    [[nodiscard]] QString current() const;
    void setCurrent(const QString& current);

    [[nodiscard]] QString currentCommitted() const;

    [[nodiscard]] QList<QColor> colours() const;
    [[nodiscard]] Q_INVOKABLE QList<QColor> coloursFor(const QString& path) const;

    [[nodiscard]] const media::Analysis& analysis() const;

signals:
    void committedChanged();
    void currentChanged();
    void currentCommittedChanged();
    void coloursChanged();

    void analysisDone();

private:
    explicit Wallpapers(QObject* parent = nullptr);

    media::Analysis m_analysis;
};

} // namespace caelestia::shell::scheme
