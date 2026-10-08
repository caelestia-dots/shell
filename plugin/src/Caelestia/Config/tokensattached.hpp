#pragma once

#include <qqmlintegration.h>
#include <qqmlparserstatus.h>
#include <qquickattachedpropertypropagator.h>

#include "anim.hpp"
#include "rootnodes.hpp"

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
    Q_PROPERTY(const caelestia::config::AppearanceTransparency* transparency READ transparency NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::SizeTokens* sizes READ sizes NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::FontTokens* font READ font NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AnimTokens* anim READ anim CONSTANT)

public:
    explicit Tokens(QObject* parent = nullptr);

    [[nodiscard]] QString screen() const;
    void inheritScreen(const QString& screen);

    [[nodiscard]] const AppearanceRounding* rounding() const;
    [[nodiscard]] const AppearanceSpacing* spacing() const;
    [[nodiscard]] const AppearancePadding* padding() const;
    [[nodiscard]] static const AppearanceTransparency* transparency();

    [[nodiscard]] const SizeTokens* sizes() const;
    [[nodiscard]] const FontTokens* font() const;
    [[nodiscard]] static const AnimTokens* anim();

    [[nodiscard]] Q_INVOKABLE static TokensRoot* forScreen(const QString& screen);

    static Tokens* qmlAttachedProperties(QObject* object);

    void classBegin() override;
    void componentComplete() override;

signals:
    void sourceChanged();

protected:
    void attachedParentChange(
        QQuickAttachedPropertyPropagator* newParent, QQuickAttachedPropertyPropagator* oldParent) override;

private:
    void propagateScreen();

    bool m_complete = false;
    QString m_screen;
    ConfigRoot* m_config = nullptr;
    TokensRoot* m_tokens = nullptr;
};

} // namespace caelestia::config
