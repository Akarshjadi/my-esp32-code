# ESP32 Board — Hardware Context

Project-agnostic board facts. Use as the hardware section of any new
project's context so you know what you're building for.

## Chip

| Field | Value |
|-------|-------|
| Model | ESP32-D0WD-V3 |
| Chip revision | v3.1 (supported up to v3.99) |
| CPU | Dual-core Xtensa LX6 @ 240 MHz |
| Wi-Fi | 802.11 b/g/n, 2.4 GHz, PHY bgn |
| Bluetooth | Yes (BT controller present) |
| Flash | 4 MB, generic SPI, QIO mode, 80 MHz clock |
| DRAM | ~156 KB @ 0x3FFB8F08 |
| IRAM | ~141 KB (14 KB D/IRAM + 111 KB @ 0x3FFE4350 + 30 KB @ 0x4009879C) |

## MAC Addresses

The ESP32 has two built-in MAC addresses (factory-programmed, offset by 1):

| Interface | MAC |
|-----------|-----|
| STA (station / uplink) | 20:50:0d:08:59:9c |
| softAP (access point / downlink) | 20:50:0d:08:59:9d |

## GPIO Map

| GPIO | Function | Notes |
|------|----------|-------|
| GPIO 0 | Boot mode (IO0) | Low at reset = bootloader mode |
| GPIO 1 | UART0 TX | Console output, 115200 8N1 |
| GPIO 2 | UART0 RX / on-board LED | Depends on board breakout |
| GPIO 3 | UART0 RX | Console input |
| GPIO 4 | SPI0 CS0 | Flash CS |
| GPIO 5 | SPI0 MISO | Flash MISO |
| GPIO 6 | SPI0 MOSI | Flash MOSI |
| GPIO 7 | SPI0 CLK | Flash CLK |
| GPIO 8 | SPI0 Q (D2) | Flash D2 (QIO/QSPI) |
| GPIO 9 | SPI0 D (D3) | Flash D3 (QIO/QSPI) |
| GPIO 10 | SPI0 HD | Flash high-speed (QSPI) |
| GPIO 11 | SPI0 CS1 | Flash CS1 (dual CS) |
| GPIO 12 | MTDO / SPI1 Q | JTAG MTDO |
| GPIO 13 | MTCK / SPI1 D | JTAG MTCK |
| GPIO 14 | SPI2 CS0 | |
| GPIO 15 | SPI2 Q | |
| GPIO 16 | SPI2 SCCLK / EN | Also the reset enable pin |
| GPIO 17 | SPI2 MISO | |
| GPIO 18 | SPI2 MOSI | |
| GPIO 19 | SPI2 D2 | |
| GPIO 20 | SPI2 D3 | |
| GPIO 21 | UART1 TX | |
| GPIO 22 | UART1 RX | |
| GPIO 23 | RESET button | On ESP32-C3: GPIO 18 |
| GPIO 25-32 | General purpose | Free for user projects |
| GPIO 33-39 | ADC / general | |

## Flash Partition Table (4 MB, larger.csv)

| # | Name | Type | SubType | Offset | Size |
|---|------|------|---------|--------|------|
| 0 | nvs | data | nvs | 0x09000 | 32 KB |
| 1 | otadata | data | ota | 0x0E000 | 8 KB |
| 2 | ota_0 | app | ota_0 | 0x10000 | 1500 KB |
| 3 | ota_1 | app | ota_1 | 0x187000 | 1500 KB |

- 1st stage bootloader: 0x0000 (3 KB)
- 2nd stage bootloader: 0x1000 (23 KB)
- App firmware: 0x10000 (OTA slot 0)

## Serial / USB

| Pin | Function |
|-----|----------|
| GPIO 1 (TX0) | Console UART output, 115200 8N1 |
| GPIO 3 (RX0) | Console UART input |

- USB-serial bridge port (macOS): `/dev/cu.usbserial-1110`
- **Known issue:** the USB-serial RX path is unreliable — long console
  commands get truncated. Use a proper USB-serial adapter or the web/OTA interface.
- Bootloader mode: hold IO0 (GPIO0) low, pulse EN (GPIO16) → "waiting for download"
- `esptool` works reliably in bootloader mode (writes verified by hash)

## Bootloader

| Field | Value |
|-------|-------|
| 1st stage | ets Jul 29 2019 12:21:46 (pre-programmed ROM) |
| 2nd stage | ESP-IDF (compiled with the firmware) |
| Flash mode | DIO @ 40 MHz (bootloader) / QIO @ 80 MHz (app) |
| OTA | Enabled (ota_0 + ota_1, otadata at 0x0E000) |

## Wi-Fi (hardware capability)

- 2.4 GHz only (no 5 GHz)
- Modes: STA, softAP, STA+softAP (concurrent)
- Security: WPA2-PSK, WPA2-Enterprise, open
- Max concurrent connections: 10 (ESP-NOW encrypt constraint)
- TX power: up to 84 (0.5 dB steps, ~20 dBm max)

## Reset / Boot Pins

| Signal | GPIO | Behavior |
|--------|------|----------|
| EN | GPIO 16 | Low = reset. Pulse to restart. |
| IO0 | GPIO 0 | Low at EN-falling-edge = bootloader mode |

## Power

| Rail | Typical |
|------|---------|
| VCC | 3.3 V (USB 5 V via onboard LDO) |
| Peak current (Wi-Fi TX) | ~300 mA |
| Idle | ~80 mA |

## JTAG / Debug

- GPIO 12 (MTDO), GPIO 13 (MTCK) — JTAG on ESP32
- OpenOCD / GDB: `toolchain-esp32` in PlatformIO
- `esp-idf` debug: `idf.py debug-server` + `openocd`

## RAM Layout

| Region | Start | Size | Purpose |
|--------|-------|------|---------|
| D/IRAM | 0x3FFAE6E0 | 6 KB | Stack / small heap |
| DRAM | 0x3FFB8F08 | 156 KB | Main heap |
| D/IRAM | 0x3FFE0440 | 14 KB | D/IRAM (dual access) |
| D/IRAM | 0x3FFE4350 | 111 KB | D/IRAM (dual access) |
| IRAM | 0x4009879C | 30 KB | IRAM (code + data) |

## NVS (Non-Volatile Storage)

- Partition: `nvs` at 0x09000, 32 KB
- Use a project-specific namespace to avoid collisions with other firmware

## New-Project Checklist

When starting a new project on this board, verify:

1. **Flash layout** — 4 MB, ota_0 at 0x10000, ota_1 at 0x187000
2. **Partition table** — `larger.csv` (or your own) must match the bootloader's expectations
3. **UART pins** — TX=GPIO1, RX=GPIO3 for console; use a proper USB-serial adapter
4. **Boot pins** — IO0=GPIO0 (bootloader), EN=GPIO16 (reset)
5. **Wi-Fi** — 2.4 GHz only, concurrent STA+AP supported
6. **RAM** — ~156 KB DRAM, ~141 KB IRAM; budget for Wi-Fi buffers (~30 KB)
7. **NVS** — use a project-specific namespace
8. **JTAG** — GPIO12/13 for OpenOCD debug
9. **Power** — 3.3 V, peak ~300 mA during Wi-Fi TX; use a USB supply for dev
10. **MAC** — STA=`...9c`, AP=`...9d` (factory, don't override unless needed)
