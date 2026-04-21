#pragma once

#include <qeasingcurve.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::config {

class AnimCurves;
class AnimDurations;

class AnimTokens : public QObject {
    Q_OBJECT
    Q_MOC_INCLUDE("tokens.hpp")           // AnimCurves
    Q_MOC_INCLUDE("appearanceconfig.hpp") // AnimDurations
    QML_ANONYMOUS

    Q_PROPERTY(QEasingCurve emphasized READ emphasized NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve emphasizedAccel READ emphasizedAccel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve emphasizedDecel READ emphasizedDecel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve standard READ standard NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve standardAccel READ standardAccel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve standardDecel READ standardDecel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveFastSpatial READ expressiveFastSpatial NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveDefaultSpatial READ expressiveDefaultSpatial NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveSlowSpatial READ expressiveSlowSpatial NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveFastEffects READ expressiveFastEffects NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveDefaultEffects READ expressiveDefaultEffects NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveSlowEffects READ expressiveSlowEffects NOTIFY curvesChanged)

    Q_PROPERTY(caelestia::config::AnimDurations* durations READ durations NOTIFY durationsChanged)

public:
    explicit AnimTokens(QObject* parent = nullptr);

    void bindCurves(AnimCurves* curves);
    void bindDurations(AnimDurations* durations);

    [[nodiscard]] QEasingCurve emphasized() const;
    [[nodiscard]] QEasingCurve emphasizedAccel() const;
    [[nodiscard]] QEasingCurve emphasizedDecel() const;
    [[nodiscard]] QEasingCurve standard() const;
    [[nodiscard]] QEasingCurve standardAccel() const;
    [[nodiscard]] QEasingCurve standardDecel() const;
    [[nodiscard]] QEasingCurve expressiveFastSpatial() const;
    [[nodiscard]] QEasingCurve expressiveDefaultSpatial() const;
    [[nodiscard]] QEasingCurve expressiveSlowSpatial() const;
    [[nodiscard]] QEasingCurve expressiveFastEffects() const;
    [[nodiscard]] QEasingCurve expressiveDefaultEffects() const;
    [[nodiscard]] QEasingCurve expressiveSlowEffects() const;
    [[nodiscard]] AnimDurations* durations() const;

signals:
    void curvesChanged();
    void durationsChanged();

private:
    void rebuildCurves();
    static QEasingCurve buildCurve(const QList<qreal>& points);

    AnimCurves* m_curves = nullptr;
    AnimDurations* m_durations = nullptr;

    QEasingCurve m_emphasized;
    QEasingCurve m_emphasizedAccel;
    QEasingCurve m_emphasizedDecel;
    QEasingCurve m_standard;
    QEasingCurve m_standardAccel;
    QEasingCurve m_standardDecel;
    QEasingCurve m_expressiveFastSpatial;
    QEasingCurve m_expressiveDefaultSpatial;
    QEasingCurve m_expressiveSlowSpatial;
    QEasingCurve m_expressiveFastEffects;
    QEasingCurve m_expressiveDefaultEffects;
    QEasingCurve m_expressiveSlowEffects;
};

} // namespace caelestia::config
