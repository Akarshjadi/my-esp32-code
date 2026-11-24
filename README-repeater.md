# ESP32 One-Click WiFi Repeater

Turn your flashed ESP32 NAT Router (Akarshjadi/my-esp32-code firmware) into a
WiFi repeater with a single command, and track the uplink signal strength as a
live graph so you can place the antenna.

## How it works

No reflashing. The script drives the web interface the firmware already ships:

| Step | Endpoint | Effect |
|------|----------|--------|
| 1 | `POST http://192.168.4.1:8080/apply` | Stores uplink STA + downlink AP credentials, firmware restarts in 1 s into repeater mode |
| 2 | `GET http://192.168.4.1:8080/api` | Returns `{"clients": N, "strength": -76}` — polled every 3 s |

RSSI samples land in `signal.csv` and are rendered into `graph.html`
(auto-refreshing, dark SVG line chart with a dashed -70 dB threshold line and
green/yellow/red color coding).

## Prerequisites

1. ESP32 flashed with the `my-esp32-code` firmware (booted, AP up)
2. Mac connected to the ESP32's setup AP: **SSID `toddler`**, **password `havemebaby`**
3. `python3` and `curl` (both preinstalled on macOS)

## One-click usage

```
./repeater.sh "<uplink_SSID>" "<uplink_PASS>" "<repeater_SSID>" "<repeater_PASS>"
```

Example:

```
./repeater.sh "HomeWiFi" "mypass" "MyRepeater" "repass123"
```

Then:

```
open graph.html
```

Walk around with the ESP32 and watch the graph fill in — place the antenna
where the signal holds above **-70 dB**.

### Repeat runs

Config is saved to `.repeater.conf` after the first run:

```
./repeater.sh            # reuse saved config, apply + graph
./repeater.sh --graph-only   # skip apply, just poll one sample into graph.html
```

## Files created

| File | Purpose |
|------|---------|
| `.repeater.conf` | Saved WiFi credentials (reused on next bare run) |
| `signal.csv` | Time-stamped RSSI samples (last 200 kept) |
| `graph.html` | Self-contained live graph (open in any browser) |

## Signal legend

| RSSI | Meaning | Color |
|------|---------|-------|
| ≥ -50 dB | Strong | green |
| -50 … -70 dB | OK | yellow |
| < -70 dB | Weak — move antenna | red |

## Troubleshooting

- **`cannot reach 192.168.4.1`** — Mac isn't on the `toddler` setup AP, or the
  ESP32 is already repeater-mode with a different AP IP. Check the AP IP with
  `./repeater.sh --graph-only` after fixing connectivity.
- **`strength: 0` / red graph** — repeater hasn't associated with the uplink
  yet (wrong SSID/password, or out of range). Fix the uplink credentials.
- **Graph not updating in browser** — the shell loop must still be running
  (don't Ctrl-C the foreground session while watching the graph, or use a
  second terminal for the live loop).
- **Changed your setup AP name?** — override with `AP_IP=... ./repeater.sh`.
