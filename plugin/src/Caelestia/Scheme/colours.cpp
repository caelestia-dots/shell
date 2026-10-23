#include "colours.hpp"

#include <qloggingcategory.h>

#include <caelestia/theme/theme.hpp>

#include "config/rootnodes.hpp"
#include "wallpapers.hpp"

namespace {

Q_LOGGING_CATEGORY(lcColours, "caelestia.scheme.colours", QtInfoMsg)

} // namespace

namespace caelestia::shell::scheme {

using Qt::StringLiterals::operator""_s;

namespace {

const QString k_dynamic = u"dynamic"_s;

qreal luminance(const QColor& colour) {
    const auto r = static_cast<qreal>(colour.redF());
    const auto g = static_cast<qreal>(colour.greenF());
    const auto b = static_cast<qreal>(colour.blueF());
    if (qFuzzyIsNull(r) && qFuzzyIsNull(g) && qFuzzyIsNull(b))
        return 0;
    return std::sqrt(0.299 * r * r + 0.587 * g * g + 0.114 * b * b);
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
    connect(transparency, &config::AppearanceTransparency::enabledChanged, this, &Colours::syncTPalette);
    connect(transparency, &config::AppearanceTransparency::baseChanged, this, &Colours::syncTPalette);
    connect(transparency, &config::AppearanceTransparency::layersChanged, this, &Colours::syncTPalette);
    connect(Wallpapers::instance(), &Wallpapers::analysisDone, this, &Colours::syncTPalette);
}

bool Colours::committed() const {
    return m_committed;
}

QString Colours::scheme() const {
    return m_state.name;
}

void Colours::setScheme(const QString& scheme) {
    applyState(scheme, m_state.flavour, m_state.mode);
}

QString Colours::flavour() const {
    return m_state.flavour;
}

void Colours::setFlavour(const QString& flavour) {
    applyState(m_state.name, flavour, m_state.mode);
}

Colours::Mode Colours::mode() const {
    return m_state.mode == lib::Mode::Light ? Mode::Light : Mode::Dark;
}

void Colours::setMode(Mode mode) {
    applyState(m_state.name, m_state.flavour, mode == Mode::Light ? lib::Mode::Light : lib::Mode::Dark);
}

ColourPalette* Colours::palette() const {
    return m_palette;
}

ColourPalette* Colours::tPalette() const {
    return m_tPalette;
}

void Colours::commit() {
    if (m_committed)
        return;

    theme::Theme(m_state).apply().then(this, [this] {
        m_committed = true;
        emit committedChanged();
    });
}

void Colours::reset() {
    if (m_committed)
        return;

    loadState();

    m_committed = true;
    emit committedChanged();
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

void Colours::loadState() {
    if (const auto state = lib::loadState()) {
        applyState(*state, true);
        return;
    }

    lib::defaultScheme().then(this, [this](const lib::SchemeData& data) {
        applyState(data, true);
    });
}

void Colours::applyState(const QString& scheme, const QString& flavour, lib::Mode mode) {
    if (scheme == k_dynamic) {
        const auto colours = Wallpapers::instance()->colours();
        if (colours.isEmpty()) {
            qCCritical(lcColours) << "Failed to apply mode: no colours found in the current wallpaper";
            return;
        }

        getSchemeData(lib::Scheme::forColour(colours.first()), flavour, mode)
            .then(this, [this](const lib::SchemeData& data) {
                applyState(data);
            });
    } else {
        lib::Scheme::forName(scheme)
            .then([flavour, mode](const std::shared_ptr<lib::Scheme>& s) {
                return getSchemeData(s, flavour, mode);
            })
            .unwrap()
            .then(this, [this](const lib::SchemeData& data) {
                applyState(data);
            });
    }
}

void Colours::applyState(const lib::SchemeData& data, bool committed) {
    const bool schemeChanged =
        m_state.name != data.name || m_state.flavour != data.flavour || m_state.mode != data.mode;

    m_state = data;
    m_palette->setColours(data.colours);
    syncTPalette();

    if (schemeChanged)
        emit this->schemeChanged();

    if (!committed && m_committed) {
        m_committed = false;
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
