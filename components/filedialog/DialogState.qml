import QtQuick
import Caelestia
import Caelestia.I18n
import Caelestia.Models
import Caelestia.Multimedia

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
    property bool showHidden
    property FileSystemEntry selectedPath

    readonly property bool selectionValid: {
        if (!selectedPath)
            return false;

        const files = (filters & FileSystemModel.Files) !== 0;
        const images = (filters & FileSystemModel.Images) !== 0;
        const videos = (filters & FileSystemModel.Videos) !== 0;
        const dirs = (filters & FileSystemModel.Dirs) !== 0;

        if (selectedPath.isDir)
            return dirs || !(files || images || videos);

        if (nameFilters.length > 0 && !nameFilters.some(f => CUtils.matchGlob(selectedPath.name, f)))
            return false;

        if (files || !(images || videos))
            return true;

        return (images && MediaUtils.isImage(selectedPath.path)) || (videos && MediaUtils.isVideo(selectedPath.path));
    }

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

    function select(entry: FileSystemEntry): void {
        const old = selectedPath;
        entry?.ref(this);
        selectedPath = entry;
        old?.unref(this);
    }
}
