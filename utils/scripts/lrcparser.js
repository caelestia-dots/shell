function parseLrc(text) {
    let lines = text.split("\n");
    let result = [];

    let timeRegex = /\[(\d+):(\d+\.\d+|\d+)\]/g;

    for (let line of lines) {

        timeRegex.lastIndex = 0;
        let matches = [];
        let match;

        while ((match = timeRegex.exec(line)) !== null) {
            matches.push(match);
        }

        if (matches.length === 0) continue;

        let lyric = line.replace(timeRegex, "").trim();

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
    for (let i = lyrics.length - 1; i >= 0; i--) {
        if (position >= lyrics[i].time) {
            return i;
        }
    }
    return -1;
}
