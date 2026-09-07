pragma Singleton

import QtQuick
import qs.services

/**
 * NetworkConnection
 *
 * Centralized utility for network connection logic. Provides a single source of truth
 * for connecting to wireless networks, eliminating code duplication across
 * controlcenter components and bar popouts.
 */
QtObject {
    id: root

    function handleConnect(network, session, onPasswordNeeded): void {
        if (!network)
            return;

        root.connectToNetwork(network, session, onPasswordNeeded);
    }

    function connectToNetwork(network, session, onPasswordNeeded): void {
        if (!network)
            return;

        // Try connecting directly first (for saved profiles and open networks)
        Nmcli.connectToNetwork(network.ssid, "", result => {
            if (result && !result.success && network.isSecure) {
                // If it failed and is secure, password is required
                if (session && session.network) {
                    session.network.showPasswordDialog = true;
                    session.network.pendingNetwork = network;
                } else if (onPasswordNeeded) {
                    onPasswordNeeded(network);
                }
            }
        });
    }

    function connectWithPassword(network, password, onResult): void {
        if (!network)
            return;

        Nmcli.connectToNetwork(network.ssid, password || "", onResult);
    }
}
