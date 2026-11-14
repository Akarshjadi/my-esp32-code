# BLE testing — where to look (we do not vendor this)

This repo does not ship BLE attack code. The radio exists on ESP32-C6/S3,
but writing a BLE spam suite from scratch is worse than using an
existing, tested, well-maintained project.

## What to use instead

| Goal | Use | Why |
|---|---|---|
| BLE advertisement spam / spoofing | [ESP32 Marauder](https://github.com/justcallmekoko/ESP32Marauder) | Dedicated BLE build, actively maintained |
| BLE + Wi-Fi combo lab | [Ghost ESP](https://github.com/GhostESP/GhostESP) | Same idea, different radio coverage |
| BLE sniffing / pairing capture | [ESP32-BLE-sniffer](https://github.com/psxylor/kbhit-ble-sniffer) | Proper sniffer hardware |
| 802.15.4 / Zigbee (ESP32-C6) | [nRF52840 Dongle + Wireshark](https://www.nordicsemi.com/Products/Development-hardware/nRF52840-Dongle) | C6's 802.15.4 radio needs a proper sniffer |

## Why not in this repo?

1. The repo's sdkconfigs have `CONFIG_BT_ENABLED` **unset** — a BLE build
   is a different firmware, not a flag flip.
2. BLE attack surface varies wildly by target (phones, watches, keyboards).
   Vendoring one "BLE spam" module would imply a coverage we can't back.
3. Attribution matters: the well-tested projects above have clear license
   and maintainer stories. Vendoring them into an APSTA router muddies both.

## If you still want to integrate

Run Marauder/Ghost ESP on a **second** ESP32 (the same dual-radio topology
described in [`docs/wifi-test-suite.md`](wifi-test-suite.md) for Wi-Fi injection).
The NAT router stays on `esp32-lab`; the BLE/sniffer board stays on its own
firmware. No shared binary, no confusion about what this repo ships.
