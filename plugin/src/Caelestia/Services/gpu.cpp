#include "gpu.hpp"

#include "../Config/config.hpp"
#include "../Config/serviceconfig.hpp"
#include "sensorslib.hpp"

#include <qdir.h>
#include <qdiriterator.h>
#include <qfile.h>
#include <qregularexpression.h>

namespace caelestia::services {

namespace {

QStringList gpuBusyFiles() {
    static const QRegularExpression cardRe(QStringLiteral("^card\\d+$"));

    QStringList files;
    QDirIterator it(QStringLiteral("/sys/class/drm"), QDir::Dirs | QDir::NoDotAndDotDot);
    while (it.hasNext()) {
        const QString path = it.next();
        if (!cardRe.match(it.fileName()).hasMatch()) {
            continue;
        }
        const QString busy = path + QStringLiteral("/device/gpu_busy_percent");
        if (QFile::exists(busy)) {
            files << busy;
        }
    }
    return files;
}

QString cleanName(QString s) {
    static const QRegularExpression noise(
        QStringLiteral("\\(R\\)|\\(TM\\)|Graphics"), QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression spaces(QStringLiteral("\\s+"));
    s.replace(noise, QString());
    s.replace(spaces, QStringLiteral(" "));
    return s.trimmed();
}

QString parseNvidiaName(const QByteArray& out) {
    const QString first = QString::fromUtf8(out).split('\n').value(0).trimmed();
    return first.isEmpty() ? QString() : cleanName(first);
}

QString parseGlxinfoName(const QByteArray& out) {
    const QStringList lines = QString::fromUtf8(out).split('\n');
    for (const QString& line : lines) {
        const qsizetype idx = line.indexOf(QStringLiteral("Device:"));
        if (idx < 0) {
            continue;
        }

        QString rest = line.mid(idx + 7);
        const qsizetype paren = rest.indexOf('(');
        if (paren >= 0) {
            rest = rest.left(paren);
        }

        const QString cleaned = cleanName(rest);
        if (!cleaned.isEmpty()) {
            return cleaned;
        }
    }

    return QString();
}

QString parseLspciName(const QByteArray& out) {
    static const QRegularExpression lineRe(
        QStringLiteral("vga|3d controller|display"), QRegularExpression::CaseInsensitiveOption);

    const QStringList lines = QString::fromUtf8(out).split('\n');
    QString match;
    for (const QString& line : lines) {
        if (lineRe.match(line).hasMatch()) {
            match = line;
            break;
        }
    }

    if (match.isEmpty()) {
        return QString();
    }

    static const QRegularExpression bracketRe(QStringLiteral("\\[([^\\]]+)\\][^\\[]*$"));
    const auto bracket = bracketRe.match(match);
    if (bracket.hasMatch()) {
        return cleanName(bracket.captured(1));
    }

    // Split on a colon followed by whitespace so the PCI slot ("00:02.0") is not
    // mistaken for the class/name separator ("controller: Device").
    static const QRegularExpression colonRe(QStringLiteral(":\\s+(.+)"));
    const auto colon = colonRe.match(match);
    if (colon.hasMatch()) {
        return cleanName(colon.captured(1));
    }

    return QString();
}

struct NameSource {
    QString program;
    QStringList args;
    QString (*parse)(const QByteArray&);
};

// Name probes in priority order; the first non-empty result wins. Which of them run
// depends on the resolved type.
const std::array<NameSource, 3>& nameSources() {
    static const std::array<NameSource, 3> sources = { {
        { QStringLiteral("nvidia-smi"), { QStringLiteral("--query-gpu=name"), QStringLiteral("--format=csv,noheader") },
            &parseNvidiaName },
        { QStringLiteral("glxinfo"), { QStringLiteral("-B") }, &parseGlxinfoName },
        { QStringLiteral("lspci"), {}, &parseLspciName },
    } };
    return sources;
}

// Indices within nameSources(): nvidia-smi, then the driver-agnostic probes.
constexpr int kNvidiaSource = 0;
constexpr int kFirstGenericSource = 1;

} // namespace

Gpu::Gpu(QObject* parent)
    : TickingService(parent) {
    m_busyFiles = gpuBusyFiles();

    auto* svc = caelestia::config::GlobalConfig::instance()->services();
    m_userType = parseType(svc->gpuType());
    QObject::connect(svc, &caelestia::config::ServiceConfig::gpuTypeChanged, this, [this, svc] {
        const Type value = parseType(svc->gpuType());
        if (value == m_userType) {
            return;
        }
        m_userType = value;
        resolveGpu();
    });

    resolveGpu();
}

Gpu::Type Gpu::type() const {
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

void Gpu::setType(Type value) {
    if (value == m_type) {
        return;
    }
    m_type = value;
    if (m_type == None) {
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
    if (m_type == Generic) {
        readGenericUsage();
        readGpuTemperature();
    } else if (m_type == Nvidia) {
        startNvidiaUsage();
    } else {
        resetUsage();
    }
}

void Gpu::resolveGpu() {
    // Supersede any chain still in flight so its callbacks cannot write stale state
    const int generation = ++m_generation;

    if (m_userType != Auto) {
        setType(m_userType);
    }

    if (m_userType == None) {
        setName(tr("None"));
        return;
    }

    setName(tr("Detecting GPU..."));
    tryNameSource(m_userType == Generic ? kFirstGenericSource : kNvidiaSource, generation);
}

int Gpu::probeEnd() const {
    return m_userType == Nvidia ? kFirstGenericSource : static_cast<int>(nameSources().size());
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
    if (m_userType == Auto && index == kNvidiaSource) {
        setType(!name.isEmpty() ? Nvidia : (m_busyFiles.isEmpty() ? None : Generic));
        if (m_type == None) {
            setName(tr("None"));
            return;
        }
    }

    if (!name.isEmpty()) {
        setName(std::move(name));
        return;
    }

    // Fall through to the next applicable source
    const int next = index + 1;
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

void Gpu::startNvidiaUsage() {
    if (m_nvidiaQuerying) {
        return;
    }
    m_nvidiaQuerying = true;
    const int generation = m_generation;
    runProcess(QStringLiteral("nvidia-smi"),
        { QStringLiteral("--query-gpu=utilization.gpu,temperature.gpu"),
            QStringLiteral("--format=csv,noheader,nounits") },
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

Gpu::Type Gpu::parseType(const QString& s) {
    const QString u = s.trimmed().toUpper();
    if (u.isEmpty()) {
        return Auto;
    }
    if (u == QStringLiteral("NVIDIA")) {
        return Nvidia;
    }
    if (u == QStringLiteral("GENERIC")) {
        return Generic;
    }
    return None;
}

} // namespace caelestia::services
