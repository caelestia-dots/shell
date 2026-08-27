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

        // If secure and not saved yet, show password dialog
        if (network.isSecure && !network.known) {
            if (session && session.network) {
                session.network.showPasswordDialog = true;
                session.network.pendingNetwork = network;
            } else if (onPasswordNeeded) {
                onPasswordNeeded(network);
            }
            return;
        }

        // Otherwise connect directly (open or already saved)
        Nmcli.connectToNetwork(network.ssid);
    }

    function connectWithPassword(network, password, onResult): void {
        if (!network)
            return;

        Nmcli.connectToNetwork(network.ssid, password || "");
    }
}
