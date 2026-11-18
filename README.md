<p align="center">
  <img src="Assets/buswrench-logo.png" alt="BusWrench" width="480">
</p>

<p align="center">
  <b>Flash and configure your CAN boards from one desktop app.</b>
</p>

BusWrench is a Windows desktop tool (Qt 6 / QML) that talks to the boards
of a race car through a PEAK PCAN-USB adapter. It finds the boards on the
CAN bus, updates their firmware **entirely over CAN** (no USB cable, no
programmer), shows their details (uptime, flash partitions, errors, ...) and
lets you edit the settings that were hard-coded in the firmware (sensor
calibration, display texts, alarms, node ID) without recompiling.

It was born for the electronics of a BMW E36 race car, but the protocol is
simple and open: any board can join the bus by implementing the same few
frames.

## Features

**Available now**
- Bus scan: finds every node and shows chip, node ID, firmware version,
  hardware revision and unique ID. Online/offline status in real time.
- Firmware update over CAN for the ESP32-S3 (OTA, two application
  partitions, the running firmware is never touched while updating).
- Safe transfer: blocks of 256 bytes, an acknowledgement for each block,
  automatic retries, timeouts, CRC32 check of the whole image before the
  new firmware is activated.
- Live log of everything the program does, including every control frame
  sent by the PC and answered by the board.
- **Details page** for each board: identity (name, node, chip, hardware,
  firmware, UID, build date, git commit), state and bus (last contact,
  frames, uptime, last reset reason, CAN error counters, chip temperature)
  and the two OTA flash partitions (version, address, used space, which
  one is running).
- **Actions** on a board: reboot, identify (the board blinks its display to
  recognize it among several ones) and rollback to the firmware stored in
  the other partition.
- **Configuration page** for the gauge boards, with four tabs:
  - *Sensore*: calibration table (2 to 16 points, voltage to value) with a
    curve graph where the points can be dragged, live value and voltage,
    filter time and fault limits.
  - *Display*: name, unit, decimals and what to show when the sensor is in
    fault (`- - -` or the last valid value).
  - *Allarmi*: three alarms (low, very low, high), each with enable,
    threshold, hysteresis and delay, plus "ignore the alarms for the first
    seconds after power on". The live state comes from the board.
  - *CAN*: change the node ID, period of the sensor frame, and a live view
    of the sensor frame byte by byte.
  - Values are written to the board (they work at once), then saved in its
    permanent memory (NVS), or restored to the factory values.
- **Settings page**: CAN bitrate (125 / 250 / 500 / 1000 kbit/s, applied by
  reconnecting the adapter), automatic rescan after an update, and the list
  of known nodes with their name and icon.
- Custom icons: copy your own SVG/PNG files in the icon folder and pick them
  for each node.
- Notifications (toast) for settings, actions and the result of an update.
- DBC file for [SavvyCAN](https://www.savvycan.com/) to decode the frames
  while you watch the bus (the update and details frames; the sensor frame
  and the parameters are not in the DBC yet).

**Planned**
- Firmware update of STM32 boards through a small CAN bootloader, with its
  own flash panel and the "Enter bootloader" button.
- Configuration of the CAN_PDM board (limits, thresholds, channel settings).

## Supported boards

| Board | MCU | Role | Update over CAN | Details and actions | Configuration |
|-------|-----|------|-----------------|---------------------|---------------|
| **CAN_GAUGE** | ESP32-S3 | Gauge with one analog channel (fuel level, pressure, ...) and a round display | Working | Working | Working |
| **CAN_PDM** | STM32F446 | Power distribution module: fans, pumps and the other loads of the car, with smart control and protections (overcurrent, temperature, inrush, short circuit) | Planned (bootloader) | Planned | Planned |

The firmware of each board lives in its own repository:

- CAN_GAUGE: `https://github.com/nicola-reat/can_gauge`
- CAN_PDM: `https://github.com/nicola-reat/can_pdm`

## How it works

Standard 11-bit CAN IDs, 500 kbit/s (configurable), little endian. Each node
has an ID (for example `0x45`), and the IDs of the protocol are derived from it:

| ID | Direction | Content |
|----|-----------|---------|
| `0x500 + node` | board → all | Sensor value, sent by the board by itself (default every 100 ms) |
| `0x600` | PC → all | Broadcast. Only `SCAN` is accepted |
| `0x600 + node` | PC → board | Commands |
| `0x680 + node` | board → PC | Replies and heartbeat |
| `0x700 + node` | PC → board | File data, 8 bytes per frame |

The first data byte of every frame tells what it is (a command or a message);
the other bytes are its parameters. Commands are accepted only on the ID of the
node, never in broadcast (only `SCAN` is), so a command can never reach all the
boards at the same time. The sensor frame is the exception: it has no command
byte (see below).

**Commands (PC → board)**

| Code | Name | Payload |
|------|------|---------|
| `0x01` | SCAN | |
| `0x10` | BEGIN | file size (u32) |
| `0x11` | CRC | CRC32 of the whole file (u32) |
| `0x12` | BLOCK_END | block number (u16), length (u16) |
| `0x13` | FINISH | |
| `0x14` | ABORT | |
| `0x15` | ENTER_BOOT | |
| `0x20` | DETAILS | |
| `0x21` | REBOOT | |
| `0x22` | IDENTIFY | |
| `0x23` | ROLLBACK | |
| `0x30` | PARAM_READ | parameter, index |
| `0x31` | PARAM_WRITE | parameter, index, value (u32) |
| `0x32` | PARAM_SAVE | |
| `0x33` | PARAM_RESET | |

**Replies (board → PC)**

| Code | Name | Payload |
|------|------|---------|
| `0x80` | HEARTBEAT (every second) | state, firmware major/minor/patch |
| `0x81` | INFO_A | chip, hardware letter, firmware major/minor/patch |
| `0x82` | INFO_B | unique ID (6 bytes) |
| `0x90` | BEGIN_ACK | status |
| `0x92` | BLOCK_ACK | block number (u16), status |
| `0x93` | FINISH_ACK | status |
| `0x95` | BOOT_ACK | status |
| `0xA0` | DETAIL_A | uptime in seconds (u32), reset reason, CAN TX errors, CAN RX errors |
| `0xA1` | DETAIL_B | temperature (i8, `0x80` = not available), year-2000, month, day, hour, minute of the build |
| `0xA2` | DETAIL_C | git hash (u32), "uncommitted changes" flag |
| `0xA3` | PART_A | slot (0/1), flags, address/64 KB, size/64 KB, used KB (u16) |
| `0xA4` | PART_B | slot (0/1), firmware major/minor/patch (`0xFF` = none) |
| `0xA5` | ACTION_ACK | command, result (`0` ok, `1` failed) |
| `0xB0` | PARAM_VALUE | parameter, index, value (u32) |
| `0xB1` | PARAM_ACK | command, parameter, status |

Status: `0` OK, `1` RETRY, `2` TOO_BIG, `3` BUSY, `4` FLASH, `5` INVALID,
`6` UNKNOWN (the board does not know this parameter).

PART_A flags: bit 0 = running now, bit 1 = starts at next boot, bit 2 = valid
image found. Reset reasons: `1` power on, `2` external reset, `3` software,
`4` crash, `5` watchdog, `6` brown-out, `7` other, `0` unknown.

**Update sequence**

1. `ENTER_BOOT` → `BOOT_ACK`
2. `BEGIN` (size) and `CRC` → the board prepares the spare partition → `BEGIN_ACK`
3. For every block: 32 data frames on `0x700 + node`, then `BLOCK_END` → `BLOCK_ACK`
4. `FINISH`: the board checks size, CRC and image, selects the new
   partition → `FINISH_ACK` → restart

If the cable is unplugged or the PC closes in the middle of an update, the
board cancels after 10 seconds and keeps its old firmware.

Every update goes to the partition that is **not** running, so `ota_0` and
`ota_1` alternate. The previous firmware stays in the other partition and can
be started again with the rollback action.

**Details**

`DETAILS` is answered with 7 frames: `DETAIL_A`, `DETAIL_B`, `DETAIL_C`, and a
`PART_A` + `PART_B` pair for each of the two partitions. The Details page asks
for them every 2 seconds while it is open (never during an update).

**Sensor frame (`0x500 + node`)**

A gauge board sends its value by itself, every 100 ms by default (the period
can be changed, 20 to 500 ms). The frame has 6 bytes and no command byte. It
is not sent while a firmware update is running.

| Byte | Content |
|------|---------|
| 0-1 | value × 10 (i16, `FF FF` = no valid value yet). `C8 00` = 20.0 |
| 2-3 | voltage at the connector, in mV (u16) |
| 4 | flags: bit 0 sensor fault, bit 1 low alarm, bit 2 high alarm, bit 3 very low alarm |
| 5 | counter, grows at every frame (0..255): it stops if the board stops |

Example: `0x545  C8 00  D0 07  00  2A` = 20.0, 2000 mV, no flags, frame 42.
While the sensor is in fault, or has no valid value, all the alarms are off
and only bit 0 is set.

**Parameters**

The Configuration page uses `PARAM_READ`, `PARAM_WRITE`, `PARAM_SAVE` and
`PARAM_RESET`:

- `PARAM_WRITE` is answered with `PARAM_ACK`; the value works at once but only
  in RAM, so it is lost at power off.
- `PARAM_SAVE` writes the current values in the permanent memory (NVS).
- `PARAM_RESET` restores the factory values and erases the saved ones. The
  node ID is not changed.
- The parameter commands are refused with `BUSY` while an update is running.

| Param | Name | Index | Value |
|-------|------|-------|-------|
| `0x01` | FILTER_MS | | filter time, 50..10000 ms |
| `0x02` | LOW_MV | | fault limit, sensor below this voltage (mV), must be lower than HIGH_MV |
| `0x03` | HIGH_MV | | fault limit, sensor above this voltage (mV) |
| `0x04` | NODE_ID | | new node ID, 1..0x7F. Saved at once, active after a reboot |
| `0x05` | NAME | 0..2 | name of the gauge, 4 characters per frame, 12 bytes at most |
| `0x06` | UNIT | 0 | unit, 4 bytes (UTF-8, "°C" is 3 bytes) |
| `0x07` | DECIMALS | | digits after the point, 0..2 |
| `0x08` | FAULT_MODE | | on fault: `0` = "- - -" blinking, `1` = last valid value |
| `0x09` | SENSOR_PERIOD | | period of the sensor frame, 20..500 ms |
| `0x10` | TABLE_N | | number of points of the calibration table, 2..16. Writing it applies the points sent before |
| `0x11` | TABLE_POINT | point | voltage in mV (low 16 bits) and value × 10 (high 16 bits, signed). Voltages must increase |
| `0x20` | ALARM_ENABLE | alarm 0..2 | `0` off, `1` on |
| `0x21` | ALARM_THRESHOLD | alarm | threshold × 10 |
| `0x22` | ALARM_HYST | alarm | hysteresis × 10 |
| `0x23` | ALARM_DELAY | alarm | delay in tenths of a second, 0..600 |
| `0x24` | ALARM_STARTUP | 0 | seconds after power on in which the alarms are ignored, 0..60 |

Alarms: `0` = low (value below the threshold), `1` = very low (below),
`2` = high (above). The hysteresis is the distance the value must go back
from the threshold before the alarm switches off: with threshold 12.0 and
hysteresis 1.0 the alarm is on below 12.0 and off above 13.0.

The same definitions (except the sensor frame and the parameters in the DBC)
are in [`protocol/can_update_proto.h`](protocol/can_update_proto.h) (shared by
PC and firmware) and in [`protocol/can_update.dbc`](protocol/can_update.dbc)
(for SavvyCAN, generated by `protocol/make_update_dbc.py`).

## Getting started

**Requirements**
- Windows 10/11
- PEAK PCAN-USB adapter and the
  [PEAK driver](https://www.peak-system.com/) (PCAN-Basic)
- Qt 6.12 with MinGW, including **Qt Serial Bus**, Qt Quick, Qt Shader Tools
- CMake and Qt Creator

**Build**
1. Open `CMakeLists.txt` in Qt Creator and select the Qt 6.12 MinGW kit.
2. Build and run.
3. Connect the PCAN-USB: the status box in the sidebar turns green.

The UI was designed in Qt Design Studio (`*.ui.qml` files); the logic is in
C++ and in `App.qml`.

## Usage

1. Press **Scansiona** (Scan): the boards appear as cards.
2. Select a card and press **Aggiorna Firmware** (Update firmware).
3. Choose the `.bin` file (button or drag & drop). The app shows name,
   version, size and SHA-256.
4. Press **Avvia Aggiornamento** (Start update). Progress, remaining time
   and the full log are on the same page.
5. At the end the board restarts, a message tells if the update worked and the
   card shows the new version.

**Details and actions**
- Select a card and press **Dettagli** to open the Details page of the board.
- **Riavvia scheda** restarts it, **Identifica scheda** makes its display blink
  for 4 seconds, **Versione precedente** starts the firmware of the other
  partition (it asks for a confirmation first).
- The buttons are available only for an online board with no update running.

**Configuration** (sidebar)
- Select a gauge card in the Devices page, then open **Configurazione**: the
  page works on the selected board.
- **Leggi dalla scheda** reads all the values, **Invia alla scheda** checks
  them and sends them (the board uses them at once), **Salva sulla scheda**
  writes them in the permanent memory, **Fabbrica** restores the factory
  values (it asks for a confirmation first).
- If a value is not valid nothing is sent and a message tells which one.
- **Change the node ID** in the *CAN* tab: the new ID is saved in the board,
  the board restarts, and the app scans again. Change the ID with only one
  board at a time on the bus: two boards with the same ID disturb each other.
  A new board has the default ID `0x45`.

**Settings** (sidebar)
- **CAN speed**: choose the bitrate and press **Applica e riconnetti**.
  The same speed must be used by all the boards on the bus.
- **Known nodes**: give a name and an icon to each node ID. A board that is not
  in the list is shown as "Nodo 0xNN". The list only gives names and icons: the
  boards found by the scan are always shown.
- **Custom icons**: press **Apri cartella icone** and copy your SVG/PNG files
  there; they appear in the icon picker by themselves.

Without hardware you can press `Ctrl+T` to add simulated devices to the list.

## Adding your own board

A board takes part in the update if its firmware:
1. uses a node ID of its own (`0x600/0x680/0x700 + node`);
2. answers `SCAN` with `INFO_A` and `INFO_B`, and sends the heartbeat;
3. implements `BEGIN`, `CRC`, `BLOCK_END`, `FINISH` and `ABORT`.

To also use the Details page and the actions, the board answers `DETAILS`
(frames `0xA0`...`0xA4`) and `REBOOT`, `IDENTIFY`, `ROLLBACK` (answer `0xA5`).
These are optional: a board that does not know them simply stays at "-".

To use the Configuration page, the board sends the sensor frame
(`0x500 + node`) and answers the parameter commands (`PARAM_READ`,
`PARAM_WRITE`, `PARAM_SAVE`, `PARAM_RESET`). A parameter the board does not
have is answered with status `6` (UNKNOWN).

[`can_node.c`](https://github.com/nicola-reat/can_gauge) in the CAN_GAUGE
firmware is a complete example for the ESP32-S3 (ESP-IDF).

## Project structure

```
src/        C++ backend (CAN adapter, device list, update manager,
            settings, known nodes)
qml/        User interface (Qt Design Studio files and App.qml)
protocol/   CAN protocol: header, DBC file and DBC generator
assets/     Logo and icons
docs/       Notes and diagrams
```

## Roadmap

- [x] PCAN-USB connection with automatic reconnection
- [x] Bus scan and device list
- [x] ESP32-S3 firmware update over CAN
- [x] Live log with the CAN frames
- [x] Settings page (bitrate, automatic rescan, known nodes, custom icons)
- [x] Details page (identity, state, flash partitions)
- [x] Actions: reboot, identify, rollback
- [x] Parameter configuration over CAN for the gauge (sensor, display,
      alarms, node ID)
- [ ] Sensor frame and parameters in the DBC file
- [ ] STM32 CAN bootloader and update
- [ ] Details page for STM32 (flash panel, "Enter bootloader")
- [ ] Parameter configuration for CAN_PDM

## License

MIT, see [`LICENSE`](LICENSE).
