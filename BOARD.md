# ESP32 Board — Complete Spec Sheet

Everything you need for any new project on this board: chip-level
datasheet specs, full pin definitions, peripherals, memory map, power
consumption, RF performance, and the live-captured state of YOUR board.

---

## 1. Chip Identity

| Field | Value |
|-------|-------|
| Model | ESP32-D0WD-V3 |
| Chip revision | **v3.1** (v3.0/v3.1 supported; max v3.99) |
| Process | TSMC 40 nm |
| Package | QFN-48, 5 × 5 mm |
| CPU | 2 × Xtensa LX6 @ 80–240 MHz |
| CoreMark | 1079.96 (dual-core @ 240 MHz, 4.50 CoreMark/MHz) |
| ROM | 448 KB (boot + core functions) |
| On-chip SRAM | 520 KB |
| RTC SRAM | 16 KB (8 KB FAST + 8 KB SLOW) |
| eFuse | 1 Kbit (256 system + 768 user) |
| Flash | **4 MB** external SPI (this board), QIO @ 80 MHz |
| Wi-Fi | 802.11 b/g/n, 2.4 GHz |
| Bluetooth | BT 4.2 BR/EDR + BLE dual mode |
| FreeRTOS | Yes, dual-core scheduler |
| ESP-IDF (current) | 5.1.2 |

---

## 2. MAC Addresses (factory-programmed, live-captured)

| Interface | MAC |
|-----------|-----|
| STA (station / uplink) | **20:50:0d:08:59:9c** |
| softAP (access point) | **20:50:0d:08:59:9d** |

Do not override unless you need a custom MAC.

---

## 3. RAM Layout

### Datasheet (full chip)

| Region | Size | Notes |
|--------|------|-------|
| D/IRAM | 32 KB | Dual-access (both data + instructions) |
| DRAM | 320 KB | 232 KB at 400–80 MHz, 296 KB at 160–240 MHz |
| RTC FAST SRAM | 8 KB | Wakes in Deep-Sleep |
| RTC SLOW SRAM | 8 KB | Accessible by ULP coprocessor |
| **Total SRAM** | **520 KB** | |

### Live-captured (this board, from boot log)

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

## 4. Flash / Memory Map

### Partition Table (4 MB, `larger.csv` — this board)

| # | Name | Type | SubType | Offset | Size |
|---|------|------|---------|--------|------|
| 0 | nvs | data | nvs | 0x09000 | 32 KB |
| 1 | otadata | data | ota | 0x0E000 | 8 KB |
| 2 | ota_0 | app | ota_0 | 0x10000 | 1500 KB |
| 3 | ota_1 | app | ota_1 | 0x187000 | 1500 KB |

- 1st stage bootloader → 0x0000 (3 KB, pre-programmed ROM)
- 2nd stage bootloader → 0x1000 (23 KB, ESP-IDF compiled)
- App firmware → 0x10000 (OTA slot 0)
- OTA → Enabled (ota_0 + ota_1, otadata at 0x0E000)

### Datasheet Memory Map

| Address Range | Region |
|---------------|--------|
| 0x0000_0000 – 0x0010_0000 | SPI Flash mapped |
| 0x3FF0_0000 – 0x3FFF_FFFF | D/IRAM (32 KB) |
| 0x3FFB_8000 – 0x3FFF_FFFF | DRAM |
| 0x4000_0000 – 0x4004_0000 | RTC IRAM |
| 0x4007_8000 – 0x400B_FFFF | IRAM |
| 0x5000_0000 – 0x5FFF_FFFF | External Flash / PSRAM |

---

## 5. GPIO Map (34 total, 6 input-only, 5 strapping)

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

### Input-only pins

| GPIO | Note |
|------|------|
| GPIO 34 | ADC2_CH6 |
| GPIO 35 | ADC2_CH7 |
| GPIO 36 | VBAT sense (no GPIO) |
| GPIO 39 | ADC2_CH11 |
| GPIO 41 | — |
| GPIO 46 | — |

### Strapping pins (read at reset, affect boot mode)

| GPIO | Function |
|------|----------|
| GPIO 0 | SPI0_CS0 / boot mode (low = bootloader) |
| GPIO 2 | SPI0_MISO / LED on some boards |
| GPIO 5 | SPI0_MISO |
| GPIO 6 | SPI0_MOSI |
| GPIO 7 | SPI0_CLK |

### UART

| GPIO | Function |
|------|----------|
| GPIO 1 | UART0 TX (console output, 115200 8N1) |
| GPIO 3 | UART0 RX (console input) |
| GPIO 10 | UART0 CTS |
| GPIO 11 | UART0 RTS |
| GPIO 17 | UART1 TX |
| GPIO 16 | UART1 RX |
| GPIO 9 | UART2 TX |
| GPIO 8 | UART2 RX |

### JTAG / Debug

| GPIO | Function |
|------|----------|
| GPIO 12 | MTDO |
| GPIO 13 | MTCK |
| GPIO 15 | MTDI |
| GPIO 14 | MTSR |

### I2C / I2S / SPI / SDIO / CAN / PWM

| Peripheral | Default GPIOs | Notes |
|------------|---------------|-------|
| I2C | 21 (SCL), 22 (SDA) | 2 controllers, up to 5 MHz |
| I2S | 14, 15, 16, 17, 18, 25, 26, 27 | 2 interfaces, 8/16/32/48/64-bit |
| SPI | 5–11 (SPI0), 12–23 (SPI2) | 4 interfaces |
| SDIO Host | 14–23 | SD/eMMC/SDIO |
| TWAI (CAN) | 34, 35 | ISO 11898-1, CAN 2.0 |
| LED PWM | 25, 26, 27, 32 | 16 channels |
| Motor PWM | 25–32 | |
| RMT | 4, 5 | TX/RX remote control |
| Pulse Counter | 32 | |

### General purpose (free for user projects)

| GPIO | Notes |
|------|-------|
| GPIO 2 | On-board LED (NAT router firmware uses this) |
| GPIO 23 | RESET button (on this board) |
| GPIO 25 | Free (also LED PWM / I2S) |
| GPIO 26 | Free (ADC1_CH0, DAC1) |
| GPIO 27 | Free (I2S) |
| GPIO 28 | Free |
| GPIO 29 | Free |
| GPIO 30 | Free |
| GPIO 31 | Free |
| GPIO 32 | Free (ADC1_CH4, also strapping) |
| GPIO 33 | ADC1_CH5 |
| GPIO 34 | Input-only, ADC2_CH6 |
| GPIO 35 | Input-only, ADC2_CH7 |
| GPIO 36 | VBAT sense (no GPIO) |
| GPIO 37 | No GPIO |
| GPIO 38 | ADC2_CH8 |
| GPIO 39 | Input-only, ADC2_CH11 |

---

## 6. ADC / DAC / Touch

| Feature | Spec |
|---------|------|
| ADC | 12-bit SAR, up to 18 channels (10 on ADC1, 8 on ADC2) |
| ADC1 channels | 0–9 (GPIO 32, 33, 34, 35, 36, 39, 1, 3, 4, 5) |
| ADC2 channels | 0–7 (GPIO 12, 13, 14, 15, 25, 26, 27, 34) |
| DAC | 2 × 8-bit (GPIO 25 = DAC1, GPIO 26 = DAC2) |
| Touch sensors | 10 channels (GPIO 4–15, 27–32) |
| Touch resolution | 12-bit |

---

## 7. Timers / Watchdogs / Clocks

| Feature | Spec |
|---------|------|
| 64-bit timers | 4 (2 per timer group) |
| 16-bit timers | 4 (2 per timer group) |
| LEDC PWM | 16 channels (8 per group) |
| Main watchdog | 1 per timer group (2 total) |
| Task watchdog | 1 (monitors FreeRTOS tasks) |
| RTC watchdog | 1 |
| Internal oscillator | 8 MHz (calibrated) |
| External crystal | 40 MHz (required for Wi-Fi/BT) |
| RTC 32 kHz crystal | Optional, for RTC + sleep |
| Audio PLL | 24 MHz |

---

## 8. Security / Crypto

| Feature | Spec |
|---------|------|
| AES | Hardware accelerated (128/192/256-bit) |
| SHA | Hardware accelerated (SHA-1, SHA-256) |
| RSA | Software (up to 3072-bit) |
| ECDSA | Software (P-256) |
| eFuse | 1 Kbit (256 system + 768 user) |
| Flash encryption | AES-XTS (via eFuse) |
| Secure Boot | v1/v2 (via eFuse) |
| Secure Download | v1/v2 |

---

## 9. Wi-Fi / Bluetooth RF Performance

| Parameter | Value |
|-----------|-------|
| Band | 2.4 GHz (2.400–2.4835 GHz) |
| Wi-Fi standard | 802.11 b/g/n |
| Max data rate | 150 Mbps (802.11n 20 MHz) |
| TX output power | 20.5 dBm max |
| RX sensitivity | -75 dBm (802.11b 11 Mbps) |
| BT version | 4.2 BR/EDR + BLE dual mode |
| BT TX power | 14 dBm |
| BT RX sensitivity | -85 dBm |
| Simultaneous | Wi-Fi + BT (time-multiplexed) |
| Antenna | On-board PCB antenna (via balun + switch) |
| Max concurrent Wi-Fi connections | 10 (ESP-NOW encrypt constraint) |

### Wi-Fi modes supported

- STA (station)
- softAP (access point)
- STA + softAP concurrent
- Promiscuous / monitor mode
- WPA2-PSK, WPA2-Enterprise (EAP), open

### TX power setting (this board)

- Firmware sets: **84** (0.5 dB steps) = ~20 dBm max

---

## 10. Power Consumption

| Mode | Typical Current | Notes |
|------|-----------------|-------|
| Deep-Sleep | ~5 µA | ULP coprocessor active |
| Light-Sleep | ~160 µA | Wi-Fi off, RTC clock on |
| Wi-Fi RX (idle) | ~95–100 mA | |
| Wi-Fi TX (max power) | ~240 mA | 20.5 dBm output |
| Wi-Fi TX (continuous) | ~280 mA | peak bursts |
| CPU @ 240 MHz (Wi-Fi off) | ~240 mA | |
| All off (Deep-Sleep) | ~5–25 µA | |

**Power supply:** 3.3 V (VCC) / 5 V USB via onboard LDO.
**Recommended:** 5 V / 1 A USB supply for development.

---

## 11. Operating Environment

| Parameter | Value |
|-----------|-------|
| Operating temp | -40 °C to +85 °C |
| Storage temp | -40 °C to +125 °C |
| Moisture sensitive | Yes (MSL per IPC) |
| RoHS | Compliant |

---

## 12. Serial / USB (this board)

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

## 13. JTAG / Debug

- GPIO 12 (MTDO), GPIO 13 (MTCK), GPIO 15 (MTDI), GPIO 14 (MTSR)
- OpenOCD + GDB via PlatformIO `toolchain-esp32`
- `idf.py debug-server` + `openocd` for in-circuit debug
- JTAG via UART (serial) also supported

---

## 14. NVS (Non-Volatile Storage)

- Partition: `nvs` at 0x09000, 32 KB
- Namespace used by NAT router firmware: `esp32_nat`
- For new projects: use your own namespace to avoid collisions

---

## 15. Boot Log (reference, live-captured)

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

## 16. New-Project Checklist

Before starting a new project on this board, verify:

- [ ] Flash layout: 4 MB, ota_0 @ 0x10000, ota_1 @ 0x187000
- [ ] Partition table matches bootloader expectations (`larger.csv` or custom)
- [ ] UART: TX=GPIO1, RX=GPIO3; use a proper USB-serial adapter
- [ ] Boot: IO0=GPIO0 (bootloader), EN=GPIO16 (reset)
- [ ] Wi-Fi: 2.4 GHz only; concurrent STA+AP supported
- [ ] RAM: ~156 KB DRAM + ~141 KB IRAM; budget ~30 KB for Wi-Fi
- [ ] NVS: use a project-specific namespace
- [ ] JTAG: GPIO12/13/14/15 for OpenOCD
- [ ] Power: 3.3 V, peak ~300 mA; use 5 V/1 A USB supply
- [ ] MAC: STA=`...9c`, AP=`...9d` (factory; don't override unless needed)
- [ ] Flash-locked pins (GPIO 4–11) are NOT available for I/O
- [ ] Input-only pins (GPIO 34, 35, 39) cannot be driven as outputs
- [ ] On-board LED is on GPIO2 (if used by firmware, avoid conflicting)
- [ ] ADC2 channels cannot be read while Wi-Fi is active (shares SRAM)

---

## 17. Datasheet References

- ESP32 Series Datasheet v5.3: https://documentation.espressif.com/esp32_datasheet_en.pdf
- ESP32 Technical Reference Manual: https://documentation.espressif.com/esp32-trm_en.pdf
- ESP32-D0WD-V3 Chip Revision v3.0 User Guide: https://documentation.espressif.com/esp32-v3-user-guide_en.pdf
- ESP32 Errata: https://documentation.espressif.com/esp32-errata_en.pdf
