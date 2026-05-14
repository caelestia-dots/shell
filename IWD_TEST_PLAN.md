# iwd Backend Test Plan (Caelestia Shell)

## 0) Safety / rollback
Keep this terminal open before testing UI network actions:

```bash
iwctl station wlan0 connect "<YOUR_SSID>"
```

If needed:

```bash
sudo systemctl restart iwd systemd-networkd
```

---

## 1) Baseline snapshot (before tests)

```bash
iwctl device list
iwctl station wlan0 show
iwctl known-networks list
networkctl --no-pager status wlan0 | head -n 40
ip -brief addr show wlan0
```

---

## 2) Wi‑Fi toggle OFF
Action: turn Wi‑Fi off from shell UI (bar + control center if available).

Expected:
- network list empty/disabled
- rescan disabled
- status icon shows disconnected
- no active SSID shown

Verify:

```bash
iwctl station wlan0 show
ip -brief link show wlan0
networkctl --no-pager status wlan0 | rg "State|Wi-Fi access point|Address"
```

---

## 3) Wi‑Fi toggle ON
Action: turn Wi‑Fi on from UI.

Expected:
- networks repopulate shortly
- rescan enabled
- known network can reconnect

Verify:

```bash
iwctl station wlan0 get-networks rssi-dbms
iwctl station wlan0 show
```

---

## 4) Rescan
Action: press rescan in UI.

Expected:
- scan indicator animates
- list refreshes
- no UI lockup/errors

---

## 5) Connect to known secured network
Action: click known SSID.

Expected:
- connects without password prompt (if saved)
- active SSID + signal shown
- connection details populate (IP/gateway/DNS)

Verify:

```bash
iwctl station wlan0 show
networkctl --no-pager status wlan0 | rg "Address|Gateway|DNS|Wi-Fi access point"
```

---

## 6) Forget + reconnect
Action: forget network in UI, then reconnect.

Expected:
- password prompt appears
- correct password connects
- wrong password fails visibly and remains disconnected

---

## 7) Ethernet sanity
Expected:
- ethernet list still appears
- connect/disconnect action works for wired interfaces
- details populate when connected

Verify:

```bash
networkctl --no-legend --no-pager list
```

---

## 8) Report format
For each case: `PASS/FAIL` + short note.

If FAIL include:
- screen (bar popout / control center)
- clicked action
- expected vs actual
- relevant terminal output snippet
