#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qtimer.h>

#include <caelestia/utils/cache.hpp>

namespace caelestia::shell::models {

class NotifData;

struct NotifAction {
    Q_GADGET
    QML_VALUE_TYPE(notifAction)

    Q_PROPERTY(QString identifier READ identifier CONSTANT)
    Q_PROPERTY(QString text READ text CONSTANT)

public:
    NotifAction() = default;
    NotifAction(NotifData* parent, QString identifier, QString text, QObject* backer = nullptr);

    [[nodiscard]] QString identifier() const;
    [[nodiscard]] QString text() const;

    Q_INVOKABLE void invoke();

    bool operator==(const NotifAction& other) const = default;

private:
    NotifData* m_parent = nullptr;
    QObject* m_backer = nullptr; // A NotificationAction from Quickshell
    QString m_identifier;
    QString m_text;
};

class NotifData : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(NotifData)
    QML_UNCREATABLE("NotifData instances can only be retrieved from a NotifStore")

    Q_PROPERTY(QString id READ id NOTIFY idChanged)
    Q_PROPERTY(QString summary READ summary NOTIFY summaryChanged)
    Q_PROPERTY(QString body READ body NOTIFY bodyChanged)
    Q_PROPERTY(QString appIcon READ appIcon NOTIFY appIconChanged)
    Q_PROPERTY(QString appName READ appName NOTIFY appNameChanged)
    Q_PROPERTY(QString image READ image NOTIFY imageChanged)
    Q_PROPERTY(QVariantMap hints READ hints NOTIFY hintsChanged)
    Q_PROPERTY(int expireTimeout READ expireTimeout NOTIFY expireTimeoutChanged)
    Q_PROPERTY(caelestia::shell::models::NotifData::Urgency urgency READ urgency NOTIFY urgencyChanged)
    Q_PROPERTY(bool resident READ resident NOTIFY residentChanged)
    Q_PROPERTY(bool hasActionIcons READ hasActionIcons NOTIFY hasActionIconsChanged)
    Q_PROPERTY(QList<caelestia::shell::models::NotifAction> actions READ actions NOTIFY actionsChanged)

public:
    enum class Urgency : quint8 {
        Low = 0,
        Normal = 1,
        Critical = 2,
    };
    Q_ENUM(Urgency)

    explicit NotifData(QObject* parent = nullptr);
    NotifData(QObject* backer, QObject* parent);

    [[nodiscard]] QString id() const;
    [[nodiscard]] QString summary() const;
    [[nodiscard]] QString body() const;
    [[nodiscard]] QString appIcon() const;
    [[nodiscard]] QString appName() const;
    [[nodiscard]] QString image() const;
    [[nodiscard]] QVariantMap hints() const;
    [[nodiscard]] int expireTimeout() const;
    [[nodiscard]] Urgency urgency() const;
    [[nodiscard]] bool resident() const;
    [[nodiscard]] bool hasActionIcons() const;
    [[nodiscard]] QList<NotifAction> actions() const;

    Q_INVOKABLE void dismiss();
    Q_INVOKABLE void dismissPopup();

    Q_INVOKABLE void holdPopup();
    Q_INVOKABLE void releasePopup();

signals:
    void idChanged();
    void summaryChanged();
    void bodyChanged();
    void appIconChanged();
    void appNameChanged();
    void imageChanged();
    void hintsChanged();
    void expireTimeoutChanged();
    void urgencyChanged();
    void residentChanged();
    void hasActionIconsChanged();
    void actionsChanged();

    void popupClosed();
    void changed();
    void closed();

private slots:
    void syncFromBacker();
    void onBackerClosed();

private:
    bool m_popup = false;
    bool m_closed = false;
    qint64 m_createdAt;
    QTimer* m_popupTimer = nullptr;
    QObject* m_backer = nullptr; // A Notification from Quickshell

    QString m_id;
    QString m_summary;
    QString m_body;
    QString m_appIcon;
    QString m_appName;
    QString m_image;
    QVariantMap m_hints;
    int m_expireTimeout;
    int m_timeUntilExpire = -1;
    Urgency m_urgency = Urgency::Normal;
    bool m_resident = false;
    bool m_hasActionIcons = false;
    QList<NotifAction> m_actions;

    void startPopupTimer();

    void connectBacker();
    [[nodiscard]] QList<NotifAction> readBackerActions();

    void cacheImage();
    void storeImage(const QString& key, utils::Cache::Producer producer);

    friend class NotifStore;
};

} // namespace caelestia::shell::models
