#pragma once

#include "config.hpp"

#include <qquickattachedpropertypropagator.h>

namespace caelestia::config {

class Config : public QQuickAttachedPropertyPropagator, public QQmlParserStatus {
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    QML_ELEMENT
    QML_UNCREATABLE("")
    QML_ATTACHED(Config)

    Q_PROPERTY(QString screen READ screen WRITE inheritScreen NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearanceConfig* appearance READ appearance NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::GeneralConfig* general READ general NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::BackgroundConfig* background READ background NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::BarConfig* bar READ bar NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::BorderConfig* border READ border NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::DashboardConfig* dashboard READ dashboard NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::ControlCenterConfig* controlCenter READ controlCenter NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::LauncherConfig* launcher READ launcher NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::NotifsConfig* notifs READ notifs NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::OsdConfig* osd READ osd NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::SessionConfig* session READ session NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::WInfoConfig* winfo READ winfo NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::LockConfig* lock READ lock NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::UtilitiesConfig* utilities READ utilities NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::SidebarConfig* sidebar READ sidebar NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::ServiceConfig* services READ services NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::UserPaths* paths READ paths NOTIFY sourceChanged)

public:
    explicit Config(QObject* parent = nullptr);

    [[nodiscard]] QString screen() const;
    void inheritScreen(const QString& screen);

    [[nodiscard]] const AppearanceConfig* appearance() const;
    [[nodiscard]] const GeneralConfig* general() const;
    [[nodiscard]] const BackgroundConfig* background() const;
    [[nodiscard]] const BarConfig* bar() const;
    [[nodiscard]] const BorderConfig* border() const;
    [[nodiscard]] const DashboardConfig* dashboard() const;
    [[nodiscard]] const ControlCenterConfig* controlCenter() const;
    [[nodiscard]] const LauncherConfig* launcher() const;
    [[nodiscard]] const NotifsConfig* notifs() const;
    [[nodiscard]] const OsdConfig* osd() const;
    [[nodiscard]] const SessionConfig* session() const;
    [[nodiscard]] const WInfoConfig* winfo() const;
    [[nodiscard]] const LockConfig* lock() const;
    [[nodiscard]] const UtilitiesConfig* utilities() const;
    [[nodiscard]] const SidebarConfig* sidebar() const;
    [[nodiscard]] const ServiceConfig* services() const;
    [[nodiscard]] const UserPaths* paths() const;

    [[nodiscard]] Q_INVOKABLE static GlobalConfig* forScreen(const QString& screen);

    static Config* qmlAttachedProperties(QObject* object);

signals:
    void sourceChanged();

protected:
    void attachedParentChange(
        QQuickAttachedPropertyPropagator* newParent, QQuickAttachedPropertyPropagator* oldParent) override;

private:
    void classBegin() override;
    void componentComplete() override;

    void propagateScreen();

    bool m_complete = false;
    QString m_screen;
    GlobalConfig* m_config = nullptr;
};

} // namespace caelestia::config
