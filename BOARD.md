# ESP32 Board — Complete Spec Sheet

Captured live from the board on 2026-11-24. All values read directly
from the running chip, not from datasheets. Use this as the hardware
context for any new project.

---

## 1. Chip Identity

| Field | Value |
|-------|-------|
| Model | ESP32-D0WD-V3 |
| Chip revision | **v3.1** (supported up to v3.99) |
| CPU | Dual-core Xtensa LX6, **240 MHz** each |
| Cores running | 2 (CPU0 main, CPU1 idle + wifi) |
| Flash size | **4 MB** (32 Mbit), generic SPI |
| Flash mode | QIO @ 80 MHz (app) / DIO @ 40 MHz (bootloader) |
| Flash chip | generic (detected by `spi_flash`) |
| Wi-Fi | 802.11 b/g/n, **2.4 GHz only**, PHY bgn |
| Bluetooth | Yes (BT controller present) |
| FreeRTOS | Yes (dual-core scheduler) |
| ESP-IDF | **5.1.2** (current firmware) |

---

## 2. MAC Addresses (factory-programmed)

| Interface | MAC |
|-----------|-----|
| STA (station / uplink) | **20:50:0d:08:59:9c** |
| softAP (access point) | **20:50:0d:08:59:9d** |

The ESP32 has two MACs (offset by 1 in B0). Do not override unless
you need a custom MAC.

---

## 3. RAM Layout (from boot log)

| Region | Start Address | Size | Purpose |
|--------|---------------|------|---------|
| DRAM | 0x3FFAE6E0 | 6 KB | Stack / small heap |
| DRAM | 0x3FFB8F08 | **156 KB** | Main heap |
| D/IRAM | 0x3FFE0440 | 14 KB | Dual-access D/IRAM |
| D/IRAM | 0x3FFE4350 | **111 KB** | Dual-access D/IRAM |
| IRAM | 0x4009879C | **30 KB** | Code + data |
| **Total usable** | | **~320 KB** | |

Budget note: Wi-Fi buffers consume ~30 KB at init.
Available for app: ~290 KB DRAM + ~100 KB IRAM.

---

## 4. Flash Partition Table (4 MB, `larger.csv`)

| # | Name | Type | SubType | Offset | Size |
|---|------|------|---------|--------|------|
| 0 | nvs | data | nvs | 0x09000 | 32 KB |
| 1 | otadata | data | ota | 0x0E000 | 8 KB |
| 2 | ota_0 | app | ota_0 | 0x10000 | 1500 KB |
| 3 | ota_1 | app | ota_1 | 0x187000 | 1500 KB |

- **1st stage bootloader** → 0x0000 (3 KB, pre-programmed ROM)
- **2nd stage bootloader** → 0x1000 (23 KB, ESP-IDF compiled)
- **App firmware** → 0x10000 (OTA slot 0)
- **OTA** → Enabled (ota_0 + ota_1, otadata at 0x0E000)

---

## 5. GPIO Map

### Flash-locked pins (do NOT use for I/O)

| GPIO | Locked Function |
|------|-----------------|
| GPIO 4 | SPI0 CS0 |
| GPIO 5 | SPI0 MISO |
| GPIO 6 | SPI0 MOSI |
| GPIO 7 | SPI0 CLK |
| GPIO 8 | SPI0 Q (D2) |
| GPIO 9 | SPI0 D (D3) |
| GPIO 10 | SPI0 HD |
| GPIO 11 | SPI0 CS1 |

### UART / Console

| GPIO | Function |
|------|----------|
| GPIO 1 | UART0 TX (console output) |
| GPIO 3 | UART0 RX (console input) |
| GPIO 21 | UART1 TX |
| GPIO 22 | UART1 RX |

### JTAG / Debug

| GPIO | Function |
|------|----------|
| GPIO 12 | MTDO (JTAG) |
| GPIO 13 | MTCK (JTAG) |

### Boot / Reset

| GPIO | Function |
|------|----------|
| GPIO 0 | IO0 — Low at reset = bootloader mode |
| GPIO 16 | EN — Low = chip reset |

### General purpose (free for user projects)

| GPIO | Notes |
|------|-------|
| GPIO 2 | On-board LED (NAT router firmware uses this for status blink) |
| GPIO 14 | SPI2 CS0 |
| GPIO 15 | SPI2 Q |
| GPIO 17 | SPI2 MISO |
| GPIO 18 | SPI2 MOSI |
| GPIO 19 | SPI2 D2 |
| GPIO 20 | SPI2 D3 |
| GPIO 23 | RESET button (on this board) |
| GPIO 25-32 | Free general purpose |
| GPIO 33-39 | ADC channels / general purpose |

---

## 6. Wi-Fi Hardware Capability

- **Band:** 2.4 GHz only (no 5 GHz)
- **Modes:** STA, softAP, STA+softAP (concurrent)
- **Security:** WPA2-PSK, WPA2-Enterprise (EAP), open
- **Max concurrent connections:** 10 (ESP-NOW encrypt constraint)
- **TX power:** 0–84 (0.5 dB steps), current firmware sets **84** (~20 dBm)
- **Beacon:** max length 752 bytes
- **Power save:** type 0 (none), coexist 0
- **RX buffers:** 64 dynamic + 10 static (1600 B each)
- **TX buffers:** 32 dynamic
- **TCP/IP mbox:** 32

---

## 7. Serial / USB

| Item | Value |
|------|-------|
| Console UART | UART0, 115200 8N1 |
| TX pin | GPIO 1 |
| RX pin | GPIO 3 |
| USB-serial port (macOS) | `/dev/cu.usbserial-1110` |
| Console mode | **Dumb** (escape-sequence probe failed on this cable) |
| Bootloader entry | Hold IO0 (GPIO0) low, pulse EN (GPIO16) |
| esptool | Works reliably in bootloader mode (hash-verified writes) |

**Known issue:** The current USB-serial bridge is unreliable for sending
console commands — long strings get truncated (only 1–2 chars arrive).
Use a proper USB-serial adapter (CP2102/CH340) or the web/OTA interface.

---

## 8. Power

| Rail | Value |
|------|-------|
| VCC | 3.3 V (USB 5 V via onboard LDO) |
| Peak current (Wi-Fi TX) | ~300 mA |
| Idle current | ~80 mA |

Use a 5 V/1 A USB supply for development (Wi-Fi TX bursts).

---

## 9. JTAG / Debug

- GPIO 12 (MTDO), GPIO 13 (MTCK)
- OpenOCD + GDB via PlatformIO `toolchain-esp32`
- `idf.py debug-server` + `openocd` for in-circuit debug

---

## 10. NVS (Non-Volatile Storage)

- Partition: `nvs` at 0x09000, 32 KB
- Namespace used by NAT router firmware: `esp32_nat`
- For new projects: use your own namespace to avoid collisions

---

## 11. Boot Log (reference)

```
ets Jul 29 2019 12:21:46
rst:0x1 (POWERON_RESET), boot:0x13 (SPI_FAST_FLASH_BOOT)
mode:DIO, clock div:2
load:0x3fff0030,len:6056          <- 1st stage bootloader
load:0x40078000,len:16096         <- 2nd stage bootloader
I (27) boot: ESP-IDF qa-test-v4.3.3-20220423 2nd stage bootloader
I (38) boot.esp32: SPI Speed      : 40MHz
I (43) boot.esp32: SPI Mode       : DIO
I (48) boot.esp32: SPI Flash Size : 4MB
I (31) boot_comm: chip revision: 3
I (503) cpu_start: cpu freq: 240000000 Hz
I (531) cpu_start: ESP-IDF: 5.1.2
I (546) cpu_start: Chip rev: v3.1
I (590) spi_flash: detected chip: generic
I (594) spi_flash: flash io: qio
I (683) wifi:wifi driver task: 3ffc3630, prio:23, stack:6656, core=0
I (693) wifi:wifi firmware version: 91b9630
I (2853) wifi:mode : sta (20:50:0d:08:59:9c) + softAP (20:50:0d:08:59:9d)
I (2933) esp_netif_lwip: DHCP server started on interface WIFI_AP_DEF with IP: 192.168.4.1
I (3013) HTTPServer: Starting server on port: '8080'
```

---

## 12. New-Project Checklist

Before starting a new project on this board, verify:

- [ ] Flash layout: 4 MB, ota_0 @ 0x10000, ota_1 @ 0x187000
- [ ] Partition table matches bootloader expectations (`larger.csv` or custom)
- [ ] UART: TX=GPIO1, RX=GPIO3; use a proper USB-serial adapter
- [ ] Boot: IO0=GPIO0 (bootloader), EN=GPIO16 (reset)
- [ ] Wi-Fi: 2.4 GHz only; concurrent STA+AP supported
- [ ] RAM: ~156 KB DRAM + ~141 KB IRAM; budget ~30 KB for Wi-Fi
- [ ] NVS: use a project-specific namespace
- [ ] JTAG: GPIO12/13 for OpenOCD
- [ ] Power: 3.3 V, peak ~300 mA; use 5 V/1 A USB supply
- [ ] MAC: STA=`...9c`, AP=`...9d` (factory; don't override unless needed)
- [ ] Flash-locked pins (GPIO 4–11) are NOT available for I/O
- [ ] On-board LED is on GPIO2 (if used by firmware, avoid conflicting)
