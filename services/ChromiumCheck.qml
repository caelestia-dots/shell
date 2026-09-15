pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    // Added desktop entry as a verification
    // Opera GX, Vivaldi and Chromium tested after (Total: 7 browsers)
    function isChromiumNotification(appName: string, desktopEntry: string): bool {
       return appName === "Brave" && desktopEntry === "brave-browser"
       || appName === "Google Chrome" && desktopEntry === "google-chrome"
       || appName === "Microsoft Edge" && desktopEntry === "microsoft-edge"
       || appName === "Opera" && desktopEntry === "opera"
       || appName === "Opera GX" && desktopEntry === "opera"
       || appName === "Vivaldi" && desktopEntry === "vivaldi"
       || appName === "Chromium" && desktopEntry === "chromium";
    }
    
    Process {
        id: createNotifDir

	    command: ["mkdir", "-p", Paths.chromiumicons]

	    Component.onCompleted: running = true
    }
	
    Process {
        id: copyChromiumImage

	    property string sourcePath
	    property string destinationPath
	    
	   // Chromiumms only uses single icon.png in their respective tmp
	   // copying it would make sense rather than moving it
	    command: ["cp", sourcePath, destinationPath]
    }
    
    // checks whether it needs to redirect the cached image to caelestia/chromium path
    function processNotifs(appName: string, imagePath: string, desktopEntry: string): string {
        const path = imagePath.replace("image://icon/", "");

	    if (isChromiumNotification(appName, desktopEntry)) {
		
            copyChromiumImage.sourcePath = path;
            copyChromiumImage.destinationPath = Paths.chromiumicons + "/" + appName + ".png";
	        copyChromiumImage.running = true;

	        return "image://icon/" + Paths.chromiumicons + "/" + appName + ".png";
	    }
	    return imagePath;
    }
}
