#include "colours.hpp"

#include <qloggingcategory.h>

#include <caelestia/scheme/smart.hpp>
#include <caelestia/theme/theme.hpp>
#include <caelestia/wallpaper/wallpaper.hpp>

#include <algorithm>
#include <cmath>
#include <numbers>
#include <stdexcept>

#include "config/rootnodes.hpp"
#include "schemehandles.hpp"
#include "wallpapers.hpp"

namespace {

Q_LOGGING_CATEGORY(lcColours, "caelestia.scheme.colours", QtInfoMsg)

} // namespace

namespace caelestia::shell::scheme {

using Qt::StringLiterals::operator""_s;

namespace {

constexpr QStringView k_dynamic = u"dynamic";

qreal luminance(const QColor& colour) {
    const auto r = static_cast<qreal>(colour.redF());
    const auto g = static_cast<qreal>(colour.greenF());
    const auto b = static_cast<qreal>(colour.blueF());
    if (qFuzzyIsNull(r) && qFuzzyIsNull(g) && qFuzzyIsNull(b))
        return 0;
    return std::sqrt(0.299 * r * r + 0.587 * g * g + 0.114 * b * b);
}

struct LinearRgb {
    qreal r;
    qreal g;
    qreal b;
};

bool inGamut(const LinearRgb& rgb) {
    return rgb.r >= 0 && rgb.r <= 1 && rgb.g >= 0 && rgb.g <= 1 && rgb.b >= 0 && rgb.b <= 1;
}

qreal toLinear(qreal v) {
    return v <= 0.04045 ? v / 12.92 : std::pow((v + 0.055) / 1.055, 2.4);
}

qreal fromLinear(qreal v) {
    v = std::clamp(v, 0.0, 1.0);
    return v <= 0.0031308 ? v * 12.92 : 1.055 * std::pow(v, 1 / 2.4) - 0.055;
}

LinearRgb oklchToLinear(qreal l, qreal c, qreal h) {
    const auto rad = h * std::numbers::pi / 180;
    const auto a = c * std::cos(rad);
    const auto b = c * std::sin(rad);

    const auto lmsL = std::pow(l + 0.3963377774 * a + 0.2158037573 * b, 3);
    const auto lmsM = std::pow(l - 0.1055613458 * a - 0.0638541728 * b, 3);
    const auto lmsS = std::pow(l - 0.0894841775 * a - 1.2914855480 * b, 3);

    return {
        .r = 4.0767416621 * lmsL - 3.3077115913 * lmsM + 0.2309699292 * lmsS,
        .g = -1.2684380046 * lmsL + 2.6097574011 * lmsM - 0.3413193965 * lmsS,
        .b = -0.0041960863 * lmsL - 0.7034186147 * lmsM + 1.7076147010 * lmsS,
    };
}

QFuture<lib::SchemeData> getSchemeData(
    const std::shared_ptr<lib::Scheme>& scheme, const QString& flavourName, lib::Mode mode) {
    auto flavour = scheme->flavour(flavourName);
    if (!flavour) {
        qCWarning(lcColours) << "Unknown flavour" << flavourName << "for scheme" << scheme->name() << "- using default";
        flavour = scheme->defaultFlavour();
    }

    if (flavour->modes().contains(mode))
        return flavour->data(mode);

    qCWarning(lcColours) << "Unknown mode" << lib::modeName(mode) << "for flavour" << flavourName << "of scheme"
                         << scheme->name() << "- using default";
    return flavour->data(flavour->defaultMode());
}

} // namespace

void connectResolveSchemeUpdates(const QObject* receiver, const std::function<void(bool)>& fn) {
    QObject::connect(Wallpapers::instance(), &Wallpapers::analysisDone, receiver, fn);
    QObject::connect(
        config::ConfigSingleton::instance()->services(), &config::ServiceConfig::smartSchemeChanged, receiver, [fn] {
            fn(false);
        });
}

QFuture<lib::SchemeData> resolveScheme(const QString& scheme, const QString& flavour, lib::Mode mode, bool smart) {
    if (scheme == k_dynamic) {
        const auto analysis = Wallpapers::instance()->analysis();
        if (analysis.colours.isEmpty()) {
            return QtFuture::makeExceptionalFuture<lib::SchemeData>(
                std::make_exception_ptr(std::runtime_error("no colours found in the current wallpaper")));
        }

        const auto choice = lib::smartChoice(analysis);
        return getSchemeData(lib::Scheme::forColour(analysis.colours.first()), smart ? choice.flavour : flavour,
            smart ? choice.mode : mode);
    }

    return lib::Scheme::forName(scheme)
        .then([scheme, flavour, mode](const std::shared_ptr<lib::Scheme>& s) {
            if (!s)
                throw std::runtime_error(u"no such scheme: %1"_s.arg(scheme).toStdString());
            return getSchemeData(s, flavour, mode);
        })
        .unwrap();
}

ColourPalette::ColourPalette(QObject* parent)
    : QObject(parent) {}

const lib::SchemeColours& ColourPalette::colours() const {
    return m_colours;
}

void ColourPalette::setColours(const lib::SchemeColours& colours) {
    m_colours = colours;
    emit changed();
}

#define GETTER(name, layer)                                                                                            \
    QColor ColourPalette::name() const {                                                                               \
        return m_colours.name;                                                                                         \
    }

CAELESTIA_PALETTE_COLOURS(GETTER)

#undef GETTER

Colours::Colours(QObject* parent)
    : QObject(parent)
    , m_palette(new ColourPalette(this))
    , m_tPalette(new ColourPalette(this)) {
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &Colours::handleFileChanged);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &Colours::handleDirectoryChanged);

    const auto dir = QFileInfo(lib::statePath()).path();
    QDir().mkpath(dir);
    m_watcher.addPath(dir);
    watch(lib::statePath());

    const auto* transparency = config::ConfigSingleton::instance()->appearance()->transparency();
    connect(transparency, &config::AppearanceTransparency::enabledChanged, this, &Colours::updateLayer);
    connect(transparency, &config::AppearanceTransparency::baseChanged, this, &Colours::updateLayer);
    connect(transparency, &config::AppearanceTransparency::layersChanged, this, &Colours::updateLayer);
    connect(Wallpapers::instance(), &Wallpapers::analysisDone, this, &Colours::updateLayer);

    connectResolveSchemeUpdates(this, [this](bool committed) {
        if (committed || m_state.name != k_dynamic)
            return;

        const auto smart = config::ConfigSingleton::instance()->services()->smartScheme();
        applyState(m_state.name, m_state.flavour, m_state.mode, false, smart);
    });

    loadState();
    loadSchemes();
}

bool Colours::committed() const {
    return m_committed;
}

QString Colours::scheme() const {
    return m_state.name;
}

QString Colours::flavour() const {
    return m_state.flavour;
}

Colours::Mode Colours::mode() const {
    return static_cast<Mode>(m_state.mode);
}

QList<SchemeHandle> Colours::schemes() const {
    return m_schemes;
}

ColourPalette* Colours::palette() const {
    return m_palette;
}

ColourPalette* Colours::tPalette() const {
    return m_tPalette;
}

bool Colours::layerNeedsUpdate() {
    return false;
}

void Colours::commit() {
    if (m_committed)
        return;

    theme::Theme(m_state).apply().onFailed(this, [](const std::exception& e) {
        qCWarning(lcColours) << "Failed to apply theme:" << e.what();
    });

    m_committed = true;
    emit committedChanged();
}

void Colours::reset() {
    if (!m_committed)
        loadState();
}

void Colours::setScheme(const QString& scheme, const QString& flavour, bool commit) {
    setState(scheme, flavour, m_state.mode, commit, flavour.isEmpty());
}

void Colours::setFlavour(const QString& flavour, bool commit) {
    setState(m_state.name, flavour, m_state.mode, commit, false);
}

void Colours::setMode(Mode mode, bool commit) {
    setState(m_state.name, m_state.flavour, static_cast<lib::Mode>(mode), commit, false);
}

QColor Colours::oklch(qreal l, qreal c, qreal h) {
    const auto rgb = oklchToLinear(l, c, h);
    return QColor::fromRgbF(static_cast<float>(fromLinear(rgb.r)), static_cast<float>(fromLinear(rgb.g)),
        static_cast<float>(fromLinear(rgb.b)));
}

QVector3D Colours::toOklch(const QColor& colour) {
    const auto r = toLinear(static_cast<qreal>(colour.redF()));
    const auto g = toLinear(static_cast<qreal>(colour.greenF()));
    const auto b = toLinear(static_cast<qreal>(colour.blueF()));

    const auto lmsL = std::cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const auto lmsM = std::cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const auto lmsS = std::cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);

    const auto l = 0.2104542553 * lmsL + 0.7936177850 * lmsM - 0.0040720468 * lmsS;
    const auto a = 1.9779984951 * lmsL - 2.4285922050 * lmsM + 0.4505937099 * lmsS;
    const auto bb = 0.0259040371 * lmsL + 0.7827717662 * lmsM - 0.8086757660 * lmsS;

    const auto c = std::hypot(a, bb);
    auto h = std::atan2(bb, a) * 180 / std::numbers::pi;
    if (h < 0)
        h += 360;

    return { static_cast<float>(l), static_cast<float>(c), static_cast<float>(h) };
}

qreal Colours::maxChroma(qreal l, qreal h) {
    qreal lo = 0;
    qreal hi = 0.4;
    for (int i = 0; i < 24; ++i) {
        const auto mid = (lo + hi) / 2;
        if (inGamut(oklchToLinear(l, mid, h)))
            lo = mid;
        else
            hi = mid;
    }
    return lo;
}

QColor Colours::_layer(const QColor& colour, int layer) const {
    return this->layer(colour, layer);
}

QColor Colours::layer(const QColor& colour, int layer) const {
    const auto* transparency = config::ConfigSingleton::instance()->appearance()->transparency();

    if (!transparency->enabled())
        return colour;

    if (layer == 0) {
        auto result = colour;
        result.setAlphaF(static_cast<float>(transparency->base()));
        return result;
    }

    return alter(colour, transparency->layers(), layer);
}

QColor Colours::alter(const QColor& colour, qreal alpha, int layer) const {
    const auto lum = luminance(colour);
    const auto a = static_cast<float>(alpha);
    if (lum <= 0)
        return QColor::fromRgbF(0, 0, 0, a);

    const auto light = m_state.mode == lib::Mode::Light;
    const auto direction = !light || layer == 1 ? 1.0 : -layer / 2.0;
    const auto strength = light ? 0.2 : 0.3;
    const auto wallBoostLight = layer == 1 ? 3.0 : 1.0;
    const auto wallBoost = light ? wallBoostLight : 2.5;
    const auto* transparency = config::ConfigSingleton::instance()->appearance()->transparency();
    const auto wallLuminance = Wallpapers::instance()->analysis().luminance;
    const auto offset = direction * strength * (1 - transparency->base()) * (1 + wallLuminance * wallBoost);
    const auto scale = (lum + offset) / lum;

    const auto scaled = [scale](float c) -> float {
        return static_cast<float>(std::clamp(static_cast<qreal>(c) * scale, 0.0, 1.0));
    };
    return QColor::fromRgbF(scaled(colour.redF()), scaled(colour.greenF()), scaled(colour.blueF()), a);
}

void Colours::updateLayer() {
    emit layerNeedsUpdateChanged();
    syncTPalette();
}

void Colours::loadState() {
    bool ok;
    wallpaper::currentScheme(&ok).then(this, [this, ok](const lib::SchemeData& data) {
        applyState(data, true);

        if (!ok)
            lib::saveState(data);
    });
}

void Colours::loadSchemes() {
    lib::Scheme::all().then(this, [this](const QList<std::shared_ptr<lib::Scheme>>& schemes) {
        m_schemes.clear();

        m_schemes.emplaceBack(*lib::Scheme::forColour(Qt::black));
        for (const auto& scheme : schemes)
            m_schemes.emplaceBack(*scheme);

        emit schemesChanged();
    });
}

void Colours::setState(const QString& scheme, const QString& flavour, lib::Mode mode, bool commit, bool smart) {
    applyState(scheme, flavour, mode, false, smart).then(this, [this, commit] {
        if (commit)
            this->commit();
    });
}

QFuture<void> Colours::applyState(
    const QString& scheme, const QString& flavour, lib::Mode mode, bool committed, bool smart) {
    return resolveScheme(scheme, flavour, mode, smart)
        .then(this,
            [this, committed](const lib::SchemeData& data) {
                applyState(data, committed);
            })
        .onFailed(this, [](const std::exception& e) {
            qCCritical(lcColours) << "Failed to apply scheme:" << e.what();
        });
}

void Colours::applyState(const lib::SchemeData& data, bool committed) {
    const bool schemeChanged =
        m_state.name != data.name || m_state.flavour != data.flavour || m_state.mode != data.mode;

    m_state = data;
    m_palette->setColours(data.colours);
    syncTPalette();

    if (schemeChanged)
        emit this->schemeChanged();

    if (committed != m_committed) {
        m_committed = committed;
        emit committedChanged();
    }
}

void Colours::syncTPalette() {
    const auto& src = palette()->colours();
    lib::SchemeColours colours;

#define LAYER_COLOUR(name, l) colours.name = layer(src.name, l);
    CAELESTIA_PALETTE_COLOURS(LAYER_COLOUR)
#undef LAYER_COLOUR

    m_tPalette->setColours(colours);
}

void Colours::watch(const QString& path) {
    if (QFileInfo::exists(path) && !m_watcher.files().contains(path))
        m_watcher.addPath(path);
}

void Colours::handleFileChanged(const QString& path) {
    watch(path);
    if (path == lib::statePath())
        loadState();
}

void Colours::handleDirectoryChanged() {
    const auto path = lib::statePath();
    if (m_watcher.files().contains(path))
        return;

    watch(path);

    if (m_watcher.files().contains(path))
        handleFileChanged(path);
}

} // namespace caelestia::shell::scheme
