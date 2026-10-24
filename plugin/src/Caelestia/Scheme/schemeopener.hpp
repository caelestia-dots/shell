#pragma once

#include <qqmlintegration.h>
#include <qqmlparserstatus.h>

#include "colours.hpp"

namespace caelestia::shell::scheme {

class SchemeOpener : public QObject, public QQmlParserStatus {
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    QML_ELEMENT

    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString flavour READ flavour WRITE setFlavour NOTIFY flavourChanged)
    Q_PROPERTY(caelestia::shell::scheme::Colours::Mode mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(bool smart READ smart WRITE setSmart NOTIFY smartChanged)

    Q_PROPERTY(caelestia::shell::scheme::ColourPalette* palette READ palette CONSTANT)

public:
    explicit SchemeOpener(QObject* parent = nullptr);

    [[nodiscard]] QString name() const;
    void setName(const QString& name);

    [[nodiscard]] QString flavour() const;
    void setFlavour(const QString& flavour);

    [[nodiscard]] Colours::Mode mode() const;
    void setMode(Colours::Mode mode);

    [[nodiscard]] bool smart() const;
    void setSmart(bool smart);

    [[nodiscard]] ColourPalette* palette() const;

    void classBegin() override;
    void componentComplete() override;

signals:
    void nameChanged();
    void flavourChanged();
    void modeChanged();
    void smartChanged();

private:
    QString m_name;
    QString m_flavour;
    Colours::Mode m_mode = Colours::Mode::Dark;
    bool m_smart = false;
    ColourPalette* const m_palette;

    bool m_complete = false;
    quint64 m_generation = 0;

    void resolve();
};

} // namespace caelestia::shell::scheme
