#include "gpu.hpp"

#include <qdir.h>
#include <qdiriterator.h>
#include <qfile.h>
#include <qregularexpression.h>

#include <algorithm>

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

// Intel and AMD expose per-client engine busyness in /proc/<pid>/fdinfo. This
// covers Intel iGPUs (no gpu_busy_percent) and AMD devices whose driver does not
// publish the busy file.
bool hasFdinfoGpu() {
    static const QRegularExpression k_cardRe(u"^card\\d+$"_s);

    QDirIterator it(u"/sys/class/drm"_s, QDir::Dirs | QDir::NoDotAndDotDot);
    while (it.hasNext()) {
        const QString path = it.next();
        if (!k_cardRe.match(it.fileName()).hasMatch()) {
            continue;
        }

        QFile vendor(path + u"/device/vendor"_s);
        if (!vendor.open(QIODevice::ReadOnly | QIODevice::Text)) {
            continue;
        }

        const QByteArray id = vendor.readAll().trimmed();
        if (id == "0x8086" || id == "0x1002") {
            return true;
        }
    }
    return false;
}

QString cleanName(QString s) {
    // Keep "Graphics": it is part of the product name on Intel and AMD iGPUs
    // ("UHD Graphics", "Radeon Graphics"), unlike on discrete cards.
    static const QRegularExpression k_noise(u"\\(R\\)|\\(TM\\)"_s, QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression k_spaces(u"\\s+"_s);
    s.replace(k_noise, {});
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

struct NameSource {
    QString program;
    QStringList args;
    QString (*parse)(const QByteArray&);
};

// Name probes in priority order; the first non-empty result wins. Which of them run
// depends on the resolved type.
const std::array<NameSource, 3>& nameSources() {
    static const std::array<NameSource, 3> k_sources = {
        {
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
        },
    };
    return k_sources;
}

// Indices within nameSources(): nvidia-smi, then the driver-agnostic probes.
constexpr int k_nvidiaSource = 0;
constexpr int k_firstGenericSource = 1;

} // namespace

Gpu::Gpu(QObject* parent)
    : TickingService(parent) {
    m_busyFiles = gpuBusyFiles();

    const auto* svc = caelestia::config::ConfigSingleton::instance()->services();
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

bool Gpu::detecting() const {
    return m_detecting;
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
        m_backend = UsageBackend::None;
        m_fdinfoTimer.invalidate();
        m_fdinfoClients.clear();
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

void Gpu::setDetecting(bool value) {
    if (value == m_detecting) {
        return;
    }
    m_detecting = value;
    emit detectingChanged();
}

void Gpu::tick() {
    if (m_backend == UsageBackend::BusyFile) {
        readGenericUsage();
        readGpuTemperature();
    } else if (m_backend == UsageBackend::Fdinfo) {
        readFdinfoUsage();
        readGpuTemperature();
    } else if (m_backend == UsageBackend::Nvidia) {
        startNvidiaUsage();
    } else {
        resetUsage();
    }
}

void Gpu::resolveGpu() {
    // Supersede any chain still in flight so its callbacks cannot write stale state
    const int generation = ++m_generation;

    // Start a fresh fdinfo sampling window
    m_fdinfoTimer.invalidate();
    m_fdinfoClients.clear();

    if (m_userType != GpuType::Auto) {
        setType(m_userType);
        if (m_userType == GpuType::Nvidia) {
            m_backend = UsageBackend::Nvidia;
        } else if (m_userType == GpuType::Generic) {
            if (!m_busyFiles.isEmpty()) {
                m_backend = UsageBackend::BusyFile;
            } else if (hasFdinfoGpu()) {
                m_backend = UsageBackend::Fdinfo;
            } else {
                m_backend = UsageBackend::None;
            }
        } else {
            m_backend = UsageBackend::None;
        }
    }

    if (m_userType == GpuType::None) {
        setName({});
        setDetecting(false);
        return;
    }

    setName({});
    setDetecting(true);
    tryNameSource(m_userType == GpuType::Generic ? k_firstGenericSource : k_nvidiaSource, generation);
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
        if (!name.isEmpty()) {
            setType(GpuType::Nvidia);
            m_backend = UsageBackend::Nvidia;
        } else if (!m_busyFiles.isEmpty()) {
            setType(GpuType::Generic);
            m_backend = UsageBackend::BusyFile;
        } else if (hasFdinfoGpu()) {
            setType(GpuType::Generic);
            m_backend = UsageBackend::Fdinfo;
        } else {
            setType(GpuType::None);
            m_backend = UsageBackend::None;
        }

        if (m_type == GpuType::None) {
            setName({});
            setDetecting(false);
            return;
        }
    }

    if (!name.isEmpty()) {
        setName(std::move(name));
        setDetecting(false);
        return;
    }

    // Fall through to the next applicable source
    const int next = index + 1;
    if (next < probeEnd()) {
        tryNameSource(next, generation);
    } else {
        setName({});
        setDetecting(false);
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

void Gpu::readFdinfoUsage() {
    QHash<qint64, QHash<QString, quint64>> current;

    const QDir proc(u"/proc"_s);
    const QStringList pids = proc.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString& pid : pids) {
        if (!pid.at(0).isDigit()) {
            continue;
        }

        const QString fdinfoPath = u"/proc/"_s + pid + u"/fdinfo"_s;
        const QDir fdinfo(fdinfoPath);
        const QStringList fds = fdinfo.entryList(QDir::Files | QDir::NoDotAndDotDot);
        for (const QString& fd : fds) {
            // Only DRM clients carry engine counters; skip every other descriptor.
            if (!QFile::symLinkTarget(u"/proc/"_s + pid + u"/fd/"_s + fd).startsWith(u"/dev/dri/"_s)) {
                continue;
            }

            QFile file(fdinfo.filePath(fd));
            if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                continue;
            }

            const QByteArray data = file.readAll();
            qint64 clientId = -1;
            QByteArray driver;
            QHash<QString, quint64> engines;

            for (const QByteArray& line : data.split('\n')) {
                if (line.startsWith("drm-driver:")) {
                    driver = line.mid(11).trimmed();
                } else if (line.startsWith("drm-client-id:")) {
                    bool ok = false;
                    clientId = line.mid(14).trimmed().toLongLong(&ok);
                    if (!ok) {
                        clientId = -1;
                    }
                } else if (line.startsWith("drm-engine-")) {
                    const qsizetype colon = line.indexOf(':');
                    if (colon < 0) {
                        continue;
                    }
                    const QString name = QString::fromLatin1(line.mid(11, colon - 11)).trimmed();
                    QByteArray value = line.mid(colon + 1).trimmed();
                    if (value.endsWith(" ns")) {
                        value.chop(3);
                    }
                    bool ok = false;
                    const quint64 ns = value.toULongLong(&ok);
                    if (ok) {
                        engines.insert(name, ns);
                    }
                }
            }

            if (clientId < 0) {
                continue;
            }
            // Only count the drivers that expose fdinfo engine busyness. A hybrid
            // system may also have NVIDIA clients whose counters differ.
            if (driver != "i915" && driver != "xe" && driver != "amdgpu" && driver != "radeon") {
                continue;
            }

            // Several descriptors can share one DRM client; counters are per
            // client, so deduplicate by id.
            current.insert(clientId, std::move(engines));
        }
    }

    if (!m_fdinfoTimer.isValid()) {
        m_fdinfoClients = std::move(current);
        m_fdinfoTimer.start();
        return;
    }

    // Counters are in nanoseconds; restart() reports milliseconds
    const qreal elapsed = static_cast<qreal>(m_fdinfoTimer.nsecsElapsed());
    m_fdinfoTimer.restart();
    QHash<QString, quint64> busy;
    for (auto it = current.cbegin(); it != current.cend(); ++it) {
        const auto prev = m_fdinfoClients.constFind(it.key());
        if (prev == m_fdinfoClients.cend()) {
            continue;
        }
        for (auto e = it->cbegin(); e != it->cend(); ++e) {
            const auto p = prev->constFind(e.key());
            if (p != prev->cend() && *e > *p) {
                busy[e.key()] += *e - *p;
            }
        }
    }

    qreal usage = 0.0;
    if (elapsed > 0.0) {
        for (auto it = busy.cbegin(); it != busy.cend(); ++it) {
            usage = std::max(usage, static_cast<qreal>(*it) / elapsed);
        }
    }
    usage = std::clamp(usage, 0.0, 1.0);
    if (std::abs(usage - m_percentage) > 0.0001) {
        m_percentage = usage;
        emit percentageChanged();
    }

    m_fdinfoClients = std::move(current);
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
