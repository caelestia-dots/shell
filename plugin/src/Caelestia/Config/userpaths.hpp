#pragma once

#include "configobject.hpp"

#include <qdir.h>
#include <qstandardpaths.h>
#include <qstring.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class UserPaths : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(
        QString, wallpaperDir, QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + u"/Wallpapers"_s)
    CONFIG_GLOBAL_PROPERTY(QString, lyricsDir, QDir::homePath() + u"/Music/lyrics/"_s)
    CONFIG_PROPERTY(QString, sessionGif, u"root:/assets/kurukuru.gif"_s)
    CONFIG_PROPERTY(QString, mediaGif, u"root:/assets/bongocat.gif"_s)
    CONFIG_PROPERTY(QString, noNotifsPic, u"root:/assets/dino.png"_s)
    CONFIG_PROPERTY(QString, lockNoNotifsPic, u"root:/assets/dino.png"_s)

public:
    explicit UserPaths(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
