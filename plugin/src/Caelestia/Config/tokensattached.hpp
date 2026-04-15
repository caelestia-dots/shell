#pragma once

#include "anim.hpp"
#include "appearanceconfig.hpp"
#include "config.hpp"
#include "tokens.hpp"

#include <qquickattachedpropertypropagator.h>

namespace caelestia::config {

class Tokens : public QQuickAttachedPropertyPropagator, public QQmlParserStatus {
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    QML_ELEMENT
    QML_UNCREATABLE("")
    QML_ATTACHED(Tokens)

    Q_PROPERTY(QString screen READ screen WRITE inheritScreen NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearanceRounding* rounding READ rounding NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearanceSpacing* spacing READ spacing NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearancePadding* padding READ padding NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearanceFont* font READ font NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearanceTransparency* transparency READ transparency NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::SizeTokens* sizes READ sizes NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AnimTokens* anim READ anim NOTIFY sourceChanged)

public:
    explicit Tokens(QObject* parent = nullptr);

    [[nodiscard]] QString screen() const;
    void inheritScreen(const QString& screen);

    [[nodiscard]] const AppearanceRounding* rounding() const;
    [[nodiscard]] const AppearanceSpacing* spacing() const;
    [[nodiscard]] const AppearancePadding* padding() const;
    [[nodiscard]] const AppearanceFont* font() const;
    [[nodiscard]] const AppearanceTransparency* transparency() const;

    [[nodiscard]] const SizeTokens* sizes() const;
    [[nodiscard]] const AnimTokens* anim() const;

    [[nodiscard]] Q_INVOKABLE static TokenConfig* forScreen(const QString& screen);

    static Tokens* qmlAttachedProperties(QObject* object);

signals:
    void sourceChanged();

protected:
    void attachedParentChange(
        QQuickAttachedPropertyPropagator* newParent, QQuickAttachedPropertyPropagator* oldParent) override;

private:
    void classBegin() override;
    void componentComplete() override;

    void propagateScreen();
    void bindAnim();

    bool m_complete = false;
    QString m_screen;
    GlobalConfig* m_config = nullptr;
    TokenConfig* m_tokens = nullptr;
    AnimTokens* m_anim = nullptr;
};

} // namespace caelestia::config
