function parseLrc(text) {
    if (!text) return [];
    let lines = text.split("\n");
    let result = [];

    let timeRegex = /\[(\d+):(\d+\.\d+|\d+)\]/g;

    // Blacklist for credits/metadata often found in NetEase lyrics
    const creditKeywords = [
        "作词", "作曲", "编曲", "制作", "收录", "演奏", "词：", "曲：", "Lyricist", "Composer", "Arranger", "Producer", "Mixing", "Mastering"
    ];

    for (let line of lines) {

        timeRegex.lastIndex = 0;
        let matches = [];
        let match;

        while ((match = timeRegex.exec(line)) !== null) {
            matches.push(match);
        }

        if (matches.length === 0) continue;

        let lyric = line.replace(timeRegex, "").trim();

        let min = parseInt(matches[0][1]);
        let sec = parseFloat(matches[0][2]);
        let totalTime = min * 60 + sec;

        // Only filter credits if they appear in the first 20 seconds
        if (totalTime < 20) {
            let isCreditFormat = creditKeywords.some(k => lyric.includes(k));
            if (isCreditFormat && (lyric.includes(":") || lyric.includes("：") || lyric.length < 25)) {
                continue;
            }
        }

        for (let match of matches) {
            let min = parseInt(match[1]);
            let sec = parseFloat(match[2]);

            result.push({
                time: min * 60 + sec,
                text: lyric
            });
        }
    }

    result.sort((a, b) => a.time - b.time);
    return result;
}

function getCurrentLine(lyrics, position) {
    const epsilon = 0.1; // 100ms tolerance
    for (let i = lyrics.length - 1; i >= 0; i--) {
        if ((position + epsilon) >= lyrics[i].time) {
            return i;
        }
    }
    return -1;
}
