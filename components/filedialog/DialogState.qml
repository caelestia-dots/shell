import QtQuick
import Caelestia.I18n
import Caelestia.Models

QtObject {
    property list<string> cwd
    property list<var> cwdStack
    property list<string> nameFilters
    property int filters
    property string filterLabel: {
        const images = filters & FileSystemModel.Images;
        const videos = filters & FileSystemModel.Videos;
        if (images && videos)
            return Tr.tr("Images and videos");
        if (images)
            return Tr.tr("Images");
        if (videos)
            return Tr.tr("Videos");
        return Tr.tr("All files");
    }
    property bool save
    property string confirmLabel

    signal accepted(path: string)
    signal rejected

    function cdInto(dir: string): void {
        if (!dir)
            return;

        cwdStack.push([...cwd]);
        cwd.push(dir);
    }

    function cdUp(): void {
        if (!cwd.length)
            return;

        cwdStack.push([...cwd]);
        cwd.pop();
    }

    function cdTo(dir: list<string>): void {
        cwdStack.push([...cwd]);
        cwd = dir;
    }

    function cdBack(): void {
        if (cwdStack.length)
            cwd = cwdStack.pop();
    }
}
