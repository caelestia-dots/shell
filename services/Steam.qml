pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n

Singleton {
    id: root

    readonly property bool enabled: GlobalConfig.addons.steam.enabled
    readonly property string apiKey: GlobalConfig.addons.steam.apiKey
    readonly property string steamIdInput: GlobalConfig.addons.steam.steamId
    readonly property int refreshMinutes: Math.max(1, GlobalConfig.addons.steam.refreshMinutes || 10)
    readonly property bool configured: apiKey.length > 0 && steamIdInput.length > 0
    // Cap the achievements sampling GETs (1 per candidate game) — a big
    // library otherwise fires hundreds of requests on the first reload.
    readonly property int achievementSampleLimit: 60
    // The periodic reload only runs while the dashboard shows the Games tab
    // (fetched data is irrelevant while hidden).
    property bool gamesTabVisible: false

    property bool loading: false
    property string error: ""
    property string resolvedSteamId: ""
    property int steamLevel: 0
    property var profile: null
    property list<var> recentGames: []
    property list<var> nonSteamGames: [] // experimental: local shortcuts.vdf
    property list<string> hiddenAppIds: [] // Steam "Hidden" collection (local)
    property string focusAppId: ""
    property string focusGameName: ""
    property list<var> focusAchievements: [] // unlocked rarest first, then locked most common first
    readonly property list<int> focusUnlockTimes: focusAchievements.map(a => a.unlockTime).filter(t => t > 0)
    property var activity: ({}) // { days, sessions, active } from steam-activity.py
    property string lastActivityJson: ""
    property real activityNow: Date.now() / 1000
    readonly property var dailyPlaytime: activity.days ?? {}
    readonly property var focusSessions: {
        const list = (activity.sessions ?? {})[focusAppId] ?? [];
        const liveStart = (activity.active ?? {})[focusAppId];
        return liveStart ? [{
                start: liveStart,
                end: Math.max(liveStart, activityNow),
                live: true
            }, ...list] : list;
    }
    readonly property string activityScript: Quickshell.shellPath("scripts/steam-activity.py")
    property var focusProgress: null
    readonly property var focusGame: recentGames.find(g => g.appId === focusAppId) ?? topGamesByPlaytime.find(g => g.appId === focusAppId) ?? nonSteamGames.find(g => g.appId === focusAppId) ?? null
    readonly property bool focusPlayingNow: !!profile?.gameId && profile.gameId === focusAppId
    readonly property bool focusNonSteam: !!focusGame?.nonSteam
    readonly property string nonSteamScript: Quickshell.shellPath("scripts/steam-nonsteam.py")
    property bool focusLoading: false
    property string focusError: ""
    // Generic library / social stats (header)
    property int gameCount: 0
    property int totalPlaytimeMinutes: 0
    property int recentPlaytimeMinutes: 0
    property list<var> ownedGames: [] // full owned list; derived stats skip hidden
    property list<var> topGamesByPlaytime: []
    property list<var> topGamesByRecency: [] // owned games with lastPlayed, newest first
    property list<string> achievementCandidates: [] // played games with community stats, by playtime

    function isHiddenApp(appId: string): bool {
        return root.hiddenAppIds.indexOf(String(appId)) >= 0;
    }

    function applyHiddenFilter(): void {
        root.recentGames = root.recentGames.filter(g => !root.isHiddenApp(g.appId));
        root.recentPlaytimeMinutes = root.recentGames.reduce((a, g) => a + (g.playtime2Weeks || 0), 0);
        root.refreshOwnedDerived();
        if (root.isHiddenApp(root.focusAppId)) {
            const next = root.pickerGames[0];
            if (next)
                root.setFocusApp(next.appId, next.name);
        }
    }

    function refreshOwnedDerived(): void {
        const visible = root.ownedGames.filter(g => !root.isHiddenApp(g.appId));
        root.gameCount = visible.length;
        root.totalPlaytimeMinutes = visible.reduce((a, g) => a + (g.playtimeForever || 0), 0);
        const byTime = visible.slice().sort((a, b) => b.playtimeForever - a.playtimeForever);
        root.topGamesByPlaytime = byTime.slice(0, 5);
        root.topGamesByRecency = visible.filter(g => g.lastPlayed > 0).sort((a, b) => b.lastPlayed - a.lastPlayed).slice(0, 20);
        root.achievementCandidates = visible.filter(g => g.hasStats && g.playtimeForever > 0).sort((a, b) => b.playtimeForever - a.playtimeForever).map(g => g.appId);
    }

    // Cover picker: Steam + Non-Steam, sorted by last played (playing now first)
    readonly property var pickerGames: {
        const map = {};
        const bump = Math.floor(Date.now() / 1000) + 10;

        function put(game, fallbackLast) {
            if (!game?.appId || root.isHiddenApp(game.appId))
                return;
            const prev = map[game.appId] || {};
            const lastPlayed = Math.max(prev.lastPlayed || 0, game.lastPlayed || 0, fallbackLast || 0);
            map[game.appId] = Object.assign({}, prev, game, {
                lastPlayed: lastPlayed,
                headerUrl: game.headerUrl || prev.headerUrl || "",
                capsuleUrl: game.capsuleUrl || prev.capsuleUrl || ""
            });
        }

        for (const g of root.topGamesByRecency)
            put(g, 0);
        for (const g of root.topGamesByPlaytime)
            put(g, 0);
        // Recently played from Steam may lack rtime; keep their relative order near "now"
        for (let i = 0; i < root.recentGames.length; i++)
            put(root.recentGames[i], bump - 1 - i);
        for (const g of root.nonSteamGames)
            put(g, 0);

        if (root.profile?.gameId && map[root.profile.gameId])
            map[root.profile.gameId] = Object.assign({}, map[root.profile.gameId], {
                lastPlayed: bump + 1
            });

        return Object.values(map).sort((a, b) => (b.lastPlayed || 0) - (a.lastPlayed || 0));
    }
    property int friendsTotal: -1
    property int friendsOnline: -1
    property int friendsInGame: -1
    property string friendsError: ""
    property list<var> friendsPreview: [] // online friends with avatars
    property var libraryAchievements: null // { unlocked, total, percent, sampled, perfect }
    property bool libraryAchievementsLoading: false

    property int gen: 0
    property var schemaCache: ({})
    property var globalPctCache: ({})
    property var achievementsCache: ({})

    readonly property string statusText: {
        if (!enabled)
            return Tr.tr("Disabled — Games tab is hidden");
        if (!configured)
            return Tr.tr("Needs API key and Steam ID");
        if (loading)
            return Tr.tr("Loading Steam data…");
        if (error.length > 0)
            return error;
        if (profile?.personaName)
            return Tr.tr("Connected as %1").arg(profile.personaName);
        return Tr.tr("Ready");
    }

    readonly property string personaStateLabel: {
        const state = profile?.personaState;
        if (profile?.gameExtraInfo)
            return Tr.tr("In-game");
        if (state === 1)
            return Tr.tr("Online");
        if (state === 2)
            return Tr.tr("Busy");
        if (state === 3)
            return Tr.tr("Away");
        if (state === 4)
            return Tr.tr("Snooze");
        if (state === 5)
            return Tr.tr("Looking to trade");
        if (state === 6)
            return Tr.tr("Looking to play");
        return Tr.tr("Offline");
    }

    function setEnabled(on: bool): void {
        if (GlobalConfig.addons.steam.enabled === on)
            return;
        GlobalConfig.addons.steam.enabled = on;
    }

    function setApiKey(key: string): void {
        GlobalConfig.addons.steam.apiKey = (key || "").trim();
    }

    function setSteamId(id: string): void {
        GlobalConfig.addons.steam.steamId = (id || "").trim();
    }

    function setRefreshMinutes(mins: int): void {
        const v = Math.max(1, Math.min(180, Math.round(mins || 10)));
        if (GlobalConfig.addons.steam.refreshMinutes === v)
            return;
        GlobalConfig.addons.steam.refreshMinutes = v;
    }

    function steamLang(): string {
        const name = Tr.locale.name || "en_US";
        const [lang, region] = name.split("_");
        const map = {
            es: region && region !== "ES" ? "latam" : "spanish",
            pt: region === "BR" ? "brazilian" : "portuguese",
            zh: region === "TW" || region === "HK" ? "tchinese" : "schinese",
            fr: "french",
            de: "german",
            it: "italian",
            ru: "russian",
            ja: "japanese",
            ko: "koreana",
            pl: "polish",
            nl: "dutch",
            tr: "turkish",
            uk: "ukrainian"
        };
        return map[lang] ?? "english";
    }

    function capsuleUrl(appId: string): string {
        if (!appId)
            return "";
        const local = root.nonSteamGames.find(g => g.appId === appId);
        if (local?.capsuleUrl)
            return local.capsuleUrl;
        return `https://cdn.cloudflare.steamstatic.com/steam/apps/${appId}/capsule_184x69.jpg`;
    }

    function headerUrl(appId: string): string {
        if (!appId)
            return "";
        const local = root.nonSteamGames.find(g => g.appId === appId);
        if (local?.headerUrl)
            return local.headerUrl;
        return `https://cdn.cloudflare.steamstatic.com/steam/apps/${appId}/header.jpg`;
    }

    function loadNonSteam(): void {
        if (!root.enabled)
            return;
        const args = ["python3", root.nonSteamScript];
        if (root.resolvedSteamId)
            args.push("--steamid", root.resolvedSteamId);
        nonSteamProc.command = args;
        nonSteamProc.running = true;
    }

    function formatPlaytime(minutes: int): string {
        if (!minutes || minutes <= 0)
            return Tr.tr("No playtime");
        if (minutes < 60)
            return Tr.tr("%1 min").arg(minutes);
        const hours = Math.floor(minutes / 60);
        const rem = minutes % 60;
        if (hours < 100 && rem > 0)
            return Tr.tr("%1 h %2 min").arg(hours).arg(rem);
        return Tr.tr("%1 h").arg(hours);
    }

    function extractSteamIdOrVanity(raw: string): var {
        const s = (raw || "").trim();
        if (!s)
            return { kind: "empty" };

        const profiles = s.match(/steamcommunity\.com\/profiles\/(\d+)/i);
        if (profiles)
            return { kind: "id", value: profiles[1] };

        const vanity = s.match(/steamcommunity\.com\/id\/([^\/\?#]+)/i);
        if (vanity)
            return { kind: "vanity", value: decodeURIComponent(vanity[1]) };

        if (/^\d{17}$/.test(s))
            return { kind: "id", value: s };

        return { kind: "vanity", value: s.replace(/^\/+|\/+$/g, "") };
    }

    function apiUrl(iface: string, method: string, version: string, params: var): string {
        const q = Object.keys(params).map(k => `${encodeURIComponent(k)}=${encodeURIComponent(params[k])}`).join("&");
        return `https://api.steampowered.com/${iface}/${method}/${version}/?${q}`;
    }

    function getJson(url: string, ok: var, fail: var): void {
        Requests.get(url, text => {
            try {
                ok(JSON.parse(text));
            } catch (e) {
                if (fail)
                    fail(Tr.tr("Invalid Steam API response"));
            }
        }, err => {
            if (fail)
                fail(err || Tr.tr("Steam request failed"));
        });
    }

    function logPlaytime(games: var): void {
        const rows = games.filter(game => game.playtimeForever > 0).map(game => [game.appId, game.playtimeForever, game.lastPlayed]);
        snapshotProc.command = ["python3", root.activityScript, "snapshot", JSON.stringify(rows)];
        snapshotProc.running = true;
    }

    function applyActivity(text: string): void {
        const raw = text || "{}";
        if (raw === root.lastActivityJson) {
            root.activityNow = Date.now() / 1000;
            return;
        }
        try {
            root.activity = JSON.parse(raw);
            root.lastActivityJson = raw;
            root.activityNow = Date.now() / 1000;
        } catch (e) {
            console.warn(`Steam activity parse failed: ${e}`);
        }
    }

    function setFocusApp(appId: string, name: string): void {
        if (!appId || String(appId) === root.focusAppId)
            return;
        root.focusAppId = String(appId);
        root.focusGameName = name || "";
        root.loadFocusAchievements(root.gen);
    }

    function clearData(): void {
        root.resolvedSteamId = "";
        root.steamLevel = 0;
        root.profile = null;
        root.recentGames = [];
        root.nonSteamGames = [];
        root.hiddenAppIds = [];
        root.focusAppId = "";
        root.focusGameName = "";
        root.focusAchievements = [];
        root.focusProgress = null;
        root.focusLoading = false;
        root.focusError = "";
        root.gameCount = 0;
        root.totalPlaytimeMinutes = 0;
        root.recentPlaytimeMinutes = 0;
        root.ownedGames = [];
        root.topGamesByPlaytime = [];
        root.topGamesByRecency = [];
        root.achievementCandidates = [];
        root.friendsTotal = -1;
        root.friendsOnline = -1;
        root.friendsInGame = -1;
        root.friendsError = "";
        root.friendsPreview = [];
        root.activity = ({});
        root.lastActivityJson = "";
        root.libraryAchievements = null;
        root.libraryAchievementsLoading = false;
        root.error = "";
        root.loading = false;
    }

    function reload(): void {
        if (!root.enabled || !root.configured) {
            root.clearData();
            if (root.enabled && !root.configured)
                root.error = Tr.tr("Needs API key and Steam ID");
            return;
        }

        const g = ++root.gen;
        root.loading = true;
        root.error = "";

        const parsed = root.extractSteamIdOrVanity(root.steamIdInput);
        if (parsed.kind === "empty") {
            root.loading = false;
            root.error = Tr.tr("Needs API key and Steam ID");
            return;
        }

        if (parsed.kind === "id") {
            root.resolvedSteamId = parsed.value;
            root.fetchCore(g);
            return;
        }

        const url = root.apiUrl("ISteamUser", "ResolveVanityURL", "v1", {
            key: root.apiKey,
            vanityurl: parsed.value
        });
        root.getJson(url, json => {
            if (g !== root.gen)
                return;
            const resp = json?.response;
            if (resp?.success === 1 && resp.steamid) {
                root.resolvedSteamId = String(resp.steamid);
                root.fetchCore(g);
            } else {
                root.loading = false;
                root.error = Tr.tr("Could not resolve Steam vanity URL");
            }
        }, err => {
            if (g !== root.gen)
                return;
            root.loading = false;
            root.error = err;
        });
    }

    function fetchCore(g: int): void {
        const sid = root.resolvedSteamId;
        const key = root.apiKey;
        let pending = 5;
        let failed = false;

        function done(): void {
            pending--;
            if (pending > 0)
                return;
            if (g !== root.gen)
                return;
            if (!failed) {
                root.loadNonSteam();
                root.pickInitialFocus(g);
                root.sampleLibraryAchievements(g);
            } else {
                root.loading = false;
            }
        }

        function fail(msg: string): void {
            if (g !== root.gen)
                return;
            failed = true;
            root.error = msg;
            done();
        }

        root.getJson(root.apiUrl("ISteamUser", "GetPlayerSummaries", "v2", {
            key: key,
            steamids: sid
        }), json => {
            if (g !== root.gen)
                return;
            const player = json?.response?.players?.[0];
            if (!player) {
                fail(Tr.tr("Steam profile not found"));
                return;
            }
            root.profile = {
                steamId: String(player.steamid || sid),
                personaName: player.personaname || "",
                avatarUrl: player.avatarfull || player.avatarmedium || player.avatar || "",
                profileUrl: player.profileurl || "",
                personaState: player.personastate ?? 0,
                gameExtraInfo: player.gameextrainfo || "",
                gameId: player.gameid ? String(player.gameid) : ""
            };
            done();
        }, fail);

        root.getJson(root.apiUrl("IPlayerService", "GetSteamLevel", "v1", {
            key: key,
            steamid: sid
        }), json => {
            if (g !== root.gen)
                return;
            root.steamLevel = json?.response?.player_level ?? 0;
            done();
        }, () => {
            if (g !== root.gen)
                return;
            root.steamLevel = 0;
            done();
        });

        root.getJson(root.apiUrl("IPlayerService", "GetRecentlyPlayedGames", "v1", {
            key: key,
            steamid: sid,
            count: 8
        }), json => {
            if (g !== root.gen)
                return;
            const games = json?.response?.games || [];
            let recentMins = 0;
            root.recentGames = games.map(game => {
                recentMins += game.playtime_2weeks || 0;
                return {
                    appId: String(game.appid),
                    name: game.name || Tr.tr("Unknown game"),
                    playtimeForever: game.playtime_forever || 0,
                    playtime2Weeks: game.playtime_2weeks || 0,
                    imgIconUrl: game.img_icon_url || "",
                    capsuleUrl: root.capsuleUrl(String(game.appid))
                };
            });
            root.recentPlaytimeMinutes = recentMins;
            done();
        }, fail);

        root.getJson(root.apiUrl("IPlayerService", "GetOwnedGames", "v1", {
            key: key,
            steamid: sid,
            include_appinfo: 1,
            include_played_free_games: 1
        }), json => {
            if (g !== root.gen)
                return;
            const resp = json?.response || {};
            const games = resp.games || [];
            const ranked = games.map(game => ({
                    appId: String(game.appid),
                    name: game.name || Tr.tr("Unknown game"),
                    playtimeForever: game.playtime_forever || 0,
                    lastPlayed: game.rtime_last_played || 0,
                    hasStats: !!game.has_community_visible_stats,
                    capsuleUrl: root.capsuleUrl(String(game.appid))
                }));
            root.ownedGames = ranked;
            root.refreshOwnedDerived();
            root.logPlaytime(ranked);
            done();
        }, () => {
            if (g !== root.gen)
                return;
            root.ownedGames = [];
            root.refreshOwnedDerived();
            done();
        });

        root.fetchFriends(g, done);
    }

    function fetchFriends(g: int, done: var): void {
        root.getJson(root.apiUrl("ISteamUser", "GetFriendList", "v1", {
            key: root.apiKey,
            steamid: root.resolvedSteamId,
            relationship: "friend"
        }), json => {
            if (g !== root.gen)
                return;
            const friends = json?.friendslist?.friends || [];
            root.friendsTotal = friends.length;
            root.friendsError = "";
            if (friends.length === 0) {
                root.friendsOnline = 0;
                root.friendsInGame = 0;
                root.friendsPreview = [];
                done();
                return;
            }

            const ids = friends.map(f => String(f.steamid));
            const chunk = ids.slice(0, 100); // Steam summaries cap
            root.getJson(root.apiUrl("ISteamUser", "GetPlayerSummaries", "v2", {
                key: root.apiKey,
                steamids: chunk.join(",")
            }), sumJson => {
                if (g !== root.gen)
                    return;
                const players = sumJson?.response?.players || [];
                let online = 0;
                let inGame = 0;
                const preview = [];
                for (let i = 0; i < players.length; i++) {
                    const p = players[i];
                    const state = p.personastate ?? 0;
                    const playing = !!(p.gameextrainfo || p.gameid);
                    if (state > 0)
                        online++;
                    if (playing)
                        inGame++;
                    if (state > 0 && preview.length < 8) {
                        preview.push({
                            name: p.personaname || "",
                            avatarUrl: p.avatarmedium || p.avatar || "",
                            gameExtraInfo: p.gameextrainfo || "",
                            inGame: playing
                        });
                    }
                }
                // Scale if we only sampled first 100
                if (ids.length > chunk.length && chunk.length > 0) {
                    const scale = ids.length / chunk.length;
                    online = Math.round(online * scale);
                    inGame = Math.round(inGame * scale);
                }
                root.friendsOnline = online;
                root.friendsInGame = inGame;
                root.friendsPreview = preview;
                done();
            }, () => {
                if (g !== root.gen)
                    return;
                root.friendsOnline = -1;
                root.friendsInGame = -1;
                root.friendsPreview = [];
                root.friendsError = Tr.tr("Could not load friend status");
                done();
            });
        }, () => {
            if (g !== root.gen)
                return;
            root.friendsTotal = -1;
            root.friendsOnline = -1;
            root.friendsInGame = -1;
            root.friendsPreview = [];
            root.friendsError = Tr.tr("Friends list is private");
            done();
        });
    }

    // Steam's "average completion" only counts games with at least one unlock
    function sampleLibraryAchievements(g: int): void {
        // Candidates are sorted by playtime (see addGames) so the cap keeps
        // the most played games; the tail is unmeasured by design.
        const sample = root.achievementCandidates.slice(0, root.achievementSampleLimit);
        if (sample.length === 0) {
            root.libraryAchievements = null;
            root.libraryAchievementsLoading = false;
            return;
        }

        root.libraryAchievementsLoading = true;
        const workers = Math.min(4, sample.length);
        let idx = 0;
        let active = workers;
        let processed = 0;
        let unlocked = 0;
        let total = 0;
        let perfect = 0;
        let started = 0;
        let completionSum = 0;

        function publish(): void {
            root.libraryAchievements = {
                unlocked: unlocked,
                total: total,
                percent: started > 0 ? completionSum / started : 0,
                sampled: started,
                perfect: perfect
            };
        }

        function next(): void {
            if (g !== root.gen)
                return;
            if (idx >= sample.length) {
                if (--active === 0) {
                    root.libraryAchievementsLoading = false;
                    publish();
                }
                return;
            }
            const appId = sample[idx++];
            const cached = root.achievementsCache[appId];
            if (cached) {
                applyList(cached);
                next();
                return;
            }
            root.getJson(root.apiUrl("ISteamUserStats", "GetPlayerAchievements", "v1", {
                key: root.apiKey,
                steamid: root.resolvedSteamId,
                appid: appId
            }), json => {
                if (g !== root.gen)
                    return;
                const list = json?.playerstats?.success === false ? null : json?.playerstats?.achievements;
                if (list) {
                    root.achievementsCache[appId] = list;
                    applyList(list);
                }
                next();
            }, () => next());
        }

        function applyList(list: var): void {
            processed++;
            if (list && list.length > 0) {
                let u = 0;
                for (let i = 0; i < list.length; i++) {
                    if (list[i].achieved === 1 || list[i].achieved === true)
                        u++;
                }
                unlocked += u;
                total += list.length;
                if (u > 0) {
                    started++;
                    completionSum += u / list.length;
                }
                    if (u === list.length)
                    perfect++;
            }
            if (processed % 8 === 0)
                publish();
        }

        for (let w = 0; w < workers; w++)
            next();
    }

    function pickInitialFocus(g: int): void {
        if (g !== root.gen)
            return;

        if (root.focusAppId) {
            const still = root.pickerGames.find(game => game.appId === root.focusAppId);
            if (still) {
                root.focusGameName = still.name || root.focusGameName;
                if (!still.nonSteam) {
                    const cache = Object.assign({}, root.achievementsCache);
                    delete cache[still.appId];
                    root.achievementsCache = cache;
                }
                root.loadFocusAchievements(g);
                return;
            }
        }

        let appId = "";
        let name = "";
        if (root.profile?.gameId) {
            appId = root.profile.gameId;
            name = root.profile.gameExtraInfo || "";
        } else if (root.recentGames.length > 0) {
            appId = root.recentGames[0].appId;
            name = root.recentGames[0].name;
        }

        root.focusAppId = appId;
        root.focusGameName = name;
        if (appId)
            root.loadFocusAchievements(g);
        else {
            root.loading = false;
            root.focusAchievements = [];
            root.focusProgress = null;
        }
    }

    function loadFocusAchievements(g: int): void {
        const appId = root.focusAppId;
        if (!appId || !root.resolvedSteamId) {
            root.loading = false;
            return;
        }

        const localGame = root.nonSteamGames.find(g => g.appId === appId);
        if (localGame) {
            root.loading = false;
            root.focusLoading = false;
            root.focusError = localGame.tracked ? Tr.tr("Playtime tracked by Millennium") : Tr.tr("Non-Steam game — no Steam achievements");
            root.focusAchievements = [];
            root.focusProgress = null;
            return;
        }

        root.focusLoading = true;
        let pending = 3;
        let playerAchievements = null;
        let schemaMap = null;
        let globalMap = null;
        let privateProfile = false;

        function finish(): void {
            pending--;
            if (pending > 0)
                return;
            if (g !== root.gen || appId !== root.focusAppId)
                return;

            root.loading = false;
            root.focusLoading = false;
            if (privateProfile || !playerAchievements) {
                root.focusError = privateProfile ? Tr.tr("Steam achievements are private for this profile") : Tr.tr("This game has no achievements");
                root.focusAchievements = [];
                root.focusProgress = null;
                return;
            }

            root.focusError = "";
            root.buildAchievementViews(appId, playerAchievements, schemaMap || {}, globalMap || {});
        }

        const cachedAch = root.achievementsCache[appId];
        if (cachedAch) {
            playerAchievements = cachedAch;
            finish();
        } else {
            root.getJson(root.apiUrl("ISteamUserStats", "GetPlayerAchievements", "v1", {
                key: root.apiKey,
                steamid: root.resolvedSteamId,
                appid: appId,
                l: root.steamLang()
            }), json => {
                if (g !== root.gen)
                    return;
                if (json?.playerstats?.success === false || json?.playerstats?.error) {
                    privateProfile = /private|not public/i.test(json?.playerstats?.error || "");
                    finish();
                    return;
                }
                const list = json?.playerstats?.achievements;
                if (!list) {
                    finish();
                    return;
                }
                if (!root.focusGameName && json.playerstats.gameName)
                    root.focusGameName = json.playerstats.gameName;
                playerAchievements = list;
                root.achievementsCache[appId] = list;
                finish();
            }, () => {
                if (g !== root.gen)
                    return;
                finish();
            });
        }

        const cachedSchema = root.schemaCache[`${appId}:${root.steamLang()}`];
        if (cachedSchema) {
            schemaMap = cachedSchema;
            finish();
        } else {
            root.getJson(root.apiUrl("ISteamUserStats", "GetSchemaForGame", "v2", {
                key: root.apiKey,
                appid: appId,
                l: root.steamLang()
            }), json => {
                if (g !== root.gen)
                    return;
                const achs = json?.game?.availableGameStats?.achievements || [];
                const map = {};
                for (let i = 0; i < achs.length; i++) {
                    const a = achs[i];
                    map[a.name] = {
                        displayName: a.displayName || a.name,
                        description: a.description || "",
                        icon: a.icon || "",
                        icongray: a.icongray || ""
                    };
                }
                schemaMap = map;
                root.schemaCache[`${appId}:${root.steamLang()}`] = map;
                finish();
            }, () => {
                if (g !== root.gen)
                    return;
                schemaMap = {};
                finish();
            });
        }

        const cachedGlobal = root.globalPctCache[appId];
        if (cachedGlobal) {
            globalMap = cachedGlobal;
            finish();
        } else {
            root.getJson(root.apiUrl("ISteamUserStats", "GetGlobalAchievementPercentagesForApp", "v2", {
                gameid: appId
            }), json => {
                if (g !== root.gen)
                    return;
                const list = json?.achievementpercentages?.achievements || [];
                const map = {};
                for (let i = 0; i < list.length; i++)
                    map[list[i].name] = Number(list[i].percent) || 0;
                globalMap = map;
                root.globalPctCache[appId] = map;
                finish();
            }, () => {
                if (g !== root.gen)
                    return;
                globalMap = {};
                finish();
            });
        }
    }

    function buildAchievementViews(appId: string, list: var, schemaMap: var, globalMap: var): void {
        const gameName = root.focusGameName || (root.recentGames.find(g => g.appId === appId)?.name) || Tr.tr("Unknown game");
        const enriched = [];
        let unlocked = 0;

        for (let i = 0; i < list.length; i++) {
            const a = list[i];
            const meta = schemaMap[a.apiname] || {};
            const achieved = a.achieved === 1 || a.achieved === true;
            if (achieved)
                unlocked++;
            enriched.push({
                apiName: a.apiname,
                name: meta.displayName || a.name || a.apiname,
                description: meta.description || "",
                icon: achieved ? (meta.icon || "") : (meta.icongray || meta.icon || ""),
                unlocked: achieved,
                unlockTime: a.unlocktime || 0,
                globalPercent: globalMap[a.apiname] ?? -1,
                gameName: gameName,
                appId: appId
            });
        }

        const total = enriched.length;
        root.focusProgress = {
            unlocked: unlocked,
            total: total,
            percent: total > 0 ? unlocked / total : 0,
            gameName: gameName,
            appId: appId
        };

        const pctOf = a => a.globalPercent >= 0 ? a.globalPercent : -1;
        const unlockedList = enriched.filter(a => a.unlocked);
        unlockedList.sort((a, b) => (pctOf(a) < 0 ? 101 : pctOf(a)) - (pctOf(b) < 0 ? 101 : pctOf(b)));
        const lockedList = enriched.filter(a => !a.unlocked);
        lockedList.sort((a, b) => pctOf(b) - pctOf(a));
        root.focusAchievements = unlockedList.concat(lockedList);
    }

    function maybeReloadOnConfig(): void {
        if (root.enabled && root.configured)
            root.reload();
        else
            root.clearData();
    }

    Connections {
        target: GlobalConfig.addons.steam
        function onEnabledChanged(): void {
            root.maybeReloadOnConfig();
        }
        function onApiKeyChanged(): void {
            root.schemaCache = ({});
            root.globalPctCache = ({});
            root.achievementsCache = ({});
            root.maybeReloadOnConfig();
        }
        function onSteamIdChanged(): void {
            root.schemaCache = ({});
            root.globalPctCache = ({});
            root.achievementsCache = ({});
            root.maybeReloadOnConfig();
        }
    }

    Timer {
        interval: root.refreshMinutes * 60 * 1000
        running: root.enabled && root.configured && root.gamesTabVisible
        repeat: true
        onTriggered: root.reload()
    }

    Process {
        id: nonSteamProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text || "{}");
                    // Back-compat if script still returns a bare array
                    if (Array.isArray(data)) {
                        root.nonSteamGames = data;
                        root.hiddenAppIds = [];
                    } else {
                        root.nonSteamGames = Array.isArray(data.nonSteam) ? data.nonSteam : [];
                        root.hiddenAppIds = (data.hiddenAppIds || []).map(id => String(id));
                        root.applyHiddenFilter();
                    }
                } catch (e) {
                    console.warn(`Steam local library parse failed: ${e}`);
                    root.nonSteamGames = [];
                    root.hiddenAppIds = [];
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length)
                    console.warn(`steam-nonsteam.py: ${text.trim()}`);
            }
        }
    }

    Timer {
        // Active sessions: 45s; otherwise 2 min (python skips /proc walk if Steam is down)
        interval: Object.keys(root.activity.active ?? {}).length > 0 ? 45 * 1000 : 120 * 1000
        running: root.enabled && root.configured
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!pollProc.running)
                pollProc.running = true;
        }
    }

    Timer {
        interval: 30 * 1000
        running: root.enabled && Object.keys(root.activity.active ?? {}).length > 0
        repeat: true
        onTriggered: root.activityNow = Date.now() / 1000
    }

    Process {
        id: pollProc

        command: ["python3", root.activityScript, "poll"]
        stdout: StdioCollector {
            onStreamFinished: root.applyActivity(text)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length)
                    console.warn(`steam-activity.py: ${text.trim()}`);
            }
        }
    }

    Process {
        id: snapshotProc

        stdout: StdioCollector {
            onStreamFinished: root.applyActivity(text)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length)
                    console.warn(`steam-activity.py: ${text.trim()}`);
            }
        }
    }

    Component.onCompleted: {
        // Defer full library/API reload until Games tab asks; still start activity poll
        if (root.enabled && root.configured && !pollProc.running)
            pollProc.running = true;
    }
}
