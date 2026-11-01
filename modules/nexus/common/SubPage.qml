import QtQuick

// Positions of the sub-pages inside each StackPage of PageCompRegistry (0 is the main page).
// Pass these to NexusState.openSubPage() instead of bare numbers, and keep them in the same order
// as PageCompRegistry when adding or moving pages.
QtObject {
    enum Index {
        // Wallpaper & style
        WallpaperSelect = 1,
        WallpaperCategory = 2,
        ColourSelect = 3,
        // Network
        EthernetDetail = 1,
        AddNetwork = 2,
        NetworkDetail = 3,
        AddVpn = 4,
        AllNetworks = 5,
        SavedNetworks = 6,
        // Bluetooth
        BtDeviceInfo = 1,
        BluetoothPairing = 2,
        // Audio
        AppVolumes = 1,
        // Panels
        DashboardPanel = 1,
        TaskbarPanel = 2,
        LauncherPanel = 3,
        SidebarPanel = 4,
        UtilitiesPanel = 5,
        BarWorkspaces = 6,
        BarActiveWindow = 7,
        BarTray = 8,
        BarStatusIcons = 9,
        BarClock = 10,
        // Apps
        AllApps = 1,
        AppInfo = 2,
        // Services
        Notifications = 1
    }
}
