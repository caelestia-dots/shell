pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services

Singleton {
    id: root

    readonly property bool enabled: GlobalConfig.addons.steam.enabled
    readonly property string apiKey: GlobalConfig.addons.steam.apiKey
    readonly property string steamIdInput: GlobalConfig.addons.steam.steamId
    readonly property bool configured: apiKey.length > 0 && steamIdInput.length > 0

    property bool loading: false
    property string error: ""
    property string resolvedSteamId: ""
    property int steamLevel: 0
    property var profile: null
    property list<var> recentGames: []
    property string focusAppId: ""
    property string focusGameName: ""
    property list<var> recentAchievements: []
    property list<var> rareAchievements: []
    property var focusProgress: null
    readonly property var focusGame: recentGames.find(g => g.appId === focusAppId) ?? topGamesByPlaytime.find(g => g.appId === focusAppId) ?? null
    readonly property bool focusPlayingNow: !!profile?.gameId && profile.gameId === focusAppId
    property bool focusLoading: false
    property string focusError: ""
    property real libraryAvgProgress: -1

    // Generic library / social stats (header)
    property int gameCount: 0
    property int totalPlaytimeMinutes: 0
    property int recentPlaytimeMinutes: 0
    property list<var> topGamesByPlaytime: []
    property list<string> achievementCandidates: [] // played games with community stats, by playtime
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
        return `https://cdn.cloudflare.steamstatic.com/steam/apps/${appId}/capsule_184x69.jpg`;
    }

    function headerUrl(appId: string): string {
        if (!appId)
            return "";
        return `https://cdn.cloudflare.steamstatic.com/steam/apps/${appId}/header.jpg`;
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

    function formatHoursCompact(minutes: int): string {
        if (!minutes || minutes <= 0)
            return "0";
        const hours = Math.round(minutes / 60);
        if (hours >= 10000)
            return `${(hours / 1000).toFixed(1)}k`;
        if (hours >= 1000)
            return `${Math.round(hours / 100) / 10}k`;
        return String(hours);
    }

    function formatUnlockAge(unlockTime: int): string {
        if (!unlockTime)
            return "";
        const secs = Math.max(0, Math.floor(Date.now() / 1000) - unlockTime);
        if (secs < 60)
            return Tr.tr("Just now");
        if (secs < 3600)
            return Tr.tr("%1 min ago").arg(Math.floor(secs / 60));
        if (secs < 86400)
            return Tr.tr("%1 h ago").arg(Math.floor(secs / 3600));
        const days = Math.floor(secs / 86400);
        if (days < 30)
            return Tr.tr("%1 d ago").arg(days);
        return Tr.formatDateTime(new Date(unlockTime * 1000), "MMM d");
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
        root.focusAppId = "";
        root.focusGameName = "";
        root.recentAchievements = [];
        root.rareAchievements = [];
        root.focusProgress = null;
        root.focusLoading = false;
        root.focusError = "";
        root.libraryAvgProgress = -1;
        root.gameCount = 0;
        root.totalPlaytimeMinutes = 0;
        root.recentPlaytimeMinutes = 0;
        root.topGamesByPlaytime = [];
        root.achievementCandidates = [];
        root.friendsTotal = -1;
        root.friendsOnline = -1;
        root.friendsInGame = -1;
        root.friendsError = "";
        root.friendsPreview = [];
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
            root.gameCount = resp.game_count || games.length || 0;
            let total = 0;
            const ranked = games.map(game => {
                const mins = game.playtime_forever || 0;
                total += mins;
                return {
                    appId: String(game.appid),
                    name: game.name || Tr.tr("Unknown game"),
                    playtimeForever: mins,
                    lastPlayed: game.rtime_last_played || 0,
                    hasStats: !!game.has_community_visible_stats,
                    capsuleUrl: root.capsuleUrl(String(game.appid))
                };
            });
            ranked.sort((a, b) => b.playtimeForever - a.playtimeForever);
            root.totalPlaytimeMinutes = total;
            root.topGamesByPlaytime = ranked.slice(0, 5);
            root.achievementCandidates = ranked.filter(r => r.hasStats && r.playtimeForever > 0).map(r => r.appId);
            done();
        }, () => {
            if (g !== root.gen)
                return;
            root.gameCount = 0;
            root.totalPlaytimeMinutes = 0;
            root.topGamesByPlaytime = [];
            root.achievementCandidates = [];
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
        const sample = root.achievementCandidates.slice();
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
                    root.recomputeLibraryAvg();
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

    function recomputeLibraryAvg(): void {
        if (root.libraryAchievements && root.libraryAchievements.total > 0)
            root.libraryAvgProgress = root.libraryAchievements.percent;
    }

    function pickInitialFocus(g: int): void {
        if (g !== root.gen)
            return;

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
            root.recentAchievements = [];
            root.rareAchievements = [];
            root.focusProgress = null;
        }
    }

    function loadFocusAchievements(g: int): void {
        const appId = root.focusAppId;
        if (!appId || !root.resolvedSteamId) {
            root.loading = false;
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
                root.recentAchievements = [];
                root.rareAchievements = [];
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

        const unlockedList = enriched.filter(a => a.unlocked && a.unlockTime > 0);
        unlockedList.sort((a, b) => b.unlockTime - a.unlockTime);
        root.recentAchievements = unlockedList.slice(0, 6);

        const rareSource = unlockedList.length > 0 ? unlockedList : enriched.filter(a => a.unlocked);
        const withPct = rareSource.filter(a => a.globalPercent >= 0);
        withPct.sort((a, b) => a.globalPercent - b.globalPercent);
        root.rareAchievements = withPct.slice(0, 5);

        // Soft library average: average completion of recent games that we already cached
        let sum = root.focusProgress.percent;
        let count = 1;
        for (let i = 0; i < root.recentGames.length; i++) {
            const id = root.recentGames[i].appId;
            if (id === appId)
                continue;
            const cached = root.achievementsCache[id];
            if (!cached)
                continue;
            let u = 0;
            for (let j = 0; j < cached.length; j++) {
                if (cached[j].achieved === 1 || cached[j].achieved === true)
                    u++;
            }
            if (cached.length > 0) {
                sum += u / cached.length;
                count++;
            }
        }
        root.libraryAvgProgress = count > 0 ? sum / count : -1;
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
        interval: 20 * 60 * 1000
        running: root.enabled && root.configured
        repeat: true
        onTriggered: root.reload()
    }

    Component.onCompleted: {
        if (root.enabled && root.configured)
            root.reload();
    }
}
