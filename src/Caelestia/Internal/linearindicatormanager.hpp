#pragma once

#include <qcolor.h>
#include <qeasingcurve.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>

namespace caelestia::controls {

class LinearIndicatorManager;

class LinearIndicatorSegment : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("LinearIndicatorSegments can only be retrieved from a "
                    "LinearIndicatorManager.")

    Q_PROPERTY(qreal startFraction READ startFraction NOTIFY updated FINAL)
    Q_PROPERTY(qreal endFraction READ endFraction NOTIFY updated FINAL)
    Q_PROPERTY(int gapSize READ gapSize NOTIFY updated FINAL)

public:
    explicit LinearIndicatorSegment(int gap, QObject* parent = nullptr);

    qreal startFraction() const;
    qreal endFraction() const;
    int gapSize() const;

signals:
    void updated();

private:
    qreal m_startFraction;
    qreal m_endFraction;
    int m_gapSize;

    friend LinearIndicatorManager;
};

class LinearIndicatorManager : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(
        QList<caelestia::controls::LinearIndicatorSegment*> activeIndicators READ activeIndicators CONSTANT FINAL)

    Q_PROPERTY(qreal progress READ progress WRITE update NOTIFY updated FINAL)
    Q_PROPERTY(qreal completeEndProgress READ completeEndProgress WRITE updateCompleteEndProgress NOTIFY updated FINAL)
    Q_PROPERTY(int gap READ gap WRITE setGap NOTIFY updated FINAL)

    Q_PROPERTY(qreal duration READ duration CONSTANT FINAL)
    Q_PROPERTY(qreal completeEndDuration READ completeEndDuration CONSTANT FINAL)

public:
    explicit LinearIndicatorManager(QObject* parent = nullptr);

    QList<LinearIndicatorSegment*> activeIndicators() const;

    qreal progress() const;
    qreal completeEndProgress() const;

    int gap() const;
    void setGap(int gap);

    int duration() const;
    int completeEndDuration() const;

    void update(qreal progress);
    void updateCompleteEndProgress(qreal progress);

signals:
    void updated();

private:
    static constexpr int SEGMENTS = 2;

    std::array<QEasingCurve, 4> m_interpolators;
    qreal m_progress;
    qreal m_completeEndProgress;
    int m_gap;

    std::array<LinearIndicatorSegment*, SEGMENTS> m_activeIndicators;
};

} // namespace caelestia::controls
