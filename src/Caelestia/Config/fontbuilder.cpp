#include "fontbuilder.hpp"
#include <qloggingcategory.h>

namespace caelestia::config {

Q_LOGGING_CATEGORY(lcFontBuilder, "caelestia.fontbuilder", QtInfoMsg)

FontBuilder::FontBuilder(QFont font)
    : m_font(std::move(font)) {}

FontBuilder FontBuilder::family(const QString& family) {
    m_font.setFamily(family);
    return *this;
}

FontBuilder FontBuilder::size(int pointSize) {
    if (pointSize <= 0)
        pointSize = 1;
    m_font.setPointSize(pointSize);
    m_font.setVariableAxis("opsz", static_cast<float>(pointSize));
    return *this;
}

FontBuilder FontBuilder::weight(QFont::Weight weight) {
    m_font.setWeight(weight);
    m_font.setVariableAxis("wght", weight);
    return *this;
}

FontBuilder FontBuilder::italic(bool on) {
    m_font.setItalic(on);
    return *this;
}

FontBuilder FontBuilder::stretch(int stretch) {
    m_font.setStretch(stretch);
    return *this;
}

FontBuilder FontBuilder::letterSpacing(qreal spacing, bool absolute) {
    m_font.setLetterSpacing(absolute ? QFont::AbsoluteSpacing : QFont::PercentageSpacing, spacing);
    return *this;
}

FontBuilder FontBuilder::capitalisation(QFont::Capitalization cap) {
    m_font.setCapitalization(cap);
    return *this;
}

FontBuilder FontBuilder::vaxis(const QString& tag, float value) {
    if (auto t = QFont::Tag::fromString(tag))
        m_font.setVariableAxis(*t, value);
    else
        qCWarning(lcFontBuilder) << "Unable to convert tag" << tag << "to QFont::Tag";
    return *this;
}

FontBuilder FontBuilder::vaxes(QVariantMap axes) {
    for (auto it = axes.constBegin(); it != axes.constEnd(); ++it) {
        if (it.value().canConvert<float>()) {
            if (auto tag = QFont::Tag::fromString(it.key()))
                m_font.setVariableAxis(*tag, it.value().toFloat());
            else
                qCWarning(lcFontBuilder) << "Unable to convert tag" << it.key() << "to QFont::Tag";
        } else {
            qCWarning(lcFontBuilder) << "Unable to convert value" << it.value() << "to float";
        }
    }
    return *this;
}

QFont FontBuilder::build() const {
    return m_font;
}

FontBuilder FontBuilder::fill(float value) {
    return vaxis("FILL", value);
}

FontBuilder FontBuilder::grade(float value) {
    return vaxis("GRAD", value);
}

FontBuilder FontBuilder::width(float value) {
    return vaxis("wdth", value);
}

FontBuilder FontBuilder::scale(qreal factor) {
    return size(static_cast<int>(m_font.pointSize() * factor));
}

} // namespace caelestia::config
