# ESP32 Board — Complete In/Out Reference

Live-captured from the flashed board on 2026-11-24.

## Chip

| Field | Value |
|-------|-------|
| Model | ESP32-D0WD-V3 |
| Chip revision | v3.1 (supported up to v3.99) |
| Dual-core Xtensa LX6 | 240 MHz (both cores running) |
| Wi-Fi | 802.11 b/g/n (2.4 GHz, PHY bgn) |
| Bluetooth | Yes (BT controller present) |
| Flash | 4 MB, generic SPI, QIO mode, 80 MHz |
| RAM | ~320 KB DRAM + ~30 KB IRAM |

## MAC Addresses

| Interface | MAC |
|-----------|-----|
| STA (uplink) | 20:50:0d:08:59:9c |
| AP (downlink / softAP) | 20:50:0d:08:59:9d |

Note: the ESP32 uses two MAC addresses (B0 + offset). STA is `...9c`, softAP is `...9d`.

## Flash Partition Layout (4 MB)

Written by `partitions.bin` (larger.csv):

| # | Name | Type | SubType | Offset | Size |
|---|------|------|---------|--------|------|
| 0 | nvs | data | nvs | 0x09000 | 0x5000 (32 KB) |
| 1 | otadata | data | ota | 0x0E000 | 0x2000 (8 KB) |
| 2 | ota_0 | app | ota_0 | 0x10000 | 1500 KB |
| 3 | ota_1 | app | ota_1 | 0x187000 | 1500 KB |

Bootloader:
- 1st stage → 0x0000 (3 KB stub)
- 2nd stage → 0x1000 (23 KB, ESP-IDF 5.1.2)
- App firmware → 0x10000 (1.37 MB, project `esp32_nat_router_extended`)

## Bootloader / Firmware

| Field | Value |
|-------|-------|
| ESP-IDF version | 5.1.2 |
| Project name | esp32_nat_router_extended |
| App version | DEV-VERSION |
| Compile time | Nov 24 2026 21:13:33 |
| ELF SHA256 | 0135a65eb80c6e60… |
| WiFi firmware | 91b9630 |
| WiFi certification | v7.0 |

## UART / Serial Console

| Pin | Function |
|-----|----------|
| GPIO 1 (TX0) | Console output (115200 8N1) |
| GPIO 3 (RX0) | Console input |

- Baud: 115200, 8N1
- Terminal in **dumb mode** (escape-sequence probe failed on the USB-serial cable)
- Prompt: `esp32nre> `
- Commands available: `set_sta`, `set_ap`, `set_ap_ip`, `set_sta_static`, `set_sta_ent`, `show`, `portmap`, `lab_allow`, `help`
- **Known issue:** the USB-serial bridge (port `/dev/cu.usbserial-1110`) is unreliable for sending console commands — only 1-2 characters of a long command arrive. Use the **web interface** instead.

### USB-Serial Bridge

- Device: `/dev/cu.usbserial-1110` (was `2110` on earlier sessions)
- Bootloader mode: hold **EN** low, **IO0** low, pulse **EN** → "waiting for download"
- `esptool` works reliably in bootloader mode (writes verified by hash)

## Network Configuration (current, live)

### Uplink (STA)

| Field | Value |
|-------|-------|
| SSID | `Airtel_My Name is patric jane` |
| Security | WPA2-PSK |
| Channel | 4 (2.4 GHz) |
| RSSI at boot | **-85 dBm** (weak — move antenna) |
| DHCP | Client (no static IP configured) |
| Status | Associating / running, no IP yet in last capture |

### Downlink (softAP)

| Field | Value |
|-------|-------|
| SSID | `toddler` (default) |
| Password | `havemebaby` (default, 8 chars) |
| BSSID | 20:50:0d:08:59:9d |
| IP | 192.168.4.1 |
| Subnet | 192.168.4.0/24 |
| DHCP server | Enabled (WIFI_AP_DEF) |
| DNS server | Enabled, port 53 |

### NAT

- **Enabled** (IP_NAPT on AP subnet → uplink)
- Web server on port **8080**
- Console on UART0

## GPIO Usage

| GPIO | Function |
|------|----------|
| GPIO 2 | On-board LED (status blink) |
| GPIO 1 | UART TX (console out) |
| GPIO 3 | UART RX (console in) |
| GPIO 23 | RESET button (ESP32) / GPIO 18 on ESP32-C3 |
| GPIO 0 | Boot mode (low at reset = bootloader) |
| GPIO 16 | EN (reset) |

## Console Commands (full list)

| Command | Description |
|---------|-------------|
| `help` | List all commands |
| `set_sta <ssid> <pass>` | Set uplink WiFi credentials (NVS) |
| `set_ap <ssid> <pass>` | Set downlink AP credentials (NVS) |
| `set_ap_ip <ip>` | Set AP IP address |
| `set_sta_static <ip> <mask> <gw>` | Static uplink IP |
| `set_sta_ent <ssid> <id> <user> <pass>` | WPA2 Enterprise uplink |
| `show` | Show current config |
| `portmap` | Show port-mapping table |
| `lab_allow add|remove|list|clear` | Manage BSSID allow-list for active Wi-Fi commands |

## Web Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| GET | `http://192.168.4.1:8080/` | Config page |
| POST | `http://192.168.4.1:8080/apply` | Apply config (params: `func=config`, `ssid`, `password`, `ap_ssid`, `ap_password`, `ap_ip`, …) → auto-restart in 1 s |
| GET | `http://192.168.4.1:8080/api` | JSON: `{"clients": N, "strength": -85, "text": "danger"}` |
| GET | `http://192.168.4.1:8080/scan` | WiFi scan results |
| GET | `http://192.168.4.1:8080/reset` | Factory reset |
| POST | `http://192.168.4.1:8080/lock` | Lock web config |
| POST | `http://192.168.4.1:8080/unlock` | Unlock web config |

## RSSI / Signal Strength

The firmware exposes uplink RSSI via:
- `GET /api` → `"strength"` field (integer dBm, 0 = not connected)
- Config page → "(signal strength: -85 db)" text

Use `repeater.sh --graph-only` to poll this into a live graph with a
**-70 dB antenna-placement threshold** line.

## Boot Log (excerpt)

```
I (503) cpu_start: cpu freq: 240000000 Hz
I (531) cpu_start: ESP-IDF: 5.1.2
I (546) cpu_start: Chip rev: v3.1
I (590) spi_flash: detected chip: generic
I (2853) wifi:mode : sta (20:50:0d:08:59:9c) + softAP (20:50:0d:08:59:9d)
I (2933) esp_netif_lwip: DHCP server started on interface WIFI_AP_DEF with IP: 192.168.4.1
I (2933) ESP32NRE: connect to ap SSID: Airtel_My Name is patric jane
I (2963) ESP32NRE: NAT is enabled
I (3013) HTTPServer: Starting server on port: '8080'
I (3213) wifi:security: WPA2-PSK, phy: bgn, rssi: -85
```

## Known Issues

1. **Weak uplink signal (-85 dBm)** — move the antenna / ESP32 closer to the
   router. The -70 dB threshold in `graph.html` is your target.
2. **STA disconnects occasionally** (reason codes 2, 15, 201, 205 seen in
   logs) — firmware auto-reconnects, but at -85 dBm the link is marginal.
3. **Watchdog resets** — `task_wdt` fires on CPU0 during console interaction
   when the serial link is unreliable. Not a firmware bug, a serial-link issue.
4. **USB-serial RX unreliable** — use the web interface for all configuration.
