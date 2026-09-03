#include "gpu.hpp"

#include <qdir.h>
#include <qdiriterator.h>
#include <qfile.h>
#include <qregularexpression.h>
#include <qset.h>

#include <chrono>

#include "config/rootnodes.hpp"
#include "config/serviceconfig.hpp"
#include "sensorslib.hpp"

namespace caelestia::services {

using Qt::StringLiterals::operator""_s;

namespace {

QStringList gpuBusyFiles() {
    static const QRegularExpression k_cardRe(u"^card\\d+$"_s);

    QStringList files;
    QDirIterator it(u"/sys/class/drm"_s, QDir::Dirs | QDir::NoDotAndDotDot);
    while (it.hasNext()) {
        const QString path = it.next();
        if (!k_cardRe.match(it.fileName()).hasMatch()) {
            continue;
        }
        const QString busy = path + u"/device/gpu_busy_percent"_s;
        if (QFile::exists(busy)) {
            files << busy;
        }
    }
    return files;
}

// PCI slot (e.g. "0000:00:02.0") of the first Intel i915 GPU, empty if none.
// i915 exposes busy time through /proc/*/fdinfo, not a sysfs gpu_busy_percent,
// so this picks the Intel usage path.
QString intelGpuPdev() {
    static const QRegularExpression k_cardRe(u"^card\\d+$"_s);

    QDirIterator it(u"/sys/class/drm"_s, QDir::Dirs | QDir::NoDotAndDotDot);
    while (it.hasNext()) {
        const QString path = it.next();
        if (!k_cardRe.match(it.fileName()).hasMatch()) {
            continue;
        }
        const QString device = path + u"/device"_s;
        const QString driver = QFile::symLinkTarget(device + u"/driver"_s);
        if (!driver.endsWith(u"/i915"_s)) {
            continue;
        }
        QFile vendor(device + u"/vendor"_s);
        if (!vendor.open(QIODevice::ReadOnly | QIODevice::Text) ||
            QString::fromUtf8(vendor.readAll()).trimmed() != u"0x8086"_s) {
            continue;
        }

        QFile uevent(device + u"/uevent"_s);
        if (!uevent.open(QIODevice::ReadOnly | QIODevice::Text)) {
            continue;
        }
        QString pdev;
        const QStringList lines = QString::fromUtf8(uevent.readAll()).split(u'\n');
        uevent.close();
        for (const QString& line : lines) {
            if (line.startsWith(u"PCI_SLOT_NAME="_s)) {
                pdev = line.mid(14).trimmed();
                break;
            }
        }
        if (!pdev.isEmpty()) {
            return pdev;
        }
    }
    return {};
}

// Parses a "<number> ns" fdinfo value into its plain nanoseconds.
quint64 parseNs(const QString& value) {
    const qsizetype sp = value.indexOf(u' ');
    return value.left(sp).toULongLong();
}

// Accumulated render+compute busy ns per DRM client of this GPU, read from each
// running process's fdinfo. Render and compute share Intel's EUs so they drive the
// usage figure; copy/video/video-enhance are ignored, as in NVTOP. A client can
// span several fds, so only the first fd seen per client-id counts.
QHash<unsigned int, QPair<quint64, quint64>> intelFdinfoBusy(const QString& pdev) {
    static const QRegularExpression k_pidRe(u"^\\d+$"_s);

    QHash<unsigned int, QPair<quint64, quint64>> busy;
    QSet<unsigned int> seen;
    QDirIterator pidIt(u"/proc"_s, QDir::Dirs | QDir::NoDotAndDotDot);
    while (pidIt.hasNext()) {
        const QString pidPath = pidIt.next();
        if (!k_pidRe.match(pidIt.fileName()).hasMatch()) {
            continue;
        }

        QDirIterator fdIt(pidPath + u"/fdinfo"_s, QDir::Files | QDir::NoDotAndDotDot);
        while (fdIt.hasNext()) {
            QFile f(fdIt.next());
            if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
                continue;
            }

            bool isTarget = false;
            unsigned client = 0;
            quint64 renderNs = 0;
            quint64 computeNs = 0;
            const QStringList lines = QString::fromUtf8(f.readAll()).split(u'\n');
            f.close();
            for (const QString& line : lines) {
                if (line.startsWith(u"drm-pdev:\t"_s)) {
                    isTarget = line.mid(10).trimmed() == pdev;
                } else if (line.startsWith(u"drm-client-id:\t"_s)) {
                    client = static_cast<unsigned>(line.mid(14).trimmed().toUInt());
                } else if (line.startsWith(u"drm-engine-render:\t"_s)) {
                    renderNs = parseNs(line.mid(19));
                } else if (line.startsWith(u"drm-engine-compute:\t"_s)) {
                    computeNs = parseNs(line.mid(19));
                }
            }

            if (isTarget && client != 0 && !seen.contains(client)) {
                seen.insert(client);
                busy.insert(client, { renderNs, computeNs });
            }
        }
    }
    return busy;
}

// Mirrors NVTOP's busy_usage_from_time_usage_round: given a busy-time delta and the
// wall time elapsed between two samples (both in ns), returns a 0-100 percentage.
unsigned busyUsageFromDelta(quint64 deltaNs, quint64 elapsedNs) {
    return static_cast<unsigned>((deltaNs * 100 + elapsedNs / 2) / elapsedNs);
}

QString cleanName(QString s) {
    static const QRegularExpression k_noise(u"\\(R\\)|\\(TM\\)|Graphics"_s, QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression k_spaces(u"\\s+"_s);
    s.replace(k_noise, QString());
    s.replace(k_spaces, u" "_s);
    return s.trimmed();
}

QString parseNvidiaName(const QByteArray& out) {
    const QString first = QString::fromUtf8(out).split(u'\n').value(0).trimmed();
    return first.isEmpty() ? QString() : cleanName(first);
}

QString parseGlxinfoName(const QByteArray& out) {
    const QStringList lines = QString::fromUtf8(out).split(u'\n');
    for (const QString& line : lines) {
        const qsizetype idx = line.indexOf(u"Device:"_s);
        if (idx < 0) {
            continue;
        }

        QString rest = line.mid(idx + 7);
        const qsizetype paren = rest.indexOf(u'(');
        if (paren >= 0) {
            rest = rest.left(paren);
        }

        const QString cleaned = cleanName(rest);
        if (!cleaned.isEmpty()) {
            return cleaned;
        }
    }

    return {};
}

QString parseLspciName(const QByteArray& out) {
    static const QRegularExpression k_lineRe(u"vga|3d controller|display"_s, QRegularExpression::CaseInsensitiveOption);

    const QStringList lines = QString::fromUtf8(out).split(u'\n');
    QString match;
    for (const QString& line : lines) {
        if (k_lineRe.match(line).hasMatch()) {
            match = line;
            break;
        }
    }

    if (match.isEmpty()) {
        return {};
    }

    static const QRegularExpression k_bracketRe(u"\\[([^\\]]+)\\][^\\[]*$"_s);
    const auto bracket = k_bracketRe.match(match);
    if (bracket.hasMatch()) {
        return cleanName(bracket.captured(1));
    }

    // Split on a colon followed by whitespace so the PCI slot ("00:02.0") is not
    // mistaken for the class/name separator ("controller: Device").
    static const QRegularExpression k_colonRe(u":\\s+(.+)"_s);
    const auto colon = k_colonRe.match(match);
    if (colon.hasMatch()) {
        return cleanName(colon.captured(1));
    }

    return {};
}

QString parseIntelPciName(const QByteArray& out) {
    static const QRegularExpression k_lineRe(u"vga|3d controller|display"_s, QRegularExpression::CaseInsensitiveOption);

    const QStringList lines = QString::fromUtf8(out).split(u'\n');
    QString match;
    for (const QString& line : lines) {
        if (k_lineRe.match(line).hasMatch()) {
            match = line;
            break;
        }
    }

    if (match.isEmpty()) {
        return {};
    }

    // Split on a colon followed by whitespace so the PCI slot ("00:02.0") is not
    // mistaken for the class/name separator ("controller: Device").
    static const QRegularExpression k_colonRe(u":\\s+(.+)"_s);
    QString rest = k_colonRe.match(match).captured(1);
    if (rest.isEmpty()) {
        return {};
    }

    // Keep the model variant ("(Ice Lake)") but drop the revision ("(rev 07)").
    static const QRegularExpression k_rev(u"\\(rev[^)]*\\)"_s, QRegularExpression::CaseInsensitiveOption);
    rest.replace(k_rev, QString());

    // Shorten the vendor prefix: "Intel Corporation <model>" -> "Intel <model>".
    rest.replace(u"Intel Corporation"_s, u"Intel"_s);

    static const QRegularExpression k_spaces(u"\\s+"_s);
    rest.replace(k_spaces, u" "_s);

    // Shorter panel label: drop the vendor and any trailing "(Ice Lake)" suffix.
    rest.replace(u"Intel "_s, QString());
    static const QRegularExpression k_suffixRe(u"\\s*\\([^)]*\\)\\s*$"_s);
    rest.remove(k_suffixRe);
    return rest.trimmed();
}

struct NameSource {
    QString program;
    QStringList args;
    QString (*parse)(const QByteArray&);
};

// Name probes in priority order; the first non-empty result wins. Which of them run
// depends on the resolved type.
const std::array<NameSource, 4>& nameSources() {
    static const std::array<NameSource, 4> k_sources = { {
        {
            .program = u"nvidia-smi"_s,
            .args = { u"--query-gpu=name"_s, u"--format=csv,noheader"_s },
            .parse = &parseNvidiaName,
        },
        {
            .program = u"glxinfo"_s,
            .args = { u"-B"_s },
            .parse = &parseGlxinfoName,
        },
        {
            .program = u"lspci"_s,
            .args = {},
            .parse = &parseLspciName,
        },
        {
            .program = u"lspci"_s,
            .args = {},
            .parse = &parseIntelPciName,
        },
    } };
    return k_sources;
}

// Indices within nameSources(): nvidia-smi, then the driver-agnostic probes, then the
// Intel-specific PCI probe.
constexpr int k_nvidiaSource = 0;
constexpr int k_firstGenericSource = 1;
constexpr int k_intelSource = 3;

} // namespace

Gpu::Gpu(QObject* parent)
    : TickingService(parent) {
    m_busyFiles = gpuBusyFiles();
    m_intelPdev = intelGpuPdev();

    auto* svc = caelestia::config::ConfigSingleton::instance()->services();
    m_userType = svc->gpuType();
    QObject::connect(svc, &caelestia::config::ServiceConfig::gpuTypeChanged, this, [this, svc] {
        const GpuType value = svc->gpuType();
        if (value == m_userType) {
            return;
        }
        m_userType = value;
        resolveGpu();
    });

    resolveGpu();
}

GpuType Gpu::type() const {
    return m_type;
}

QString Gpu::name() const {
    return m_name;
}

qreal Gpu::percentage() const {
    return m_percentage;
}

qreal Gpu::temperature() const {
    return m_temperature;
}

void Gpu::setType(GpuType value) {
    if (value == m_type) {
        return;
    }
    m_type = value;
    if (m_type == GpuType::None) {
        resetUsage();
    }
    emit typeChanged();
}

void Gpu::setName(QString value) {
    if (value == m_name) {
        return;
    }
    m_name = std::move(value);
    emit nameChanged();
}

void Gpu::tick() {
    if (m_type == GpuType::Generic) {
        readGenericUsage();
        readGpuTemperature();
    } else if (m_type == GpuType::Intel) {
        readIntelUsage();
    } else if (m_type == GpuType::Nvidia) {
        startNvidiaUsage();
    } else {
        resetUsage();
    }
}

void Gpu::resolveGpu() {
    // Supersede any chain still in flight so its callbacks cannot write stale state
    const int generation = ++m_generation;

    if (m_userType != GpuType::Auto) {
        setType(m_userType);
    }

    if (m_userType == GpuType::None) {
        setName(tr("None"));
        return;
    }

    setName(tr("Detecting GPU..."));
    const GpuType user = m_userType;
    if (user == GpuType::Intel) {
        tryNameSource(k_intelSource, generation);
    } else {
        const bool startsGeneric = user == GpuType::Generic || user == GpuType::Intel;
        tryNameSource(startsGeneric ? k_firstGenericSource : k_nvidiaSource, generation);
    }
}

int Gpu::probeEnd() const {
    return m_userType == GpuType::Nvidia ? k_firstGenericSource : static_cast<int>(nameSources().size());
}

void Gpu::tryNameSource(int index, int generation) {
    const NameSource& src = nameSources().at(static_cast<std::size_t>(index));
    runProcess(src.program, src.args, [this, index, generation, parse = src.parse](const QByteArray& out) {
        finishNameSource(index, generation, parse(out));
    });
}

void Gpu::finishNameSource(int index, int generation, QString name) {
    if (generation != m_generation) {
        return; // superseded by a newer resolution
    }

    // Under Auto the NVIDIA name probe doubles as the type probe: a non-empty result
    // means an NVIDIA GPU is present and queryable.
    if (m_userType == GpuType::Auto && index == k_nvidiaSource) {
        GpuType resolved;
        if (!name.isEmpty()) {
            resolved = GpuType::Nvidia;
        } else if (!m_intelPdev.isEmpty()) {
            resolved = GpuType::Intel;
        } else {
            resolved = m_busyFiles.isEmpty() ? GpuType::None : GpuType::Generic;
        }
        setType(resolved);

        if (m_type == GpuType::None) {
            setName(tr("None"));
            return;
        }
    }

    if (!name.isEmpty()) {
        setName(std::move(name));
        return;
    }

    // Fall through to the next applicable source
    int next = index + 1;
    // Name Auto-resolved Intel from the PCI probe, not the Mesa renderer string.
    if (m_type == GpuType::Intel && index < k_intelSource) {
        next = k_intelSource;
    }
    if (next < probeEnd()) {
        tryNameSource(next, generation);
    } else {
        setName(tr("None"));
    }
}

void Gpu::runProcess(const QString& program, const QStringList& args, std::function<void(const QByteArray&)> callback) {
    auto* proc = new QProcess(this);
    proc->setStandardErrorFile(QProcess::nullDevice());

    // Deliver the result exactly once, then tear the process down. A crash, a missing
    // binary or a failed run yields empty output so the caller can fall through
    // gracefully: only FailedToStart skips finished(), and a crash reports CrashExit there.
    const auto finish = [proc, callback = std::move(callback)](const QByteArray& out) {
        callback(out);
        proc->deleteLater();
    };

    QObject::connect(proc, &QProcess::finished, this, [finish, proc](int code, QProcess::ExitStatus status) {
        const bool ok = status == QProcess::NormalExit && code == 0; // Fail on crashes and non-zero exit codes
        finish(ok ? proc->readAllStandardOutput() : QByteArray());
    });
    QObject::connect(proc, &QProcess::errorOccurred, this, [finish](QProcess::ProcessError err) {
        if (err == QProcess::FailedToStart) {
            finish(QByteArray());
        }
    });

    proc->start(program, args);
}

void Gpu::readGenericUsage() {
    qreal sum = 0.0;
    int count = 0;
    for (const QString& path : std::as_const(m_busyFiles)) {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
            continue;
        }
        bool ok = false;
        const qreal v = f.readAll().trimmed().toDouble(&ok);
        f.close();
        if (ok) {
            sum += v;
            ++count;
        }
    }
    const qreal newPerc = count > 0 ? sum / count / 100.0 : 0.0;
    if (std::abs(newPerc - m_percentage) > 0.0001) {
        m_percentage = newPerc;
        emit percentageChanged();
    }
}

void Gpu::readIntelUsage() {
    if (m_intelPdev.isEmpty()) {
        resetUsage();
        return;
    }

    // Same math as NVTOP's busy_usage_from_time_usage_round: per client, sum render +
    // compute, from the ns delta between scans scaled by the wall time elapsed. A delta
    // larger than that window is treated as over-counting and skipped.
    const auto now = std::chrono::steady_clock::now().time_since_epoch().count();
    const auto cur = intelFdinfoBusy(m_intelPdev);

    // First tick only seeds the baseline; there is nothing to diff yet.
    if (m_lastIntelNs == 0) {
        m_lastFdinfo.clear();
        for (auto it = cur.cbegin(); it != cur.cend(); ++it) {
            m_lastFdinfo.insert(it.key(), IntelClientBusy{ .render = it.value().first, .compute = it.value().second });
        }
        m_lastIntelNs = now;
        return;
    }

    const auto elapsedNs = static_cast<quint64>(now - m_lastIntelNs);
    if (elapsedNs == 0) {
        return;
    }

    unsigned totalPerc = 0;
    for (auto it = cur.cbegin(); it != cur.cend(); ++it) {
        const auto prev = m_lastFdinfo.value(it.key());
        const quint64 renderDelta = it.value().first >= prev.render ? it.value().first - prev.render : 0;
        const quint64 computeDelta = it.value().second >= prev.compute ? it.value().second - prev.compute : 0;

        // Skip deltas that exceed the wall-time window (i915 can over-report). Compute
        // usage only counts on top of a valid render reading, as in NVTOP.
        const bool renderValid = renderDelta != 0 && renderDelta <= elapsedNs;
        const bool computeValid = renderValid && computeDelta != 0 && computeDelta <= elapsedNs;

        unsigned clientPerc = 0;
        if (renderValid) {
            clientPerc = busyUsageFromDelta(renderDelta, elapsedNs);
        }
        if (computeValid) {
            clientPerc += busyUsageFromDelta(computeDelta, elapsedNs);
        }
        clientPerc = std::min(clientPerc, 100u);
        totalPerc = std::min(totalPerc + clientPerc, 100u);
    }

    m_lastFdinfo.clear();
    for (auto it = cur.cbegin(); it != cur.cend(); ++it) {
        m_lastFdinfo.insert(it.key(), IntelClientBusy{ .render = it.value().first, .compute = it.value().second });
    }
    m_lastIntelNs = now;

    const qreal usage = qMin<qreal>(1.0, static_cast<qreal>(totalPerc) / 100.0);
    if (std::abs(usage - m_percentage) > 0.0001) {
        m_percentage = usage;
        emit percentageChanged();
    }

    // No temperature source for iGPUs on most systems.
    if (std::abs(m_temperature) > 0.05) {
        m_temperature = 0.0;
        emit temperatureChanged();
    }
}

void Gpu::startNvidiaUsage() {
    if (m_nvidiaQuerying) {
        return;
    }
    m_nvidiaQuerying = true;
    const int generation = m_generation;
    runProcess(u"nvidia-smi"_s,
        { u"--query-gpu=utilization.gpu,temperature.gpu"_s, u"--format=csv,noheader,nounits"_s },
        [this, generation](const QByteArray& out) {
            m_nvidiaQuerying = false;

            // The type moved out from under the sample, so it no longer describes the GPU
            if (generation != m_generation) {
                return;
            }

            const QList<QByteArray> parts = out.trimmed().split(',');
            if (parts.size() < 2) {
                return;
            }
            bool ok1 = false;
            bool ok2 = false;
            const qreal usage = parts.at(0).trimmed().toDouble(&ok1) / 100.0;
            const qreal temp = parts.at(1).trimmed().toDouble(&ok2);
            if (ok1 && std::abs(usage - m_percentage) > 0.0001) {
                m_percentage = usage;
                emit percentageChanged();
            }
            if (ok2 && std::abs(temp - m_temperature) > 0.05) {
                m_temperature = temp;
                emit temperatureChanged();
            }
        });
}

void Gpu::readGpuTemperature() {
    const auto t = sensorslib::gpuPciAverageTemp();
    const qreal newTemp = t.value_or(0.0);
    if (std::abs(newTemp - m_temperature) > 0.05) {
        m_temperature = newTemp;
        emit temperatureChanged();
    }
}

void Gpu::resetUsage() {
    if (std::abs(m_percentage) > 0.0001) {
        m_percentage = 0.0;
        emit percentageChanged();
    }
    if (std::abs(m_temperature) > 0.05) {
        m_temperature = 0.0;
        emit temperatureChanged();
    }
}

} // namespace caelestia::services
