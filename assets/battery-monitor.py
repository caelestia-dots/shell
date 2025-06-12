#!/usr/bin/env python3

import os
import time
import subprocess

BATTERY = "/sys/class/power_supply/BAT0"

def read_file(path):
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except:
        return None

def get_status():
    charge_full = int(read_file(f"{BATTERY}/charge_full") or 1)
    charge_now = int(read_file(f"{BATTERY}/charge_now") or 0)
    percent = int((charge_now / charge_full) * 100)
    status = read_file(f"{BATTERY}/status") or "Unknown"
    plugged = status == "Charging"
    return {
        "percent": percent,
        "plugged": plugged,
        "state": status
    }

def notify(title, message, icon=None):
    try:
        args = ["/sbin/notify-send", title, message]
        if icon:
            args.extend(["-i", icon])
        subprocess.run(args, check=True)
    except:
        pass

def main():
    last_status = None
    last_levels = {
        "low": False,
        "critical": False,
        "full": False
    }

    while True:
        info = get_status()

        if last_status is None:
            last_status = info
            continue

        # Plug/unplug detection
        if info["plugged"] != last_status["plugged"]:
            if info["plugged"]:
                notify("Charger Connected", "Charging started", "battery-good-charging")
            else:
                notify("Charger Disconnected", "Running on battery", "battery-good")

        # Battery level alerts
        percent = info["percent"]

        if percent >= 100 and not last_levels["full"]:
            notify("Battery Full", "You can unplug the charger", "battery-full-charged")
            last_levels["full"] = True
        elif percent < 100:
            last_levels["full"] = False

        if percent <= 20 and not last_levels["low"]:
            notify("Battery Low", "Battery is below 20%", "battery-low")
            last_levels["low"] = True
        elif percent > 20:
            last_levels["low"] = False

        if percent <= 5 and not last_levels["critical"]:
            notify("Battery Critically Low", "Plug in the charger immediately", "battery-caution")
            last_levels["critical"] = True
        elif percent > 5:
            last_levels["critical"] = False

        if info != last_status:
            last_status = info

        time.sleep(1)

if __name__ == "__main__":
    main()
