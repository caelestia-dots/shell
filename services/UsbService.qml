import QtQuick
import Quickshell.Io

Item {
    id: usbService

    signal deviceConnected(var device)
    signal deviceDisconnected(var device)

    property double lastEventTime: 0
    property int debounceMs: 250
    property var pending: []
    property var currentDev: null
    property var known: ({})

// Classify device type based on udev properties
    function detectType(line) {
    const l = (line || "").toLowerCase()

// High priority: Standard peripherals
    if (l.includes("keyboard")) return "Keyboard"
    if (l.includes("mouse") || l.includes("pointer") || l.includes("touchpad")) return "Mouse"
    if (l.includes("storage") || l.includes("block") || l.includes("disk")) return "Storage"
    if (l.includes("audio") || l.includes("sound")) return "Audio"
    if (l.includes("video") || l.includes("camera")) return "Video"
    
    // Game controllers and mobile devices

    if (l.includes("nsw") || l.includes("joy-con") || l.includes("dualshock") || 
        l.includes("xbox") || l.includes("playstation") || l.includes("gamepad") || 
        l.includes("joystick") || l.includes("bda") || l.includes("controller")) return "Gamepad"
        
    if (l.includes("phone") || l.includes("mtp") || l.includes("android") || l.includes("iphone") || l.includes("midi")) return "Phone"
    
    if (l.includes("input") || l.includes("hid")) return "HID"
    return "USB"
}

// Sanitize and format device display names
function cleanDeviceName(name) {
    let n = name
    
    // Specific hardware rebranding
    if (n.includes("Sony") && n.includes("DualShock 4")) return "PS4 DualShock 4"
    if (n.includes("BDA NSW")) return "Nintendo Switch Controller"
    
    // General naming cleanup
    if (n.includes("Wireless Controller")) return n.replace("Wireless Controller", "Gamepad")
    
    return n.trim() || qsTr("USB Device")
}

// Fallback: Extract bus address if model name is unavailable
    function detectNameFromPath(path) {
        if (!path) return qsTr("USB Device")
        const m = path.match(/[0-9]+-[0-9]+(\.[0-9]+)*/i)
        return m ? m[0] : qsTr("USB Device")
    }

// Shell argument escaping for process safety
    function shEscape(str) {
        return String(str).replace(/'/g, "'\\''")
    }

// Main udev monitor process
    Process {
        id: monitor
        command: ["sh", "-c", "udevadm monitor --udev --subsystem-match=usb"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                const raw = data.trim()
                if (!raw.startsWith("UDEV")) return

                const isAdd = raw.includes(" add ")
                const isRemove = raw.includes(" remove ")
                if (!isAdd && !isRemove) return

                let m = raw.match(/(\/devices\/[^\s]+)/)
                let devPath = m ? m[1] : raw.split(" ").pop()

                if (isAdd) {
                    const now = Date.now()
                    if (now - usbService.lastEventTime < usbService.debounceMs) return
                    usbService.lastEventTime = now

                    pending.push({ path: devPath })
                    if (!nameLookup.running && currentDev === null) processNextInQueue()
                } 
               
                else if (isRemove) {
                    let found = false;

                // Exact path match

                    if (known[devPath]) {
                        usbService.deviceDisconnected(known[devPath]);
                        delete known[devPath];
                        found = true;
                    } 

                    // Fuzzy matching for complex HID device paths
                    if (!found) {
                        for (let savedPath in known) {
                            if (devPath.includes(savedPath) || savedPath.includes(devPath)) {
                                const info = known[savedPath];
                                usbService.deviceDisconnected(info);
                                delete known[savedPath];
                                found = true;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

// Sequential queue processing for device discovery
    function processNextInQueue() {
        if (pending.length > 0) {
            currentDev = pending.shift()
            nameLookup.command = ["sh", "-c", "udevadm info --query=property -p '" + shEscape(currentDev.path) + "' | grep -E 'DEVTYPE=usb_device|ID_MODEL_FROM_DATABASE=|ID_MODEL=|ID_VENDOR_FROM_DATABASE=|ID_VENDOR=' || true"]
            nameLookup.running = true
        }
    }

// Hardware metadata discovery
    Process {
        id: nameLookup
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
    const out = text.trim() 
    let props = {}
    out.split("\n").forEach(line => {
        const parts = line.split("=")
        if (parts.length === 2) props[parts[0]] = parts[1].trim()
    })

// Verify target is a physical USB device
    if (props["DEVTYPE"] !== "usb_device") {
        currentDev = null
        processNextInQueue()
        return
    }

    let vendor = props["ID_VENDOR_FROM_DATABASE"] || props["ID_VENDOR"] || ""
    let model = props["ID_MODEL_FROM_DATABASE"] || props["ID_MODEL"] || ""
    let rawName = (vendor + " " + model).trim()
    
    // Si udev no da nombre, usamos la ruta antes de limpiar
    if (rawName === "") rawName = detectNameFromPath(currentDev.path)

    const finalName = cleanDeviceName(rawName)
    const devPath = currentDev.path
    const devType = detectType(out)

    known[devPath] = { name: finalName, type: devType, path: devPath }
    usbService.deviceConnected(known[devPath])

    currentDev = null
    processNextInQueue()
}
        }
    }
}