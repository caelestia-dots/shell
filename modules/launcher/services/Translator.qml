pragma Singleton

import ".."
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property string sourceLanguage: "fr"
    property string targetLanguage: ""
    property string lastTranslation: ""
    property bool isLoading: false
    property string error: ""
    
    property list<var> languages: [
        { name: "French", code: "fr" },
        { name: "English", code: "en" },
        { name: "Spanish", code: "es" },
        { name: "German", code: "de" },
        { name: "Italian", code: "it" },
        { name: "Portuguese", code: "pt" },
        { name: "Russian", code: "ru" },
        { name: "Japanese", code: "ja" },
        { name: "Chinese", code: "zh" },
        { name: "Korean", code: "ko" },
        { name: "Arabic", code: "ar" },
        { name: "Dutch", code: "nl" },
        { name: "Polish", code: "pl" },
        { name: "Turkish", code: "tr" },
        { name: "Swedish", code: "sv" },
        { name: "Norwegian", code: "no" },
        { name: "Danish", code: "da" },
        { name: "Finnish", code: "fi" },
        { name: "Czech", code: "cs" },
        { name: "Hungarian", code: "hu" },
        { name: "Romanian", code: "ro" },
        { name: "Bulgarian", code: "bg" },
        { name: "Croatian", code: "hr" },
        { name: "Slovak", code: "sk" },
        { name: "Slovenian", code: "sl" },
        { name: "Estonian", code: "et" },
        { name: "Latvian", code: "lv" },
        { name: "Lithuanian", code: "lt" },
        { name: "Greek", code: "el" },
        { name: "Hebrew", code: "he" },
        { name: "Thai", code: "th" },
        { name: "Vietnamese", code: "vi" },
        { name: "Indonesian", code: "id" },
        { name: "Malay", code: "ms" },
        { name: "Hindi", code: "hi" },
        { name: "Bengali", code: "bn" },
        { name: "Tamil", code: "ta" },
        { name: "Telugu", code: "te" },
        { name: "Marathi", code: "mr" },
        { name: "Gujarati", code: "gu" },
        { name: "Kannada", code: "kn" },
        { name: "Malayalam", code: "ml" },
        { name: "Punjabi", code: "pa" },
        { name: "Urdu", code: "ur" },
        { name: "Persian", code: "fa" },
        { name: "Ukrainian", code: "uk" },
        { name: "Belarusian", code: "be" },
        { name: "Macedonian", code: "mk" },
        { name: "Albanian", code: "sq" },
        { name: "Serbian", code: "sr" },
        { name: "Bosnian", code: "bs" },
        { name: "Montenegrin", code: "me" },
        { name: "Icelandic", code: "is" },
        { name: "Irish", code: "ga" },
        { name: "Welsh", code: "cy" },
        { name: "Scottish Gaelic", code: "gd" },
        { name: "Maltese", code: "mt" },
        { name: "Basque", code: "eu" },
        { name: "Catalan", code: "ca" },
        { name: "Galician", code: "gl" }
    ]

    property PersistentProperties storage: PersistentProperties {
        id: storage
        reloadableId: "translator"
        
        property string sourceLanguage: "fr"
        property string targetLanguage: ""
    }

    Component.onCompleted: {
        sourceLanguage = storage.sourceLanguage;
        targetLanguage = storage.targetLanguage;
    }

    onSourceLanguageChanged: {
        if (sourceLanguage !== storage.sourceLanguage) {
            storage.sourceLanguage = sourceLanguage;
        }
    }

    onTargetLanguageChanged: {
        if (targetLanguage !== storage.targetLanguage) {
            storage.targetLanguage = targetLanguage;
        }
    }

    function translate(text, callback) {
        if (!text || text.trim().length === 0) {
            lastTranslation = "";
            error = "";
            if (callback) callback({ translatedText: "", alternatives: [] });
            return;
        }

        if (!targetLanguage || targetLanguage === "") {
            error = "No target language selected";
            if (callback) callback({ translatedText: "", alternatives: [], error: error });
            return;
        }

        isLoading = true;
        error = "";

        const encodedText = encodeURIComponent(text);
        const url = `https://translate.google.com/translate_a/single?client=gtx&sl=auto&tl=${targetLanguage}&dt=t&q=${encodedText}`;

        translateProc.command = [
            "/usr/bin/curl", "-s", "-X", "GET", url
        ];
        translateProc.running = true;
    }

    function swapLanguages() {
        const temp = sourceLanguage;
        sourceLanguage = targetLanguage;
        targetLanguage = temp;
    }

    function autoDetectLanguage(text) {
        return sourceLanguage;
    }

    Process {
        id: translateProc

        stdout: StdioCollector {
            onStreamFinished: {
                isLoading = false;
                
                const translation = text.trim();
                if (translation && translation !== "null" && translation !== "") {
                    try {
                        const response = JSON.parse(translation);
                        if (response && response[0] && response[0][0] && response[0][0][0]) {
                            lastTranslation = response[0][0][0];
                            error = "";
                        } else {
                            error = "Invalid response format";
                            lastTranslation = "";
                        }
                    } catch (e) {
                        error = "Parse error: " + e.message;
                        lastTranslation = "";
                    }
                } else {
                    error = "No translation received";
                    lastTranslation = "";
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    isLoading = false;
                    error = "Network error: " + text;
                    lastTranslation = "";
                }
            }
        }

        onExited: code => {
            if (code !== 0) {
                isLoading = false;
                if (!error) {
                    error = "Process failed with exit code: " + code;
                    lastTranslation = "";
                }
            }
        }
    }
}
