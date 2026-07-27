pragma Singleton

import Caelestia.Plugins

PluginsBase {
    function entryPoints(type: int): list<pluginEntryPoint> {
        loadedPlugins; // For reactivity
        return __entryPoints(type);
    }
}
