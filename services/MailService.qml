pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

Singleton {
    id: root

    property list<string> unreadEmails: []

    property int refCount

    reloadableId: "mailText"

    Timer {
        running: root.refCount > 0
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            getUnreadEmails.running = true;
        }
    }

    Process {
        id: getUnreadEmails

        running: true
        command: Config.bar.mail.fetchCommand
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const json = JSON.parse(text);
                    // stripEmoji to get rid  of QT warnings:
                    // WARN: render glyph failed err=9e face=0x7f989de17600, glyph=891
                    // WARN: QFontEngine: Glyph rendered in unknown pixel_mode=0
                    const stripEmoji = str => str.replace(/\p{Emoji_Presentation}/gu, '').trim();
                    const unreadEmails = json.filter(m => m && m.authors && m.subject)   // safety guard
                    .map(m => `${m.authors}: ${stripEmoji(m.subject)}`);
                    root.unreadEmails = unreadEmails;
                } catch (e) {
                    console.error("Failed to parse mail output:", e.message);
                    root.unreadEmails = [];
                }
            }
        }
    }
}
