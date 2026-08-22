#include "font.hpp"

#include "appearanceconfig.hpp"

namespace caelestia::config {

namespace {

settings::ObjectNode* style(settings::ObjectNode* cfg, const QString& key) {
    return cfg->value(key).value<settings::ObjectNode*>();
}

} // namespace

// FontStyleBase

QFont FontStyleBase::large() const {
    return m_large;
}

QFont FontStyleBase::medium() const {
    return m_medium;
}

QFont FontStyleBase::small() const {
    return m_small;
}

QFont FontStyleBase::buildFont(const settings::ObjectNode* cfg, const QString& fallbackFamily, qreal scale) {
    const auto family = cfg->value(u"family"_s).toString();
    const auto size = cfg->value(u"size"_s).toInt();
    const auto weight = cfg->value(u"weight"_s).value<QFont::Weight>();
    const auto italic = cfg->value(u"italic"_s).toBool();
    const auto vaxes = cfg->value(u"vaxes"_s).toMap();

    QFont font;
    font.setFamily(family.isEmpty() ? fallbackFamily : family);
    const int scaledSize = static_cast<int>(size * scale);
    const int cappedSize = scaledSize > 0 ? scaledSize : 1;
    font.setPointSize(cappedSize);
    font.setVariableAxis("opsz", static_cast<float>(cappedSize));
    font.setWeight(weight);
    font.setVariableAxis("wght", weight);
    font.setItalic(italic);

    for (auto it = vaxes.constBegin(); it != vaxes.constEnd(); ++it) {
        if (auto tag = QFont::Tag::fromString(it.key()))
            font.setVariableAxis(*tag, it.value().toFloat());
    }

    return font;
}

void FontStyleBase::bind(settings::ObjectNode* cfg) {
    if (m_cfg == cfg)
        return;

    if (m_cfg) {
        disconnect(m_cfg, nullptr, this, nullptr);
        disconnect(style(m_cfg, u"large"_s), nullptr, this, nullptr);
        disconnect(style(m_cfg, u"medium"_s), nullptr, this, nullptr);
        disconnect(style(m_cfg, u"small"_s), nullptr, this, nullptr);
    }

    m_cfg = cfg;

    if (cfg) {
        connect(cfg, &settings::Node::optionChanged, this, &FontStyleBase::rebuild);
        connect(style(cfg, u"large"_s), &settings::Node::optionChanged, this, &FontStyleBase::rebuild);
        connect(style(cfg, u"medium"_s), &settings::Node::optionChanged, this, &FontStyleBase::rebuild);
        connect(style(cfg, u"small"_s), &settings::Node::optionChanged, this, &FontStyleBase::rebuild);
    }

    rebuild();
}

void FontStyleBase::rebuild() {
    if (m_cfg) {
        const auto family = m_cfg->value(u"family"_s).toString();
        m_large = buildFont(style(m_cfg, u"large"_s), family, m_scale);
        m_medium = buildFont(style(m_cfg, u"medium"_s), family, m_scale);
        m_small = buildFont(style(m_cfg, u"small"_s), family, m_scale);
    } else {
        m_large = QFont();
        m_medium = QFont();
        m_small = QFont();
    }
    emit fontsChanged();
}

void FontStyleBase::setScale(qreal scale) {
    if (qFuzzyCompare(m_scale + 1.0, scale + 1.0))
        return;
    m_scale = scale;
    rebuild();
}

// FontStyle

FontStyle::FontStyle(QObject* parent)
    : FontStyleBase(parent)
    , m_builders(new FontBuilders(this, this)) {}

FontBuilders* FontStyle::builders() const {
    return m_builders;
}

// IconFontStyle

IconFontStyle::IconFontStyle(QObject* parent)
    : FontStyleBase(parent)
    , m_builders(new IconFontBuilders(this, this)) {}

FontBuilder IconFontStyle::size(int pointSize) {
    return FontBuilder(m_small).size(pointSize);
}

void IconFontStyle::bind(settings::ObjectNode* cfg) {
    if (m_cfg == cfg)
        return;

    if (m_cfg)
        disconnect(style(m_cfg, u"extraLarge"_s), nullptr, this, nullptr);

    FontStyleBase::bind(cfg);

    if (cfg)
        connect(style(cfg, u"extraLarge"_s), &settings::Node::optionChanged, this, &IconFontStyle::rebuild);
}

QFont IconFontStyle::extraLarge() const {
    return m_extraLarge;
}

IconFontBuilders* IconFontStyle::builders() const {
    return m_builders;
}

void IconFontStyle::rebuild() {
    if (m_cfg) {
        const auto family = m_cfg->value(u"family"_s).toString();
        m_extraLarge = buildFont(style(m_cfg, u"extraLarge"_s), family, m_scale);
    } else {
        m_extraLarge = QFont();
    }
    FontStyleBase::rebuild();
}

// FontBuilders

FontBuilders::FontBuilders(const FontStyleBase* style, QObject* parent)
    : QObject(parent)
    , m_style(style) {
    connect(style, &FontStyleBase::fontsChanged, this, &FontBuilders::buildersChanged);
}

FontBuilder FontBuilders::large() const {
    return FontBuilder(m_style->large());
}

FontBuilder FontBuilders::medium() const {
    return FontBuilder(m_style->medium());
}

FontBuilder FontBuilders::small() const {
    return FontBuilder(m_style->small());
}

// IconFontBuilders

IconFontBuilders::IconFontBuilders(const IconFontStyle* style, QObject* parent)
    : FontBuilders(style, parent) {}

FontBuilder IconFontBuilders::extraLarge() const {
    return FontBuilder(static_cast<const IconFontStyle*>(m_style)->extraLarge());
}

// FontTokens

FontTokens::FontTokens(QObject* parent)
    : QObject(parent)
    , m_headline(new FontStyle(this))
    , m_title(new FontStyle(this))
    , m_body(new FontStyle(this))
    , m_label(new FontStyle(this))
    , m_mono(new FontStyle(this))
    , m_icon(new IconFontStyle(this)) {}

FontStyle* FontTokens::headline() const {
    return m_headline;
}

FontStyle* FontTokens::title() const {
    return m_title;
}

FontStyle* FontTokens::body() const {
    return m_body;
}

FontStyle* FontTokens::label() const {
    return m_label;
}

FontStyle* FontTokens::mono() const {
    return m_mono;
}

IconFontStyle* FontTokens::icon() const {
    return m_icon;
}

FontBuilder FontTokens::clock() const {
    return FontBuilder(m_clock);
}

QString FontTokens::workspaces() const {
    return m_font ? m_font->workspaces() : QString();
}

void FontTokens::bindFont(AppearanceFont* font) {
    if (m_font == font)
        return;

    if (m_font)
        disconnect(m_font, nullptr, this, nullptr);

    m_font = font;

    if (font) {
        rebuildScale();
        m_headline->bind(font->headline());
        m_title->bind(font->title());
        m_body->bind(font->body());
        m_label->bind(font->label());
        m_mono->bind(font->mono());
        m_icon->bind(font->icon());

        connect(font, &AppearanceFont::clockChanged, this, &FontTokens::rebuildClock);
        connect(font, &AppearanceFont::scaleChanged, this, &FontTokens::rebuildScale);
        connect(font, &AppearanceFont::workspacesChanged, this, &FontTokens::workspacesChanged);
    } else {
        rebuildScale();
        m_headline->bind(nullptr);
        m_title->bind(nullptr);
        m_body->bind(nullptr);
        m_label->bind(nullptr);
        m_mono->bind(nullptr);
        m_icon->bind(nullptr);
    }

    rebuildClock();
    emit workspacesChanged();
}

void FontTokens::rebuildScale() {
    const qreal s = m_font ? m_font->scale() : 1;
    m_headline->setScale(s);
    m_title->setScale(s);
    m_body->setScale(s);
    m_label->setScale(s);
    m_mono->setScale(s);
    m_icon->setScale(s);
}

void FontTokens::rebuildClock() {
    QFont f;
    if (m_font)
        f.setFamily(m_font->clock());
    m_clock = f;
    emit clockChanged();
}

} // namespace caelestia::config
