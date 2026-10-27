# android_vendor_rpi_rpi5

Vendor files for AOSP Android on the Raspberry Pi 5.
Branch `android-15`.

## Contents

| Path | Purpose |
|---|---|
| `boot/` | Firmware configuration (`config.txt`) |
| `mesa/` | Mesa GPU drivers: OpenGL ES (V3D) and Vulkan (V3DV), with build scripts |
| `firmware/` | Wi-Fi and Bluetooth firmware for the CYW43455 |

Each folder has a `BUILD_INFO` with sources, versions and checksums.

## License

| Path | License |
|---|---|
| `mesa/` | MIT (see `mesa/licenses/`) |
| `firmware/` | Cypress redistribution licence (`firmware/LICENCE.cypress`) |
| Other files | Apache 2.0 |
