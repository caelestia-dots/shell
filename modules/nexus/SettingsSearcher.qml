pragma Singleton

import qs.utils
import qs.modules.nexus

// Fuzzy searcher over the settings index. Reuses the shell's Searcher util (the
// same engine the launcher uses) so behaviour stays consistent. Title matches
// weigh heaviest, then keywords, then the description.
Searcher {
    list: SettingsIndex.entries
    useFuzzy: true
    keys: ["title", "keywords", "description"]
    weights: [0.6, 0.3, 0.1]
}
