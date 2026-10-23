#pragma once

#include <qcolor.h>
#include <qfilesystemwatcher.h>
#include <qfuture.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>

#include <caelestia/scheme/scheme.hpp>

// X(colour name, transparency layer)
#define CAELESTIA_PALETTE_COLOURS(X)                                                                                   \
    X(primaryPaletteKeyColour, 1)                                                                                      \
    X(secondaryPaletteKeyColour, 1)                                                                                    \
    X(tertiaryPaletteKeyColour, 1)                                                                                     \
    X(neutralPaletteKeyColour, 1)                                                                                      \
    X(neutralVariantPaletteKeyColour, 1)                                                                               \
    X(errorPaletteKeyColour, 1)                                                                                        \
    X(background, 0)                                                                                                   \
    X(onBackground, 1)                                                                                                 \
    X(surface, 0)                                                                                                      \
    X(surfaceDim, 0)                                                                                                   \
    X(surfaceBright, 0)                                                                                                \
    X(surfaceContainerLowest, 1)                                                                                       \
    X(surfaceContainerLow, 1)                                                                                          \
    X(surfaceContainer, 1)                                                                                             \
    X(surfaceContainerHigh, 1)                                                                                         \
    X(surfaceContainerHighest, 1)                                                                                      \
    X(onSurface, 1)                                                                                                    \
    X(onSurfaceVariant, 1)                                                                                             \
    X(outline, 1)                                                                                                      \
    X(outlineVariant, 1)                                                                                               \
    X(inverseSurface, 0)                                                                                               \
    X(inverseOnSurface, 1)                                                                                             \
    X(primary, 1)                                                                                                      \
    X(onPrimary, 1)                                                                                                    \
    X(primaryContainer, 1)                                                                                             \
    X(onPrimaryContainer, 1)                                                                                           \
    X(primaryFixed, 1)                                                                                                 \
    X(primaryFixedDim, 1)                                                                                              \
    X(onPrimaryFixed, 1)                                                                                               \
    X(onPrimaryFixedVariant, 1)                                                                                        \
    X(inversePrimary, 1)                                                                                               \
    X(secondary, 1)                                                                                                    \
    X(onSecondary, 1)                                                                                                  \
    X(secondaryContainer, 1)                                                                                           \
    X(onSecondaryContainer, 1)                                                                                         \
    X(secondaryFixed, 1)                                                                                               \
    X(secondaryFixedDim, 1)                                                                                            \
    X(onSecondaryFixed, 1)                                                                                             \
    X(onSecondaryFixedVariant, 1)                                                                                      \
    X(tertiary, 1)                                                                                                     \
    X(onTertiary, 1)                                                                                                   \
    X(tertiaryContainer, 1)                                                                                            \
    X(onTertiaryContainer, 1)                                                                                          \
    X(tertiaryFixed, 1)                                                                                                \
    X(tertiaryFixedDim, 1)                                                                                             \
    X(onTertiaryFixed, 1)                                                                                              \
    X(onTertiaryFixedVariant, 1)                                                                                       \
    X(error, 1)                                                                                                        \
    X(onError, 1)                                                                                                      \
    X(errorContainer, 1)                                                                                               \
    X(onErrorContainer, 1)                                                                                             \
    X(success, 1)                                                                                                      \
    X(onSuccess, 1)                                                                                                    \
    X(successContainer, 1)                                                                                             \
    X(onSuccessContainer, 1)                                                                                           \
    X(term0, 1)                                                                                                        \
    X(term1, 1)                                                                                                        \
    X(term2, 1)                                                                                                        \
    X(term3, 1)                                                                                                        \
    X(term4, 1)                                                                                                        \
    X(term5, 1)                                                                                                        \
    X(term6, 1)                                                                                                        \
    X(term7, 1)                                                                                                        \
    X(term8, 1)                                                                                                        \
    X(term9, 1)                                                                                                        \
    X(term10, 1)                                                                                                       \
    X(term11, 1)                                                                                                       \
    X(term12, 1)                                                                                                       \
    X(term13, 1)                                                                                                       \
    X(term14, 1)                                                                                                       \
    X(term15, 1)

namespace caelestia::shell::scheme {

namespace lib = ::caelestia::scheme;

class ColourPalette : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("ColourPalette instances can only be retrieved from Colours")

#define PROP(name, layer) Q_PROPERTY(QColor name READ name NOTIFY changed)
    CAELESTIA_PALETTE_COLOURS(PROP)
#undef PROP

public:
    explicit ColourPalette(QObject* parent = nullptr);

    [[nodiscard]] const lib::SchemeColours& colours() const;
    void setColours(const lib::SchemeColours& colours);

#define GETTER(name, layer) [[nodiscard]] QColor name() const;
    CAELESTIA_PALETTE_COLOURS(GETTER)
#undef GETTER

signals:
    void changed();

private:
    lib::SchemeColours m_colours;
};

class Colours : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(ColoursImpl)

    /// All scheme/colour properties are previews that are applied to only the shell until committed.
    /// When a scheme property is changed, it will not be committed until `commit()` is called.
    /// Properties can be reset via `reset()`.
    Q_PROPERTY(bool committed READ committed NOTIFY committedChanged)

    Q_PROPERTY(QString scheme READ scheme NOTIFY schemeChanged)
    Q_PROPERTY(QString flavour READ flavour NOTIFY schemeChanged)
    Q_PROPERTY(caelestia::shell::scheme::Colours::Mode mode READ mode NOTIFY schemeChanged)

    Q_PROPERTY(caelestia::shell::scheme::ColourPalette* palette READ palette CONSTANT)
    Q_PROPERTY(caelestia::shell::scheme::ColourPalette* tPalette READ tPalette CONSTANT)

    Q_PROPERTY(bool __layerNeedsUpdate READ layerNeedsUpdate NOTIFY layerNeedsUpdateChanged)

public:
    enum class Mode : quint8 {
        Light = static_cast<quint8>(lib::Mode::Light),
        Dark = static_cast<quint8>(lib::Mode::Dark),
    };
    Q_ENUM(Mode)

    explicit Colours(QObject* parent = nullptr);

    [[nodiscard]] bool committed() const;

    [[nodiscard]] QString scheme() const;
    [[nodiscard]] QString flavour() const;
    [[nodiscard]] Mode mode() const;

    [[nodiscard]] ColourPalette* palette() const;
    [[nodiscard]] ColourPalette* tPalette() const;

    [[nodiscard]] static bool layerNeedsUpdate();

    Q_INVOKABLE void commit();
    Q_INVOKABLE void reset();

    Q_INVOKABLE void setScheme(const QString& scheme, bool commit = true);
    Q_INVOKABLE void setFlavour(const QString& flavour, bool commit = true);
    Q_INVOKABLE void setMode(Mode mode, bool commit = true);

    // NOLINTNEXTLINE(readability-identifier-naming)
    [[nodiscard]] Q_INVOKABLE QColor _layer(const QColor& colour, int layer) const;
    [[nodiscard]] QColor layer(const QColor& colour, int layer = 1) const;

signals:
    void committedChanged();
    void schemeChanged();

    void layerNeedsUpdateChanged();

private:
    bool m_committed = true;

    ColourPalette* const m_palette;
    ColourPalette* const m_tPalette;

    lib::SchemeData m_state;
    QFileSystemWatcher m_watcher;

    [[nodiscard]] QColor alter(const QColor& colour, qreal alpha, int layer) const;

    void updateLayer();

    void loadState();
    void setState(const QString& scheme, const QString& flavour, lib::Mode mode, bool commit);
    QFuture<void> applyState(const QString& scheme, const QString& flavour, lib::Mode mode, bool committed = false);
    void applyState(const lib::SchemeData& data, bool committed = false);
    void syncTPalette();

    void watch(const QString& path);
    void handleFileChanged(const QString& path);
    void handleDirectoryChanged();
};

} // namespace caelestia::shell::scheme
