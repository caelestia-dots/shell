#pragma once

#include <qfont.h>
#include <qqmlintegration.h>
#include <qvariant.h>

namespace caelestia::shell::config {

class FontBuilder {
    Q_GADGET
    QML_ANONYMOUS

public:
    FontBuilder() = default;
    explicit FontBuilder(QFont font);

    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder family(const QString& family);
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder size(int pointSize);
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder weight(QFont::Weight weight);
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder italic(bool on = true);
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder stretch(int stretch);
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder letterSpacing(qreal spacing, bool absolute = true);
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder capitalisation(QFont::Capitalization cap);
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder vaxis(const QString& tag, float value);
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder vaxes(const QVariantMap& axes);
    [[nodiscard]] Q_INVOKABLE QFont build() const;

    // Common vaxes
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder fill(float value);
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder grade(float value);
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder width(float value);

    // Operations
    [[nodiscard]] Q_INVOKABLE caelestia::shell::config::FontBuilder scale(qreal factor);

private:
    QFont m_font;
};

} // namespace caelestia::shell::config
