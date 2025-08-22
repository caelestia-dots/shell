pragma Singleton

import qs.config
import qs.utils
import Quickshell

Searcher {
    id: root

    list: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    keys: ["name", "comment", "genericName", "categories", "keywords"]
    weights: [
    	Config.launcher.appQueryWeights.name,
    	Config.launcher.appQueryWeights.comment,
    	Config.launcher.appQueryWeights.genericName,
    	Config.launcher.appQueryWeights.categories,
    	Config.launcher.appQueryWeights.keywords
    ]

    useFuzzy: Config.launcher.useFuzzy.apps

    function launch(entry: DesktopEntry): void {
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["app2unit", "--", ...Config.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            Quickshell.execDetached({
                command: ["app2unit", "--", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
    }
}
