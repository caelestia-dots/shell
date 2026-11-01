#pragma once

// The wallpaper colour preview: what `caelestia wallpaper -p <image> --no-smart` prints, made in
// process so the shell doesn't start Python for every wallpaper it hovers over.

#include <qbytearray.h>
#include <qstring.h>

namespace caelestia::material {

// The scheme a preview is made for: the one the CLI has applied
struct SchemeState {
    QString variant;
    QString flavour;
    QString mode;
};

// The applied scheme from the CLI's state file, falling back to the CLI's defaults
SchemeState appliedScheme();

// The JSON a preview loads: { name, flavour, mode, variant, colours }. Empty, with `error` set, on
// failure.
QByteArray previewJson(const QString& wallpaper, const SchemeState& scheme, QString* error);

} // namespace caelestia::material
