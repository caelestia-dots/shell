#pragma once

#include <qeasingcurve.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::internal {

class CircularIndicatorManager : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(qreal startFraction READ startFraction NOTIFY startFractionChanged)
    Q_PROPERTY(qreal endFraction READ endFraction NOTIFY endFractionChanged)
    Q_PROPERTY(qreal rotation READ rotation NOTIFY rotationChanged)
    Q_PROPERTY(qreal progress READ progress WRITE setProgress NOTIFY progressChanged)
    Q_PROPERTY(qreal completeEndProgress READ completeEndProgress WRITE setCompleteEndProgress NOTIFY
            completeEndProgressChanged)
    Q_PROPERTY(qreal duration READ duration NOTIFY indeterminateAnimationTypeChanged)
    Q_PROPERTY(qreal completeEndDuration READ completeEndDuration NOTIFY indeterminateAnimationTypeChanged)
    Q_PROPERTY(IndeterminateAnimationType indeterminateAnimationType READ indeterminateAnimationType WRITE
            setIndeterminateAnimationType NOTIFY indeterminateAnimationTypeChanged)

public:
    explicit CircularIndicatorManager(QObject* parent = nullptr);

    enum IndeterminateAnimationType {
        Advance = 0,
        Retreat
    };
    Q_ENUM(IndeterminateAnimationType)

    [[nodiscard]] qreal startFraction() const;
    [[nodiscard]] qreal endFraction() const;
    [[nodiscard]] qreal rotation() const;

    [[nodiscard]] qreal progress() const;
    void setProgress(qreal progress);

    [[nodiscard]] qreal completeEndProgress() const;
    void setCompleteEndProgress(qreal progress);

    [[nodiscard]] qreal duration() const;
    [[nodiscard]] qreal completeEndDuration() const;

    [[nodiscard]] IndeterminateAnimationType indeterminateAnimationType() const;
    void setIndeterminateAnimationType(IndeterminateAnimationType t);

signals:
    void startFractionChanged();
    void endFractionChanged();
    void rotationChanged();
    void progressChanged();
    void completeEndProgressChanged();
    void indeterminateAnimationTypeChanged();

private:
    IndeterminateAnimationType m_type;
    QEasingCurve m_curve;

    qreal m_progress;
    qreal m_startFraction;
    qreal m_endFraction;
    qreal m_rotation;
    qreal m_completeEndProgress;

    void update(qreal progress);
    void updateAdvance(qreal progress);
    void updateRetreat(qreal progress);
};

} // namespace caelestia::internal
