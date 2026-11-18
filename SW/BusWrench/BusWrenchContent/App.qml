import QtQuick
import QtQuick.Controls
import BusWrench
import QtQuick.Dialogs
import QtQml.Models

/*
 * OVERVIEW
 * --------
 * Main application window. It loads the UI designed in Qt Design Studio
 * (Screen01) and connects it to the C++ backend. The objects below are created
 * in main.cpp and are visible here by name:
 *   can      - CAN adapter, bus scan, list of devices (CanBackend)
 *   updater  - firmware transfer (UpdateManager)
 *   settings - saved settings: bitrate, automatic rescan (AppSettings)
 *   nodes    - list of the known nodes: ID, name, icon (NodeConfig)
 *
 * This file contains no design: it only links backend data to the UI.
 */


Window {
    id: window
    width: mainScreen.width
    height: mainScreen.height

    visible: true
    title: "BusWrench"

    // Background color of an action card: slightly lighter when the mouse is over it
    // and the card can be used now. A disabled card never lights up.
    function hoverBg(hovered, enabled) {
        return (hovered && enabled) ? "#14305A" : "#0E1D36"
    }

    /* ---------- Devices and Update pages ---------- */

    // Card selected by the user (null = no selection). The detail panel
    // on the right reads its data from this card.
    property var selectedCard: null
    readonly property bool selOnline: selectedCard ? selectedCard.online : false

    // True when an update can be started: device online, file valid for this
    // board, nothing running.
    readonly property bool canStart: selectedCard !== null && selOnline
                                     && updater.fileLoaded && !updater.busy
                                     && fileProblem === ""

    // Node ID (e.g. "0x45") to select again after a new scan. It is set after
    // an update, so the same board is selected again when it comes back.
    property string preferredNode: ""

    // Update just finished: node ID and version of the file. After the board
    // restarts, they are used to check which firmware it is really running.
    property int updatedNode: -1
    property string updatedVersion: ""

    // Chip type of the selected board (1 = ESP32-S3, 2 = STM32, 0 = unknown),
    // from the scan.
    readonly property int selChipId: selectedCard
                                     ? (can.devices.infoFor(parseInt(selectedCard.nodeId)).chipId || 0)
                                     : 0

    // Problem between the loaded file and the selected board ("" = no problem).
    // It reads fileName too, so it is evaluated again when a new file is loaded.
    readonly property string fileProblem: (updater.fileLoaded && updater.fileName !== ""
                                           && selectedCard !== null)
                                          ? updater.problemFor(selChipId) : ""

    // A red message appears as soon as a problem is found.
    onFileProblemChanged: {
        if (fileProblem !== "")
            showToast(fileProblem, true)
    }

    // Color of the result of the last update: green = ok, red = error,
    // orange = cancelled, blue = no result (idle or running).
    readonly property color outcomeColor: updater.outcome === 1 ? "#22C55E"
                                        : updater.outcome === 2 ? "#F87171"
                                        : updater.outcome === 3 ? "#F5A524"
                                        : "#1E7BFF"

    /* ---------- Settings page: CAN speed ---------- */

    // Bitrate selected in the Settings page. It is saved only when "Applica" is clicked.
    property int pendingBitrate: settings.bitrate

    /* ---------- Toast (message at the top right) ---------- */

    // Shows a message at the top right for 3 seconds (red if isError is true).
    function showToast(message, isError) {
        toast.message = message
        toast.error = (isError === true)
        toast.opacity = 1
        toastTimer.restart()
    }

    /* ---------- Details page ---------- */

    // Node ID (number) of the device shown in the Details page.
    property int detailNodeId: -1

    // Data of that device, read from the list of devices (see DeviceModel::infoFor).
    // It is an empty object if the device is not in the list.
    property var detail: ({})
    readonly property bool hasDetail: detail.nodeId !== undefined
    readonly property bool detailOnline: hasDetail && detail.online === true
    readonly property bool detailIsEsp: hasDetail && detail.chipId === 1

    // True when the board has answered the DETAILS command at least once.
    readonly property bool hasBoardData: hasDetail && detail.detailsOk === true

    // Current time in ms, updated together with "detail" (used for "last contact").
    property double nowMs: Date.now()

    // Reads the data of the device again (called every 500 ms by the timer below).
    function refreshDetail() {
        nowMs = Date.now()
        detail = detailNodeId >= 0 ? can.devices.infoFor(detailNodeId) : ({})
    }

    // "0,4 s fa", "12 s fa", "3 min fa" from a time in milliseconds.
    function agoText(ms) {
        if (ms < 0) ms = 0
        if (ms < 10000) return (ms / 1000).toFixed(1).replace(".", ",") + " s fa"
        if (ms < 60000) return Math.round(ms / 1000) + " s fa"
        return Math.round(ms / 60000) + " min fa"
    }

    // Two digits: 7 -> "07".
    function pad2(n) { return (n < 10 ? "0" : "") + n }

    // Seconds -> "02:14:09" (with days if more than 24 h: "3 g 02:14:09").
    function uptimeText(sec) {
        var d = Math.floor(sec / 86400)
        var h = Math.floor((sec % 86400) / 3600)
        var m = Math.floor((sec % 3600) / 60)
        return (d > 0 ? d + " g " : "") + pad2(h) + ":" + pad2(m) + ":" + pad2(sec % 60)
    }

    // Reset code of the protocol -> text.
    function resetText(code) {
        switch (code) {
        case 1: return qsTr("Accensione")
        case 2: return qsTr("Reset esterno")
        case 3: return qsTr("Riavvio software")
        case 4: return qsTr("Errore (crash)")
        case 5: return qsTr("Watchdog")
        case 6: return qsTr("Calo di tensione")
        case 7: return qsTr("Altro")
        default: return qsTr("Sconosciuto")
        }
    }

    // ---- Flash slots (s = 0 for ota_0, 1 for ota_1) ----

    // Is this slot the one the board is running now? (flag bit 0)
    function slotRunning(s) {
        return hasBoardData && (detail["p" + s + "Flags"] & 1) !== 0
    }
    // Does this slot contain a valid firmware image? (flag bit 2)
    function slotValid(s) {
        return hasBoardData && (detail["p" + s + "Flags"] & 4) !== 0
    }
    // Fraction of the partition used by the firmware (0 ... 1).
    function slotUsedPct(s) {
        if (!slotValid(s)) return 0
        var sizeKb = detail["p" + s + "Size"] * 64         // size is in units of 64 KB
        return sizeKb > 0 ? Math.min(1, detail["p" + s + "Used"] / sizeKb) : 0
    }
    // "Indirizzo 0x110000 · 1,5 MB"
    function slotAddrText(s) {
        if (!hasBoardData || !detail["p" + s + "Present"]) return qsTr("Indirizzo -")
        var addr = (detail["p" + s + "Addr"] * 65536).toString(16).toUpperCase()
        while (addr.length < 6) addr = "0" + addr
        var mb = (detail["p" + s + "Size"] * 64 / 1024).toFixed(1).replace(".", ",")
        return qsTr("Indirizzo 0x") + addr + " · " + mb + " MB"
    }
    // "Occupata: 812 KB (53%)"
    function slotUsedText(s) {
        if (!slotValid(s)) return qsTr("Occupata: -")
        return qsTr("Occupata: ") + detail["p" + s + "Used"] + " KB ("
               + Math.round(slotUsedPct(s) * 100) + "%)"
    }
    // Text of the tag at the top of a slot.
    function slotTagText(s) {
        if (slotRunning(s)) return qsTr("In esecuzione")
        return slotValid(s) ? qsTr("Precedente") : qsTr("Vuota")
    }

    // ---- Map of the flash (panel "Partizioni flash") ----

    // Number from the board data (0 if it is missing).
    function num(name) { return detail[name] || 0 }

    // The map is drawn only if the board has sent the size of the flash
    // and both partitions (an old firmware does not send the size).
    readonly property bool mapOk: hasBoardData && num("flashMb") > 0
                                  && detail.p0Present === true && detail.p1Present === true

    // The map is 596 px wide: pixels for one unit of 64 KB.
    readonly property real mapScale: mapOk ? 596 / (num("flashMb") * 16) : 0

    // x position (in the panel) of a point given in units of 64 KB.
    function mapX(units) { return 16 + units * mapScale }

    // Width of a block that starts at "start" and is "size" units long (2 px gap).
    function mapW(start, size) { return Math.max(2, mapX(start + size) - mapX(start) - 2) }

    // The "data" area starts after the last app partition and goes to the end of the flash.
    readonly property int dataStartU: Math.max(num("p0Addr") + num("p0Size"),
                                               num("p1Addr") + num("p1Size"))
    readonly property int dataUnits: num("flashMb") * 16 - dataStartU

    // Units of 64 KB -> "3,5" (megabytes).
    function mbText(units) { return (units * 64 / 1024).toFixed(1).replace(".", ",") }

    // ---- Actions on the board (reboot, identify, rollback) ----

    // Command codes of the protocol (see can_update_proto.h).
    readonly property int cmdReboot: 0x21
    readonly property int cmdIdentify: 0x22
    readonly property int cmdRollback: 0x23

    // The action buttons work only if the board is online, no update is running
    // and it is an ESP32 (the STM32 firmware does not know these commands yet).
    readonly property bool actionsEnabled: detailOnline && detailIsEsp && !updater.busy

    // Slot that is NOT running: the one a rollback would start.
    function otherSlot() { return slotRunning(0) ? 1 : 0 }

    // A rollback needs a valid firmware in the other slot.
    readonly property bool rollbackPossible: actionsEnabled && hasBoardData && slotValid(otherSlot())

    /* ---------- Settings page: editor of the known nodes ---------- */

    // Row of the "nodes" list being edited. -1 means "new node" (empty editor).
    property int editRow: -1

    // Icon chosen in the editor: a file name of the "images" folder
    // ("ico_cpu.svg") or the full URL of an icon of the user folder.
    property string editIcon: "ico_cpu.svg"

    // Icons built into the program (files in the "images" folder).
    // To add one: import the SVG in Design Studio (Assets), run CMake again
    // and write its file name here.
    readonly property var builtinIcons: ["ico_gauge.svg", "ico_cpu.svg", "ico_keypad.svg",
                                         "ico_microchip.svg", "ico_zap.svg", "ico_clock.svg"]

    // Icons found in the user folder (file URLs). Updated by refreshIcons().
    property var userIcons: []

    // All the icons shown in the picker: built-in first, then the user ones.
    readonly property var allIcons: builtinIcons.concat(userIcons)

    // Returns the source for an Image: user icons are full URLs, the built-in
    // ones are files of the "images" folder.
    function iconSrc(name) {
        return name.indexOf("file:") === 0 ? name : "images/" + name
    }

    // Reads the user icon folder again. The list is replaced only if it changed,
    // so the picker does not jump while the user is scrolling it.
    function refreshIcons() {
        var list = nodes.userIcons()
        if (JSON.stringify(list) !== JSON.stringify(userIcons))
            userIcons = list
    }

    // Puts one node of the list in the editor (name, ID and icon).
    // row = -1 empties the editor, ready to write a new node.
    function pickNode(row) {
        editRow = row
        if (row >= 0) {
            var n = nodes.get(row)                          // fields of that row
            mainScreen.pageSettings.nameInput.text = n.nodeName
            mainScreen.pageSettings.idInput.text = n.idText
            editIcon = n.iconFile
        } else {
            mainScreen.pageSettings.nameInput.text = ""
            mainScreen.pageSettings.idInput.text = "0x"     // starts the ID the right way
            editIcon = "ico_cpu.svg"
        }
    }

    // At startup: read the icon folder and show the first node in the editor.
    Component.onCompleted: {
        refreshIcons()
        pickNode(nodes.count > 0 ? 0 : -1)
        addHoverToAll(mainScreen)          // HOVER: hover on all the buttons of the pages
    }

    /* ---------- Configuration page (sensor of a CAN_GAUGE board) ---------- */

    // Node shown in the page: the board selected in the Devices page
    // ("0x45" -> 69), or -1 if no card is selected.
    readonly property int cfgNode: selectedCard ? parseInt(selectedCard.nodeId) : -1

    // Selected tab: 0 Sensor, 1 Display, 2 Alarms, 3 CAN, 4 System.
    property int cfgTab: 0

    // True when a field was edited and not yet written to the board.
    property bool cfgDirty: false
    // Row of the calibration table selected by the user (-1 = none).
    property int cfgSel: -1
    // Node ID asked to the board (-1 = no change in progress). When the board
    // confirms it, the board is restarted so the new ID becomes active.
    property int cfgNodeTarget: -1

    // Number -> text like "0x46" (at least two digits, capital letters).
    function hexId(v) { return "0x" + (v < 16 ? "0" : "") + v.toString(16).toUpperCase() }
    // Unit of the value (read from the board, the CAN frame carries only the number).
    property string sensorUnit: "L"

    // Display options read from the board: digits after the point (0..2) and what to
    // show on fault (0 = "- - -", 1 = last valid value). They can be changed in the page.
    property int cfgDecimals: 1
    property int cfgFaultMode: 0
    // Period of the sensor frame in ms (read from the board).
    property int cfgPeriod: 100
    // Last valid value (tenths) seen while the page is open, for "show the last valid value".
    property int cfgLastX10: -1


    // Last sensor values of that board, read from the backend every 200 ms
    // while the page is open (see the Timer at the end of this file).
    property var cfgSensor: ({})

    // Fresh data = a sensor frame of THIS board arrived less than 1 second ago.
    // A board without sensor (the PDM) never sends it, so it is never "fresh".
    readonly property bool cfgFresh: cfgNode >= 0 && cfgSensor.valid === true
                                     && cfgSensor.ageMs < 1000
    // Sensor fault flag sent by the board.
    readonly property bool cfgFault: cfgFresh && cfgSensor.fault === true

    // Tenths -> text with the decimal comma: 325 -> "32,5".
    function fmtX10(v) { return (v / 10).toFixed(1).replace(".", ",") }
    // Value in tenths -> text with the chosen number of decimals: 325 -> "32,5" (1) / "33" (0) / "32,50" (2).
    // The table and the dragged points keep using fmtX10 (always one decimal),
    // so nothing is rounded by mistake.
    function fmtVal(v) { return (v / 10).toFixed(cfgDecimals).replace(".", ",") }
    // Byte -> two hex digits: 200 -> "C8" (negative numbers: only the lowest byte, like on the bus).
    function hex2(v) { var b = v & 0xFF; return (b < 16 ? "0" : "") + b.toString(16).toUpperCase() }

    // The 6 bytes of the last sensor frame, rebuilt from the decoded values.
    function frameHex() {
        var s = cfgSensor
        return hex2(s.valueX10) + " " + hex2(s.valueX10 >> 8) + "  "
             + hex2(s.mv) + " " + hex2(s.mv >> 8) + "  "
             + hex2(s.flags) + "  " + hex2(s.counter)
    }

    // The same frame explained byte by byte.
    function frameInfo() {
        var s = cfgSensor
        var yn = function(bit) { return (s.flags & bit) ? qsTr("SÌ") : qsTr("no") }
        return qsTr("byte 0-1  valore    ") + (s.valueX10 < 0 ? "—" : fmtVal(s.valueX10) + " " + sensorUnit) + "\n"
             + qsTr("byte 2-3  tensione  ") + s.mv + " mV\n"
             + qsTr("byte 4    flag\n")
             + qsTr("   bit0 guasto sensore    ") + yn(0x01) + "\n"
             + qsTr("   bit1 riserva           ") + yn(0x02) + "\n"
             + qsTr("   bit2 valore alto       ") + yn(0x04) + "\n"
             + qsTr("   bit3 riserva critica   ") + yn(0x08) + "\n"
             + qsTr("byte 5    contatore ") + s.counter + "\n\n"
             + qsTr("ultimo frame ricevuto ") + s.ageMs + qsTr(" ms fa")
    }
    // Text of the "state" box.
    function cfgStateText() {
        if (!cfgFresh) return qsTr("Nessun dato")
        if (!cfgFault) return qsTr("OK")
        if (cfgSensor.mv < 1000) return qsTr("Guasto: filo o corto a massa")
        if (cfgSensor.mv > 4000) return qsTr("Guasto: corto a 5 V")
        return qsTr("Guasto: fuori limiti")
    }

    // Puts the calibration table received from the board in the rows of the page.
    function fillCfgTable(p) {
        cfgRows.clear()
        for (var i = 0; i < p.table.length; ++i)
            cfgRows.append({ mvtxt: String(p.table[i].mv),
                             vtxt: fmtX10(p.table[i].valueX10) })
        cfgSel = -1
    }

    // Puts the parameters received from the board in the input fields and in the table.
    function fillCfgFields() {
        var p = can.sensorParams(cfgNode)
        var pg = mainScreen.pageConfig
        if (p.filterMs >= 0) pg.inFilter.text = p.filterMs
        if (p.lowMv >= 0)    pg.inLow.text = p.lowMv
        if (p.highMv >= 0)   pg.inHigh.text = p.highMv
        if (p.nodeNext >= 0 && !pg.inNode.activeFocus)      // not while the user is typing
            pg.inNode.text = hexId(p.nodeNext)
        if (p.nameKnown && !pg.inName.activeFocus)      // not while the user is typing
            pg.inName.text = p.name
        if (p.unitKnown) {
            sensorUnit = p.unit
            if (!pg.inUnit.activeFocus)
                pg.inUnit.text = p.unit
        }
        if (p.decimals >= 0)  cfgDecimals = p.decimals
        if (p.faultMode >= 0) cfgFaultMode = p.faultMode
        // Alarms: -1 = this value has not arrived yet
        for (var a = 0; a < 3; ++a) {
            if (p.alarmEnabled[a] >= 0) alarmRows.setProperty(a, "en",  p.alarmEnabled[a] === 1)
            if (p.alarmThr[a]     >= 0) alarmRows.setProperty(a, "thr", fmtX10(p.alarmThr[a]))
            if (p.alarmHyst[a]    >= 0) alarmRows.setProperty(a, "hys", fmtX10(p.alarmHyst[a]))
            if (p.alarmDelay[a]   >= 0) alarmRows.setProperty(a, "del", fmtX10(p.alarmDelay[a]))
        }
        if (p.alarmStartup >= 0 && !pg.inStartup.activeFocus)
            pg.inStartup.text = String(p.alarmStartup)
        if (p.periodMs >= 0) {
            cfgPeriod = p.periodMs
            if (!pg.inPeriod.activeFocus)
                pg.inPeriod.text = String(p.periodMs)
        }
        if (p.tableComplete) fillCfgTable(p)      // only when ALL the points arrived
    }

    /* ---------- HOVER: hover on all the clickable areas ---------- */

    // The "veil": a light blue rectangle put over a button. It is visible only
    // while the mouse is over the button, and it never takes the clicks.
    // A button that is dimmed (opacity < 0.9) is disabled: no veil, normal cursor.
    Component {
        id: hoverVeil

        Rectangle {
            id: veil

            property var area                                  // the MouseArea of the button
            readonly property bool active: area.parent.opacity > 0.9

            // Same position, size and rounded corners as the button.
            x: area.x
            y: area.y
            width: area.width
            height: area.height
            // Same rounded corners as the button; if the parent has none
            // (as in the sidebar), use 10 like the rest of the design.
            radius: (area.parent.radius !== undefined && area.parent.radius > 0) ? area.parent.radius : 10
            color: "#8AB8FF"
            opacity: (area.containsMouse && active) ? 0.16 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            // The mouse area must report the hover; the cursor is a hand
            // only on the buttons that can be used now.
            Binding { target: veil.area; property: "hoverEnabled"; value: true }
            Binding {
                target: veil.area
                property: "cursorShape"
                value: veil.active ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }

    // Adds the veil to one MouseArea (it does nothing if it is not needed).
    function addHover(area) {
        if (!area || area.hoverEnabled === true)
            return                                  // it already has its own hover
        if (area.width > 700 || area.height > 300)
            return                                  // big areas that cover a whole page
        hoverVeil.createObject(area.parent, { area: area })
    }

    // Walks all the items under "item" and calls addHover() on every MouseArea.
    function addHoverToAll(item) {
        if (!item)
            return
        for (var i = 0; i < item.children.length; ++i) {
            var c = item.children[i]
            // A MouseArea is the only item that has both of these properties.
            if (c.hoverEnabled !== undefined && c.containsMouse !== undefined)
                addHover(c)
            addHoverToAll(c)
        }
    }

    Screen01 {
        id: mainScreen

        anchors.centerIn: parent

        // CAN adapter status box (bottom left of the sidebar).
        statusTitle.text: can.statusTitle
        statusTitle.color: can.connected ? "#22C55E" : "#F87171"
        statusSub.text: can.connected
                        ? can.statusDetail + " | RX " + can.rxCount
                        : can.statusDetail
        canStatusCheck.visible: can.connected
        canStatusError.visible: !can.connected

        // "N devices found" text under the cards.
        pageDevices.countText.text: can.devices.count === 1
                                    ? "1 dispositivo trovato"
                                    : can.devices.count + " dispositivi trovati"

        // Detail panel: visible only when a card is selected.
        pageDevices.detailPanel.visible: window.selectedCard !== null
        pageDevices.dName.text: window.selectedCard ? window.selectedCard.deviceName : ""
        pageDevices.dChip.text: window.selectedCard ? window.selectedCard.chip : ""
        pageDevices.valNode.text: window.selectedCard ? window.selectedCard.nodeId : ""
        pageDevices.valUid.text: window.selectedCard ? window.selectedCard.uid : ""
        pageDevices.valFw.text: window.selectedCard ? window.selectedCard.firmware : ""
        pageDevices.valHw.text: window.selectedCard ? window.selectedCard.hardware : ""

        // ---- Update page: selected device ----
        pageUpdate.devName.text: window.selectedCard ? window.selectedCard.chip : "-"
        pageUpdate.data1.text: window.selectedCard ? window.selectedCard.nodeId : "-"
        pageUpdate.data2.text: window.selectedCard ? window.selectedCard.firmware : "-"
        pageUpdate.data3.text: window.selectedCard ? window.selectedCard.hardware : "-"
        pageUpdate.badge.color: window.selOnline ? "#11392F" : "#3A1518"
        pageUpdate.badgeStatus.color: window.selOnline ? "#22C55E" : "#F87171"
        pageUpdate.badgeStatusTxt.color: window.selOnline ? "#22C55E" : "#F87171"
        pageUpdate.badgeStatusTxt.text: window.selOnline ? "Online" : "Offline"

        // Ring around the chip icon: blue if the selected board is online, red if offline.
        pageUpdate.ringFg.strokeColor: (window.selectedCard !== null && !window.selOnline)
                                       ? "#F87171" : "#2BB6E8"

        // ---- Update page: firmware file info ----
        pageUpdate.infoNameData.text: updater.fileLoaded ? updater.fileName : "-"
        pageUpdate.infoVersionData.text: updater.fileLoaded ? updater.fileVersion : "-"
        pageUpdate.infoDimensionData.text: updater.fileLoaded ? updater.fileSize : "-"
        pageUpdate.infoSHAData.text: updater.fileLoaded ? updater.fileSha : "-"

        // ---- Update page: start / cancel button ----
        pageUpdate.btnStart.opacity: (window.canStart || updater.busy) ? 1.0 : 0.4
        pageUpdate.btnStart.color: updater.busy ? "#B3261E" : "#1E7BFF"
        pageUpdate.btnStartTxt.text: updater.busy ? qsTr("Annulla") : qsTr("Avvia Aggiornamento")

        // ---- Update page: progress ----
        pageUpdate.pctFg.end: updater.progress * 360
        pageUpdate.pctText.text: Math.round(updater.progress * 100) + "%"
        pageUpdate.barFg.width: 828 * updater.progress
        pageUpdate.statusTitle.text: window.fileProblem !== "" ? window.fileProblem
                                   : updater.statusText !== "" ? updater.statusText
                                   : qsTr("Stato aggiornamento")
        pageUpdate.etaText.text: updater.etaText !== "" ? qsTr("Tempo stimato: ") + updater.etaText
                                                        : qsTr("Tempo stimato: --:--")

        // ---- Update page: colors of the result ----
        // Big ring and bar take the color of the result.
        pageUpdate.pctFg.strokeColor: window.outcomeColor
        pageUpdate.barFg.color: window.outcomeColor
        // Status title: red if the file does not fit the board, otherwise the
        // color of the result (white if there is no result yet).
        pageUpdate.statusTitle.color: window.fileProblem !== "" ? "#F87171"
                                    : updater.outcome !== 0 ? window.outcomeColor
                                    : "#FFFFFF"

        // Icon of the detail panel: the same icon used by the selected card
        // (a file of the "images" folder or an icon of the user folder).
        pageDevices.detailIcon.source: window.selectedCard && window.selectedCard.iconFile !== ""
                                       ? window.iconSrc(window.selectedCard.iconFile)
                                       : ""

        // Online / Offline badge of the selected device.
        pageDevices.badge.color: window.selOnline ? "#11392F" : "#3A1518"
        pageDevices.badgeText.color: window.selOnline ? "#22C55E" : "#F87171"
        pageDevices.badgeText.text: window.selOnline ? "Online" : "Offline"

        // "Cambia dispositivo" is disabled (dimmed) while an update is running.
        pageUpdate.btnChange.opacity: updater.busy ? 0.4 : 1.0

        // ---- Settings page ----
        // The chip of the selected bitrate is highlighted.
        pageSettings.chip125.color:  window.pendingBitrate === 125  ? "#0E2A52" : "#0A1830"
        pageSettings.chip125.border.color:  window.pendingBitrate === 125  ? "#1E7BFF" : "#2A4570"
        pageSettings.chip250.color:  window.pendingBitrate === 250  ? "#0E2A52" : "#0A1830"
        pageSettings.chip250.border.color:  window.pendingBitrate === 250  ? "#1E7BFF" : "#2A4570"
        pageSettings.chip500.color:  window.pendingBitrate === 500  ? "#0E2A52" : "#0A1830"
        pageSettings.chip500.border.color:  window.pendingBitrate === 500  ? "#1E7BFF" : "#2A4570"
        pageSettings.chip1000.color: window.pendingBitrate === 1000 ? "#0E2A52" : "#0A1830"
        pageSettings.chip1000.border.color: window.pendingBitrate === 1000 ? "#1E7BFF" : "#2A4570"

        // Switch "Scansione dopo l'aggiornamento"
        pageSettings.autoRescanSwitch.color: settings.autoRescan ? "#1E7BFF" : "#2A4570"
        pageSettings.autoRescanKnob.x: settings.autoRescan ? 23 : 3

        // ---- Details page ----
        pageDetails.detailIcon.source: window.hasDetail ? window.iconSrc(window.detail.iconFile) : ""
        pageDetails.hdrName.text: window.hasDetail ? window.detail.deviceName : "-"
        pageDetails.hdrSub.text: window.hasDetail
                                 ? qsTr("Dettagli dispositivo · nodo ") + window.detail.nodeId
                                   + " · " + window.detail.chip
                                 : qsTr("Dispositivo non trovato: fai una nuova scansione")

        // Online / Offline badge
        pageDetails.detailBadge.color: window.detailOnline ? "#11392F" : "#3A1518"
        pageDetails.detailBadgeDot.color: window.detailOnline ? "#22C55E" : "#F87171"
        pageDetails.detailBadgeText.color: window.detailOnline ? "#22C55E" : "#F87171"
        pageDetails.detailBadgeText.text: window.detailOnline ? "Online" : "Offline"

        // Identity: name, node, chip, hardware, firmware and UID are known from
        // the scan; build date and commit come from the DETAILS answer of the board.
        pageDetails.dvName.text: window.hasDetail ? window.detail.deviceName : "-"
        pageDetails.dvNode.text: window.hasDetail ? window.detail.nodeId : "-"
        pageDetails.dvChip.text: window.hasDetail ? window.detail.chip : "-"
        pageDetails.dvHw.text: window.hasDetail ? window.detail.hardware : "-"
        pageDetails.dvFw.text: window.hasDetail ? window.detail.firmware : "-"
        pageDetails.dvUid.text: window.hasDetail ? window.detail.uid : "-"
        pageDetails.dvBuild.text: window.hasBoardData && window.detail.buildDate !== ""
                                  ? window.detail.buildDate : "-"
        pageDetails.dvCommit.text: window.hasBoardData && window.detail.commit !== ""
                                   ? window.detail.commit : "-"

        // State and bus: "last contact" and "frames" are measured by the PC,
        // the other values are sent by the board.
        pageDetails.svLast.text: window.hasDetail
                                 ? window.agoText(window.nowMs - window.detail.lastSeen) : "-"
        pageDetails.svLast.color: window.detailOnline ? "#22C55E" : "#F87171"
        pageDetails.svFrames.text: window.hasDetail
                                   ? window.detail.frames.toLocaleString(Qt.locale(), "f", 0) : "-"
        pageDetails.svUptime.text: window.hasBoardData
                                   ? window.uptimeText(window.detail.uptimeSec) : "-"
        pageDetails.svReset.text: window.hasBoardData
                                  ? window.resetText(window.detail.resetCode) : "-"
        // CAN errors "TX / RX": green when both are 0, orange otherwise.
        pageDetails.svErrors.text: window.hasBoardData
                                   ? window.detail.txErr + " / " + window.detail.rxErr : "-"
        pageDetails.svErrors.color: window.hasBoardData
                                    && (window.detail.txErr > 0 || window.detail.rxErr > 0)
                                    ? "#F5A524" : "#22C55E"
        // -128 means "temperature not available".
        pageDetails.svTemp.text: window.hasBoardData && window.detail.tempC !== -128
                                 ? window.detail.tempC + " °C" : "-"

        // Flash partitions exist only on the ESP32 (the STM32 has a bootloader instead).
        pageDetails.panelPartitions.visible: window.detailIsEsp
        pageDetails.actRollback.visible: window.detailIsEsp

        // ---- Map of the flash: blocks and labels from the data of the board ----
        pageDetails.flashInfo.text: window.mapOk ? window.num("flashMb") + qsTr(" MB · schema OTA")
                                                 : qsTr("schema OTA")
        pageDetails.mapSys.visible: window.mapOk
        pageDetails.mapSys.width: Math.max(8, window.mapX(window.num("p0Addr")) - 16 - 2)

        pageDetails.mapOta0.visible: window.mapOk
        pageDetails.mapOta0.x: window.mapX(window.num("p0Addr"))
        pageDetails.mapOta0.width: window.mapW(window.num("p0Addr"), window.num("p0Size"))
        pageDetails.mapOta0.color: window.slotRunning(0) ? "#1E7BFF" : "#16305A"

        pageDetails.mapOta1.visible: window.mapOk
        pageDetails.mapOta1.x: window.mapX(window.num("p1Addr"))
        pageDetails.mapOta1.width: window.mapW(window.num("p1Addr"), window.num("p1Size"))
        pageDetails.mapOta1.color: window.slotRunning(1) ? "#1E7BFF" : "#16305A"

        pageDetails.mapData.visible: window.mapOk && window.dataUnits > 0
        pageDetails.mapData.x: window.mapX(window.dataStartU)
        pageDetails.mapData.width: window.mapW(window.dataStartU, window.dataUnits)

        pageDetails.mapAppLabel.text: window.mapOk
                                      ? qsTr("App · ") + window.mbText(window.num("p0Size")) + qsTr(" MB ciascuna")
                                      : ""
        pageDetails.mapDataLabel.text: window.mapOk && window.dataUnits > 0
                                       ? qsTr("Dati · ") + window.mbText(window.dataUnits) + qsTr(" MB")
                                       : ""

        // ---- Flash slot 0 (ota_0): the running one has a blue border and a green tag ----
        pageDetails.slot0Box.color: window.slotRunning(0) ? "#10264A" : "#0E1D36"
        pageDetails.slot0Box.border.color: window.slotRunning(0) ? "#1E7BFF" : "#1B3050"
        pageDetails.p0Tag.color: window.slotRunning(0) ? "#11392F" : "#16305A"
        pageDetails.p0TagText.color: window.slotRunning(0) ? "#22C55E" : "#C9D6EA"
        pageDetails.p0TagText.text: window.slotTagText(0)
        pageDetails.p0Version.text: qsTr("Versione ") + (window.hasBoardData ? window.detail.p0Version : "-")
        pageDetails.p0Addr.text: window.slotAddrText(0)
        pageDetails.p0Bar.width: 264 * window.slotUsedPct(0)      // 264 = full bar width
        pageDetails.p0Bar.color: window.slotRunning(0) ? "#1E7BFF" : "#2A4570"
        pageDetails.p0Used.text: window.slotUsedText(0)

        // ---- Flash slot 1 (ota_1) ----
        pageDetails.slot1Box.color: window.slotRunning(1) ? "#10264A" : "#0E1D36"
        pageDetails.slot1Box.border.color: window.slotRunning(1) ? "#1E7BFF" : "#1B3050"
        pageDetails.p1Tag.color: window.slotRunning(1) ? "#11392F" : "#16305A"
        pageDetails.p1TagText.color: window.slotRunning(1) ? "#22C55E" : "#C9D6EA"
        pageDetails.p1TagText.text: window.slotTagText(1)
        pageDetails.p1Version.text: qsTr("Versione ") + (window.hasBoardData ? window.detail.p1Version : "-")
        pageDetails.p1Addr.text: window.slotAddrText(1)
        pageDetails.p1Bar.width: 264 * window.slotUsedPct(1)
        pageDetails.p1Bar.color: window.slotRunning(1) ? "#1E7BFF" : "#2A4570"
        pageDetails.p1Used.text: window.slotUsedText(1)

        // Note under the slots: where the next update will be written.
        pageDetails.partNote.text: window.hasBoardData
                                   ? qsTr("Il prossimo aggiornamento andrà su ")
                                     + (window.slotRunning(0) ? "ota_1" : "ota_0")
                                   : qsTr("In attesa dei dati dalla scheda...")

        // Buttons are dimmed when they cannot be used now.
        pageDetails.actReboot.opacity: window.actionsEnabled ? 1.0 : 0.4
        pageDetails.actIdentify.opacity: window.actionsEnabled ? 1.0 : 0.4
        pageDetails.actRollback.opacity: window.rollbackPossible ? 1.0 : 0.4
        pageDetails.actBootloader.opacity: 0.4          // STM32 only, not available yet

        // ---- Hover on the action cards ----
        // The mouse areas must report the hover; the cursor becomes a hand
        // only on the cards that can be used now.
        pageDetails.maActUpdate.hoverEnabled: true
        pageDetails.maActUpdate.cursorShape: Qt.PointingHandCursor
        pageDetails.actUpdate.color: window.hoverBg(pageDetails.maActUpdate.containsMouse, true)

        pageDetails.maActReboot.hoverEnabled: true
        pageDetails.maActReboot.cursorShape: window.actionsEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        pageDetails.actReboot.color: window.hoverBg(pageDetails.maActReboot.containsMouse, window.actionsEnabled)

        pageDetails.maActIdentify.hoverEnabled: true
        pageDetails.maActIdentify.cursorShape: window.actionsEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        pageDetails.actIdentify.color: window.hoverBg(pageDetails.maActIdentify.containsMouse, window.actionsEnabled)

        pageDetails.maActRollback.hoverEnabled: true
        pageDetails.maActRollback.cursorShape: window.rollbackPossible ? Qt.PointingHandCursor : Qt.ArrowCursor
        pageDetails.actRollback.color: window.hoverBg(pageDetails.maActRollback.containsMouse, window.rollbackPossible)

        // "Entra in bootloader" is not available yet: no hover, normal cursor.
        pageDetails.maActBootloader.cursorShape: Qt.ArrowCursor

        pageDetails.maActCopyUid.hoverEnabled: true
        pageDetails.maActCopyUid.cursorShape: Qt.PointingHandCursor
        pageDetails.actCopyUid.color: window.hoverBg(pageDetails.maActCopyUid.containsMouse, true)

        // ---- Configuration page: header ----
        pageConfig.cName.text: window.selectedCard ? window.selectedCard.deviceName
                                                   : qsTr("Nessun dispositivo")
        pageConfig.cSub.text: window.selectedCard === null
                              ? qsTr("Seleziona un dispositivo nella pagina Dispositivi")
                              : window.cfgFresh
                                ? qsTr("Configurazione del sensore · nodo ") + window.selectedCard.nodeId
                                : qsTr("Nessun dato dal sensore · nodo ") + window.selectedCard.nodeId
        pageConfig.cBadge.color: window.cfgFresh ? "#11392F" : "#3A1518"
        pageConfig.cBadgeDot.color: window.cfgFresh ? "#22C55E" : "#F87171"
        pageConfig.cBadgeText.color: window.cfgFresh ? "#22C55E" : "#F87171"
        pageConfig.cBadgeText.text: window.cfgFresh ? "Online" : "Offline"

        // Message on the right of the buttons.
        pageConfig.cHint.text: window.cfgDirty ? qsTr("Modifiche non scritte sulla scheda")
                                               : qsTr("Nessuna modifica")
        pageConfig.cHint.color: window.cfgDirty ? "#F5A524" : "#8FA3BF"

        // The buttons are dimmed (and without hover) when the board does not answer.
        pageConfig.btnRead.opacity: window.cfgFresh ? 1.0 : 0.4
        pageConfig.btnWrite.opacity: window.cfgFresh ? 1.0 : 0.4
        pageConfig.btnSave.opacity: window.cfgFresh ? 1.0 : 0.4
        pageConfig.btnFactory.opacity: window.cfgFresh ? 1.0 : 0.4
        pageConfig.btnAddPt.opacity: window.cfgFresh ? 1.0 : 0.4
        pageConfig.btnCapture.opacity: window.cfgFresh ? 1.0 : 0.4
        // Live point of the curve graph: "2,00 V → 20,0 L"
        pageConfig.cCurveInfo.text: (window.cfgFresh && !window.cfgFault && window.cfgSensor.valueX10 >= 0)
        ? (window.cfgSensor.mv / 1000).toFixed(2).replace(".", ",") + " V → "
          + window.fmtVal(window.cfgSensor.valueX10) + " " + window.sensorUnit
        : "-"

        // ---- Configuration page: live strip ----
        pageConfig.cValue.text: (!window.cfgFresh || window.cfgFault || window.cfgSensor.valueX10 < 0)
                                ? "- - -"
                                : window.fmtVal(window.cfgSensor.valueX10) + " " + window.sensorUnit
        pageConfig.cValue.color: window.cfgFault ? "#F87171"
                                 : window.cfgFresh ? "#FFFFFF" : "#8FA3BF"
        pageConfig.cVolt.text: window.cfgFresh
                               ? (window.cfgSensor.mv / 1000).toFixed(2).replace(".", ",") + " V"
                               : "-"
        pageConfig.cState.text: window.cfgStateText()
        pageConfig.cState.color: window.cfgFault ? "#F87171"
                                 : window.cfgFresh ? "#22C55E" : "#8FA3BF"

        // ---- Configuration page: tabs ----
        pageConfig.tabLbl0.color: window.cfgTab === 0 ? "#FFFFFF" : "#8FA3BF"
        pageConfig.tabLbl1.color: window.cfgTab === 1 ? "#FFFFFF" : "#8FA3BF"
        pageConfig.tabLbl2.color: window.cfgTab === 2 ? "#FFFFFF" : "#8FA3BF"
        pageConfig.tabLbl3.color: window.cfgTab === 3 ? "#FFFFFF" : "#8FA3BF"
        pageConfig.tabLine.x: 28 + window.cfgTab * 118           // the tabs are 118 px apart
        pageConfig.tabSensor.visible: window.cfgTab === 0

        // ---- Configuration page: Alarms tab ----
        pageConfig.tabAlarm.visible: window.cfgTab === 2

        // ---- Configuration page: Display tab ----
        pageConfig.tabDisplay.visible: window.cfgTab === 1
        pageConfig.dec0.color: window.cfgDecimals === 0 ? "#1E7BFF" : "transparent"
        pageConfig.dec1.color: window.cfgDecimals === 1 ? "#1E7BFF" : "transparent"
        pageConfig.dec2.color: window.cfgDecimals === 2 ? "#1E7BFF" : "transparent"
        pageConfig.fm0.color: window.cfgFaultMode === 0 ? "#1E7BFF" : "transparent"
        pageConfig.fm1.color: window.cfgFaultMode === 1 ? "#1E7BFF" : "transparent"
        pageConfig.cPrevName.text: pageConfig.inName.text
        // Preview: the real value with the chosen decimals and unit; on fault "- - -"
        // or the last valid value, as chosen.
        pageConfig.cPrevValue.text:
            (window.cfgFresh && !window.cfgFault && window.cfgSensor.valueX10 >= 0)
                ? window.fmtVal(window.cfgSensor.valueX10) + " " + pageConfig.inUnit.text
                : (window.cfgFresh && window.cfgFault && window.cfgFaultMode === 1 && window.cfgLastX10 >= 0)
                    ? window.fmtVal(window.cfgLastX10) + " " + pageConfig.inUnit.text
                    : "- - -"

        pageConfig.tabCan.visible: window.cfgTab === 3
        pageConfig.btnNode.opacity: window.cfgFresh ? 1.0 : 0.4
        pageConfig.cNodeIds.text: window.cfgNode < 0 ? "" :
            window.hexId(0x500 + window.cfgNode) + qsTr("   valore del sensore, ogni ") + window.cfgPeriod + qsTr(" ms\n")
          + window.hexId(0x600 + window.cfgNode) + qsTr("   comandi ricevuti dalla scheda\n")
          + window.hexId(0x680 + window.cfgNode) + qsTr("   risposte e heartbeat\n")
          + window.hexId(0x700 + window.cfgNode) + qsTr("   dati del file durante l'aggiornamento")

        // Live frame of the sensor (right panel of the CAN tab)
        pageConfig.cFrameId.text: window.cfgNode < 0 ? "" : window.hexId(0x500 + window.cfgNode) + qsTr("   DLC 6")
        pageConfig.cFrameHex.text: window.cfgFresh ? window.frameHex() : "-- --  -- --  --  --"
        pageConfig.cFrameInfo.text: window.cfgFresh ? window.frameInfo() : qsTr("Nessun frame ricevuto")


        // Scrollable list: one card for each device found by the bus scan.
        Flickable {
            parent: mainScreen.pageDevices.cardsArea
            anchors.fill: parent
            clip: true                                   // hide cards outside the area
            contentWidth: width
            contentHeight: can.devices.count * 144       // card height 130 + 14 of spacing
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { }

            Repeater {
                model: can.devices

                delegate: DeviceCard {
                    id: card

                    x: 0
                    y: index * 144

                    deviceName: model.deviceName
                    chip:       model.chip
                    nodeId:     model.nodeId
                    firmware:   model.firmware
                    hardware:   model.hardware
                    uid:        model.uid
                    online:     model.online
                    iconFile:   model.iconFile
                    selected:   window.selectedCard === card

                    // The first card that appears is selected automatically.
                    // After an update, the card of the same board is selected again.
                    Component.onCompleted: {
                        if (window.selectedCard === null
                                || (window.preferredNode !== "" && card.nodeId === window.preferredNode))
                            window.selectedCard = card
                        window.addHover(card.cardMouse)      // HOVER: hover on the card
                    }

                    // Clicking the card selects it.
                    Connections {
                        target: card.cardMouse
                        function onClicked() { window.selectedCard = card }
                    }
                }
            }
        }

        // ---- Toast: small message at the top right, it disappears after 3 seconds ----
        Rectangle {
            id: toast

            property string message: ""
            property bool error: false

            z: 100                                   // above everything else
            width: 340
            height: Math.max(52, toastText.implicitHeight + 28)   // grows with long texts
            x: window.width - width - 20             // 20 px from the right edge
            y: 20                                    // 20 px from the top
            radius: 10
            color: error ? "#3A1518" : "#11392F"     // background: dark red / dark green
            border.color: error ? "#F87171" : "#22C55E"
            border.width: 1

            opacity: 0                               // hidden until showToast() is called
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }   // fade in / out

            Text {
                id: toastText
                anchors.fill: parent
                anchors.margins: 14
                text: toast.message
                color: toast.error ? "#F87171" : "#22C55E"
                font.pixelSize: 14
                font.bold: true
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }

        Timer {
            id: toastTimer
            interval: 3000                           // time the message stays visible (ms)
            onTriggered: toast.opacity = 0
        }

        // Scrollable log: one row for each line of the update log.
        // It follows the newest line; if you scroll up to read, it stops
        // following until you come back to the end.
        ListView {
            id: logView
            parent: mainScreen.pageUpdate.logArea
            anchors.fill: parent
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // One row for each line of the log (only the number is used as model:
            // the list does not restart from the top when a new line arrives).
            model: updater.logLines.length

            property bool follow: true
            onMovingChanged: if (!moving) follow = atYEnd

            ScrollBar.vertical: ScrollBar { }

            // When a new line is written, go to the end (if we are following).
            Connections {
                target: updater
                function onLogChanged() {
                    if (logView.follow)
                        Qt.callLater(function() { logView.positionViewAtEnd() })
                }
            }

            delegate: Item {
                id: row
                width: logView.width - 14           // space for the scroll bar
                height: 18

                // A line is "HH:mm:ss  text".
                readonly property string line: updater.logLines[index] || ""
                readonly property string msg: line.substring(10)

                // Time
                Text {
                    x: 6
                    width: 66
                    height: parent.height
                    color: "#8FA3BF"
                    text: row.line.substring(0, 8)
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }

                // Message: monospace font, so the columns of the frames line up.
                // Colors: red = error, orange = warning, blue = sent by the PC,
                // purple = sent by the board, white = everything else.
                Text {
                    x: 78
                    width: parent.width - 84
                    height: parent.height
                    color: row.msg.startsWith("ERROR") ? "#F87171"
                         : row.msg.startsWith("WARN")  ? "#F5A524"
                         : row.msg.startsWith("PC >>") ? "#2BB6E8"
                         : row.msg.startsWith("<< BOARD") ? "#C084FC"
                         : "#FFFFFF"
                    text: row.msg
                    font.family: "Consolas"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Settings page: list of the known nodes, one row for each node.
        // It works like the list of device cards: a Flickable (scrollable area)
        // placed inside the "nodesArea" box drawn in Design Studio.
        Flickable {
            id: nodesFlick
            parent: mainScreen.pageSettings.nodesArea     // put it inside the box
            anchors.fill: parent
            clip: true                                    // hide rows outside the box
            contentWidth: width
            contentHeight: nodes.count * 60               // row 52 + 8 of spacing
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { }

            Repeater {
                model: nodes          // creates one row for each node of the list

                delegate: Rectangle {
                    x: 0
                    y: index * 60                         // rows one under the other
                    width: nodesFlick.width - 14          // space for the scroll bar
                    height: 52
                    radius: 10
                    // The row being edited is highlighted (same colors as the device cards).
                    color: window.editRow === index ? "#10264A" : "#0E1D36"
                    border.color: window.editRow === index ? "#1E7BFF" : "#1B3050"
                    border.width: 1

                    // Icon box
                    Rectangle {
                        x: 12
                        y: 9
                        width: 34
                        height: 34
                        radius: 10
                        color: "#16305A"

                        Image {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            source: window.iconSrc(model.iconFile)   // built-in or user icon
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(40, 40)
                        }
                    }

                    // Name of the node
                    Text {
                        x: 58
                        width: parent.width - 140
                        height: parent.height
                        text: model.nodeName
                        color: "#FFFFFF"
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight             // "..." if the name is too long
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Node ID on the right (blue if the row is selected)
                    Text {
                        x: parent.width - 72
                        width: 60
                        height: parent.height
                        text: model.idText
                        color: window.editRow === index ? "#2BB6E8" : "#8FA3BF"
                        font.family: "Consolas"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Clicking the row loads it in the editor.
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        onClicked: window.pickNode(index)
                        Component.onCompleted: window.addHover(rowMouse)    // HOVER
                    }
                }
            }
        }

        // Settings page: icon picker. A row of squares that scrolls sideways:
        // drag it with the mouse or use the mouse wheel.
        Flickable {
            id: iconFlick
            parent: mainScreen.pageSettings.iconArea      // put it inside the "iconArea" box
            anchors.fill: parent
            clip: true
            contentWidth: window.allIcons.length * 48     // 40 of icon + 8 of spacing
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            // The mouse wheel moves the picker sideways (a Flickable alone
            // would only move up and down).
            WheelHandler {
                onWheel: (event) => {
                    iconFlick.contentX = Math.max(0, Math.min(
                        iconFlick.contentWidth - iconFlick.width,
                        iconFlick.contentX - event.angleDelta.y))
                }
            }

            Repeater {
                model: window.allIcons

                delegate: Rectangle {
                    x: index * 48
                    width: 40
                    height: 40
                    radius: 10
                    // The chosen icon has a blue border (2 px), the others a gray one.
                    color: window.editIcon === modelData ? "#16305A" : "#0E1D36"
                    border.color: window.editIcon === modelData ? "#1E7BFF" : "#1B3050"
                    border.width: window.editIcon === modelData ? 2 : 1

                    Image {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: window.iconSrc(modelData)    // modelData = icon name or URL
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(44, 44)          // loads the file at a good quality
                    }

                    // Clicking the square chooses the icon (it is saved with "Salva").
                    MouseArea {
                        id: iconMouse
                        anchors.fill: parent
                        onClicked: window.editIcon = modelData
                        Component.onCompleted: window.addHover(iconMouse)   // HOVER
                    }
                }
            }
        }
    }

    /* ---------- Devices page actions ---------- */

    // Clicking "Scansiona" sends the SCAN command on the bus.
    Connections {
        target: mainScreen.pageDevices.maScan
        function onClicked() { can.scan() }
    }

    // Clicking "Aggiorna Firmware" opens the Update page.
    Connections {
        target: mainScreen.pageDevices.maUpdateFw
        function onClicked() { mainScreen.state = "update" }
    }

    /* ---------- Update page actions ---------- */

    // File chooser for the firmware .bin
    FileDialog {
        id: fileDialog
        title: qsTr("Seleziona file firmware")
        nameFilters: ["Firmware (*.bin)", "All files (*)"]
        onAccepted: updater.loadFile(selectedFile)
    }

    // "Sfoglia file..." opens the file chooser.
    Connections {
        target: mainScreen.pageUpdate.maBrowse
        function onClicked() { fileDialog.open() }
    }

    // Drag & drop of a .bin file onto the drop zone.
    DropArea {
        parent: mainScreen.pageUpdate.dropZone
        anchors.fill: parent
        onDropped: (drop) => {
            if (drop.hasUrls)
                updater.loadFile(drop.urls[0])
        }
    }

    // Start button: starts the update, or cancels it while it is running.
    Connections {
        target: mainScreen.pageUpdate.maStart
        function onClicked() {
            if (updater.busy)
                updater.abort()
            else if (window.canStart)
                updater.start(parseInt(window.selectedCard.nodeId))   // "0x45" -> 69
        }
    }

    // "Cambia dispositivo" goes back to the Devices page (not allowed during an update).
    Connections {
        target: mainScreen.pageUpdate.maChange
        function onClicked() {
            if (!updater.busy)
                mainScreen.state = ""      // "" = base state = Devices page
        }
    }

    // When the update ends: show a message (green = ok, red = failed or cancelled).
    // After a successful update the board restarts: wait a few seconds,
    // then scan the bus again so the card shows the new firmware version.
    // The rescan can be turned off in the Settings page.
    Connections {
        target: updater
        function onFinished(ok) {
            if (ok)
                window.showToast(qsTr("Aggiornamento completato, riavvio della scheda..."))
            else
                window.showToast(qsTr("Aggiornamento non riuscito"), true)

            if (ok && settings.autoRescan) {
                window.preferredNode = window.selectedCard ? window.selectedCard.nodeId : ""
                // Remember which board and which version, to check them later.
                window.updatedNode = window.selectedCard ? parseInt(window.selectedCard.nodeId) : -1
                window.updatedVersion = updater.fileVersion
                rescanTimer.restart()
            }
        }
    }
    Timer {
        id: rescanTimer
        interval: 4000
        onTriggered: {
            can.scan()
            versionCheckTimer.restart()      // check the result 3 seconds after the scan
        }
    }

    // Checks which firmware the board runs after an update: compares the
    // version of the file with the version the board reports after restarting.
    // If they differ, the new firmware did not start and the board went back
    // to the previous one (automatic rollback).
    Timer {
        id: versionCheckTimer
        interval: 3000
        onTriggered: {
            if (window.updatedNode < 0)
                return
            var info = can.devices.infoFor(window.updatedNode)     // data of the board
            window.updatedNode = -1                                // check only once

            if (info.nodeId === undefined || info.online !== true) {
                window.showToast(qsTr("La scheda non risponde dopo il riavvio"), true)
                return
            }
            // Keep only digits and dots, so "v1.0.3" and "1.0.3" are equal.
            var running  = String(info.firmware).replace(/[^0-9.]/g, "")
            var expected = window.updatedVersion.replace(/[^0-9.]/g, "")

            if (running === expected)
                window.showToast(qsTr("Scheda aggiornata: firmware ") + info.firmware)
            else
                window.showToast(qsTr("Il nuovo firmware non è partito: la scheda è tornata alla versione ")
                                 + info.firmware, true)
        }
    }

    /* ---------- Settings page actions ---------- */

    // Click on a speed: only selects it (saved with "Applica").
    Connections {
        target: mainScreen.pageSettings.maChip125
        function onClicked() { window.pendingBitrate = 125 }
    }
    Connections {
        target: mainScreen.pageSettings.maChip250
        function onClicked() { window.pendingBitrate = 250 }
    }
    Connections {
        target: mainScreen.pageSettings.maChip500
        function onClicked() { window.pendingBitrate = 500 }
    }
    Connections {
        target: mainScreen.pageSettings.maChip1000
        function onClicked() { window.pendingBitrate = 1000 }
    }

    // The switch turns the automatic rescan on and off.
    Connections {
        target: mainScreen.pageSettings.maAutoRescan
        function onClicked() { settings.autoRescan = !settings.autoRescan }
    }

    // "Applica e riconnetti": saves the bitrate and reconnects the adapter with it.
    Connections {
        target: mainScreen.pageSettings.maApply
        function onClicked() {
            // Not while a firmware update is running.
            if (updater.busy) {
                window.showToast(qsTr("Impossibile durante un aggiornamento"), true)
                return
            }
            settings.bitrate = window.pendingBitrate
            can.applyBitrate(settings.bitrate)
            window.showToast(qsTr("Bitrate applicato: ") + settings.bitrate + " kbit/s")
        }
    }

    // "Salva": adds the node (if the editor was empty) or changes the selected one.
    // C++ checks name and ID and returns the text of the error, or "" if all is fine.
    Connections {
        target: mainScreen.pageSettings.maSave
        function onClicked() {
            var wasNew = (window.editRow < 0)          // was it a new node?
            var err = nodes.save(window.editRow,
                                 mainScreen.pageSettings.nameInput.text,
                                 mainScreen.pageSettings.idInput.text,
                                 window.editIcon)
            if (err !== "") {
                window.showToast(err, true)            // red message with the error
            } else {
                window.showToast(qsTr("Nodo salvato"))
                if (wasNew)
                    window.pickNode(nodes.count - 1)   // select the new node (the last one)
            }
        }
    }

    // "+ Aggiungi nodo": empties the editor. The node is created with "Salva".
    Connections {
        target: mainScreen.pageSettings.maAdd
        function onClicked() { window.pickNode(-1) }
    }

    // "Elimina": removes the node selected in the list.
    Connections {
        target: mainScreen.pageSettings.maDelete
        function onClicked() {
            if (window.editRow < 0)
                return                                 // nothing selected
            nodes.remove(window.editRow)
            window.showToast(qsTr("Nodo eliminato"))
            window.pickNode(nodes.count > 0 ? 0 : -1)  // show the first node, or empty editor
        }
    }

    // "Apri cartella icone": opens the folder in Windows Explorer.
    Connections {
        target: mainScreen.pageSettings.maOpenIcons
        function onClicked() { nodes.openIconFolder() }
    }

    // While the Settings page is open, check the icon folder every 2 seconds,
    // so an icon copied in the folder appears in the picker without restarting.
    Timer {
        interval: 2000
        repeat: true
        running: mainScreen.state === "settings"
        onTriggered: window.refreshIcons()
    }

    /* ---------- Details page actions ---------- */

    // "Dettagli" in the Devices page: opens the details of the selected card.
    Connections {
        target: mainScreen.pageDevices.maDetails
        function onClicked() {
            if (window.selectedCard === null)
                return
            window.detailNodeId = parseInt(window.selectedCard.nodeId)   // "0x45" -> 69
            window.refreshDetail()
            mainScreen.state = "details"
        }
    }

    // "Dispositivi" button of the Details page: back to the Devices page.
    Connections {
        target: mainScreen.pageDetails.maDetailsBack
        function onClicked() { mainScreen.state = "" }
    }

    // "Aggiorna firmware": opens the Update page (it uses the selected card).
    Connections {
        target: mainScreen.pageDetails.maActUpdate
        function onClicked() { mainScreen.state = "update" }
    }

    // Invisible text field used only to copy a text to the clipboard.
    TextEdit {
        id: clipHelper
        visible: false
    }

    // "Copia UID": puts the UID in the clipboard and shows a message.
    Connections {
        target: mainScreen.pageDetails.maActCopyUid
        function onClicked() {
            if (!window.hasDetail)
                return
            clipHelper.text = window.detail.uid
            clipHelper.selectAll()
            clipHelper.copy()
            window.showToast(qsTr("UID copiato: ") + window.detail.uid)
        }
    }

    // "Riavvia scheda": sends the REBOOT command.
    Connections {
        target: mainScreen.pageDetails.maActReboot
        function onClicked() {
            if (window.actionsEnabled)
                can.sendAction(window.detailNodeId, window.cmdReboot)
        }
    }

    // "Identifica scheda": the board blinks its display for 4 seconds.
    Connections {
        target: mainScreen.pageDetails.maActIdentify
        function onClicked() {
            if (window.actionsEnabled)
                can.sendAction(window.detailNodeId, window.cmdIdentify)
        }
    }

    // "Versione precedente": asks for a confirmation first, because the firmware changes.
    Connections {
        target: mainScreen.pageDetails.maActRollback
        function onClicked() {
            if (window.rollbackPossible)
                rollbackDialog.open()
        }
    }
    MessageDialog {
        id: rollbackDialog
        title: qsTr("Versione precedente")
        text: qsTr("La scheda si riavvierà con la versione %1 dell'altra partizione. Continuare?")
              .arg(window.hasBoardData ? window.detail["p" + window.otherSlot() + "Version"] : "-")
        buttons: MessageDialog.Yes | MessageDialog.No
        onAccepted: can.sendAction(window.detailNodeId, window.cmdRollback)
    }

    // Answers of the board: new parameters -> fill the fields; result of a command -> message.
    Connections {
        target: can
        function onSensorParamsChanged(nodeId) {
            if (nodeId !== window.cfgNode)
                return
            window.fillCfgFields()
            window.cfgDirty = false
        }
        function onParamAck(nodeId, cmd, param, status) {
            if (nodeId !== window.cfgNode)
                return
            if (status !== 0) {
                window.cfgNodeTarget = -1
                window.showToast(qsTr("La scheda ha rifiutato il comando (codice ") + status + ")", true)
                return
            }
            if (cmd === 0x32) {
                window.showToast(qsTr("Salvato nella memoria della scheda"))
            } else if (cmd === 0x33) {
                window.showToast(qsTr("Valori di fabbrica ripristinati"))
            } else if (cmd === 0x31 && param === 0x04 && window.cfgNodeTarget >= 0) {
                // The board saved the new node ID: restart it so the ID becomes active,
                // then scan again and select the board with the new ID.
                window.showToast(qsTr("Nodo salvato: la scheda si riavvia come ")
                                 + window.hexId(window.cfgNodeTarget))
                window.preferredNode = window.hexId(window.cfgNodeTarget)
                can.sendAction(window.cfgNode, window.cmdReboot)
                rescanTimer.restart()
                window.cfgNodeTarget = -1
            }
        }
    }

    // While the Details page is open the data is read again twice a second
    // (this only reads what the PC already has in memory).
    Timer {
        interval: 500
        repeat: true
        running: mainScreen.state === "details"
        onTriggered: window.refreshDetail()
    }

    // While the Details page is open, ask the board for its details:
    // right away when the page opens, then every 2 seconds.
    // Not during a firmware update: the bus is busy with the file.
    Timer {
        interval: 2000
        repeat: true
        running: mainScreen.state === "details"
        triggeredOnStart: true
        onTriggered: {
            if (!updater.busy && window.detailNodeId >= 0)
                can.requestDetails(window.detailNodeId)
        }
    }

    /* ---------- Configuration page actions ---------- */

    // The selected board changed while the page is open: read the new one.
    onCfgNodeChanged: {
        window.cfgDirty = false
        if (mainScreen.state === "config" && cfgNode >= 0)
            can.readSensorParams(cfgNode)
    }

    // The sensor values are read again 5 times per second while the page is open.
    Timer {
        interval: 200
        repeat: true
        running: mainScreen.state === "config"
        triggeredOnStart: true
        onTriggered: {
            window.cfgSensor = window.cfgNode >= 0 ? can.sensorInfo(window.cfgNode) : ({})
            // Remember the last valid value (used by "show the last valid value").
            if (window.cfgFresh && !window.cfgFault && window.cfgSensor.valueX10 >= 0)
                window.cfgLastX10 = window.cfgSensor.valueX10
            curveCanvas.requestPaint()          // draw the curve graph again
        }
    }

    // When the page opens, read all the parameters from the board
    // (the answers fill the input fields).
    Connections {
        target: mainScreen
        function onStateChanged() {
            if (mainScreen.state === "config" && window.cfgNode >= 0) {
                window.cfgDirty = false
                can.readSensorParams(window.cfgNode)
            }
        }
    }

    // Click on one of the five tabs.
    Instantiator {
        model: [mainScreen.pageConfig.maTab0, mainScreen.pageConfig.maTab1,
                mainScreen.pageConfig.maTab2, mainScreen.pageConfig.maTab3]
        delegate: Connections {
            target: modelData
            function onClicked() { window.cfgTab = index }
        }
    }

    // Editing a field marks the page as "not written".
    Instantiator  {
        model: [mainScreen.pageConfig.inFilter, mainScreen.pageConfig.inLow,
                mainScreen.pageConfig.inHigh, mainScreen.pageConfig.inName,
                mainScreen.pageConfig.inUnit, mainScreen.pageConfig.inStartup,
            mainScreen.pageConfig.inPeriod]
        delegate: Connections {
            target: modelData
            function onTextEdited() { window.cfgDirty = true }
        }
    }

    // Answers of the board: new parameters -> fill the fields; result of a command -> message.
    Connections {
        target: can
        function onSensorParamsChanged(nodeId) {
            if (nodeId !== window.cfgNode)
                return
            window.fillCfgFields()
            window.cfgDirty = false
        }
        function onParamAck(nodeId, cmd, param, status) {
            if (nodeId !== window.cfgNode)
                return
            if (status !== 0) {
                window.showToast(qsTr("La scheda ha rifiutato il comando (codice ") + status + ")", true)
                return
            }
            if (cmd === 0x32)
                window.showToast(qsTr("Salvato nella memoria della scheda"))
            else if (cmd === 0x33)
                window.showToast(qsTr("Valori di fabbrica ripristinati"))
        }
    }

    // "Leggi dalla scheda": reads everything again (the edits not written are lost).
    Connections {
        target: mainScreen.pageConfig.maRead
        function onClicked() {
            if (!window.cfgFresh)
                return
            window.cfgDirty = false
            can.readSensorParams(window.cfgNode)
        }
    }

    // "Scrivi sulla scheda": checks the fields and the table, then sends them.
    // The board uses them at once but does not save them (that is "Salva in NVS").
    // If anything is wrong NOTHING is sent.
    Connections {
        target: mainScreen.pageConfig.maWrite
        function onClicked() {
            if (!window.cfgFresh)
                return
            var pg = mainScreen.pageConfig
            var f  = parseInt(pg.inFilter.text)
            var lo = parseInt(pg.inLow.text)
            var hi = parseInt(pg.inHigh.text)

            if (isNaN(f) || f < 50 || f > 10000) {
                window.showToast(qsTr("Filtro: da 50 a 10000 ms"), true)
                return
            }
            if (isNaN(lo) || isNaN(hi) || lo < 0 || hi > 5000 || lo >= hi) {
                window.showToast(qsTr("Limiti di guasto non validi (basso minore di alto, massimo 5000 mV)"), true)
                return
            }

            // ---- calibration table: read the rows and check them ----
            var pts = []
            for (var i = 0; i < cfgRows.count; ++i) {
                var r  = cfgRows.get(i)
                var mv = parseInt(r.mvtxt)
                var v  = parseFloat(String(r.vtxt).replace(",", "."))   // "32,5" -> 32.5
                if (isNaN(mv) || mv < 0 || mv > 5000) {
                    window.showToast(qsTr("Punto ") + (i + 1) + qsTr(": la tensione deve essere da 0 a 5000 mV"), true)
                    return
                }
                if (isNaN(v) || v < 0 || v > 3276) {
                    window.showToast(qsTr("Punto ") + (i + 1) + qsTr(": il valore deve essere da 0 a 3276"), true)
                    return
                }
                pts.push({ mv: mv, valueX10: Math.round(v * 10) })
            }
            if (pts.length < 2 || pts.length > 16) {
                window.showToast(qsTr("La tabella deve avere da 2 a 16 punti"), true)
                return
            }
            pts.sort(function(a, b) { return a.mv - b.mv })             // lowest voltage first
            for (var k = 1; k < pts.length; ++k) {
                if (pts[k].mv === pts[k - 1].mv) {
                    window.showToast(qsTr("Due punti hanno la stessa tensione: ") + pts[k].mv + " mV", true)
                    return
                }
            }
            // ---- display texts: name (max 12 bytes), unit (max 4 bytes, UTF-8) ----
            var utf8Len = function(s) {            // length in bytes: "°" = 2, "L" = 1
                var n = 0
                for (var u = 0; u < s.length; ++u) {
                    var cc = s.charCodeAt(u)
                    n += cc < 0x80 ? 1 : (cc < 0x800 ? 2 : 3)
                }
                return n
            }
            if (utf8Len(pg.inName.text) > 12) {
                window.showToast(qsTr("Nome troppo lungo (massimo 12 byte)"), true)
                return
            }
            if (utf8Len(pg.inUnit.text) > 4) {
                window.showToast(qsTr("Unità troppo lunga (massimo 4 byte)"), true)
                return
            }
            // ---- alarms: read the rows and check them ----
            var alr = []
            for (var q = 0; q < 3; ++q) {
                var ar  = alarmRows.get(q)
                var thr = parseFloat(String(ar.thr).replace(",", "."))
                var hys = parseFloat(String(ar.hys).replace(",", "."))
                var del = parseFloat(String(ar.del).replace(",", "."))
                if (isNaN(thr) || thr < 0 || thr > 3276) {
                    window.showToast(ar.name + qsTr(": la soglia deve essere da 0 a 3276"), true)
                    return
                }
                if (isNaN(hys) || hys < 0 || hys > 3276) {
                    window.showToast(ar.name + qsTr(": l'isteresi deve essere da 0 a 3276"), true)
                    return
                }
                if (isNaN(del) || del < 0 || del > 60) {
                    window.showToast(ar.name + qsTr(": il ritardo deve essere da 0 a 60 secondi"), true)
                    return
                }
                alr.push({ en: ar.en ? 1 : 0, thr: Math.round(thr * 10),
                           hys: Math.round(hys * 10), del: Math.round(del * 10) })
            }
            if (alr[0].en && alr[1].en && alr[1].thr >= alr[0].thr) {
                window.showToast(qsTr("La soglia di riserva critica deve essere più bassa di quella di riserva"), true)
                return
            }
            var startS = parseInt(pg.inStartup.text)
            if (isNaN(startS) || startS < 0 || startS > 60) {
                window.showToast(qsTr("Ignora gli allarmi: da 0 a 60 secondi"), true)
                return
            }
            var per = parseInt(pg.inPeriod.text)
            if (isNaN(per) || per < 20 || per > 500) {
                window.showToast(qsTr("Periodo del frame: da 20 a 500 ms"), true)
                return
            }
            // ---- all fine: send ----
            can.writeParam(window.cfgNode, 0x01, 0, f)             // filter
            // The board refuses a "low" above its current "high" (and the other way
            // round): the limit that moves away from the other one goes first.
            var cur = can.sensorParams(window.cfgNode)
            if (lo >= cur.highMv) {
                can.writeParam(window.cfgNode, 0x03, 0, hi)
                can.writeParam(window.cfgNode, 0x02, 0, lo)
            } else {
                can.writeParam(window.cfgNode, 0x02, 0, lo)
                can.writeParam(window.cfgNode, 0x03, 0, hi)
            }
            can.writeTable(window.cfgNode, pts)
            can.writeText(window.cfgNode, 0x05, pg.inName.text)    // name
            can.writeText(window.cfgNode, 0x06, pg.inUnit.text)    // unit
            can.writeParam(window.cfgNode, 0x07, 0, window.cfgDecimals)
            can.writeParam(window.cfgNode, 0x08, 0, window.cfgFaultMode)
            for (var s2 = 0; s2 < 3; ++s2) {                          // alarms
                can.writeParam(window.cfgNode, 0x20, s2, alr[s2].en)
                can.writeParam(window.cfgNode, 0x21, s2, alr[s2].thr)
                can.writeParam(window.cfgNode, 0x22, s2, alr[s2].hys)
                can.writeParam(window.cfgNode, 0x23, s2, alr[s2].del)
            }
            can.writeParam(window.cfgNode, 0x24, 0, startS)
            can.writeParam(window.cfgNode, 0x09, 0, per)               // period of the sensor frame
            window.cfgDirty = false
            window.showToast(qsTr("Valori scritti sulla scheda (non ancora salvati)"))
        }
    }

    // "Salva in NVS".
    Connections {
        target: mainScreen.pageConfig.maSave
        function onClicked() {
            if (window.cfgFresh)
                can.saveParams(window.cfgNode)
        }
    }

    // "Fabbrica": asks for a confirmation first, because the saved values are erased.
    Connections {
        target: mainScreen.pageConfig.maFactory
        function onClicked() {
            if (window.cfgFresh)
                factoryDialog.open()
        }
    }
    MessageDialog {
        id: factoryDialog
        title: qsTr("Valori di fabbrica")
        text: qsTr("La scheda torna ai valori di fabbrica e i valori salvati vengono cancellati. Continuare?")
        buttons: MessageDialog.Yes | MessageDialog.No
        onAccepted: can.resetParams(window.cfgNode)
    }
    /* ---------- Configuration page: calibration table ---------- */

    // The rows of the table. Each row has two texts (what the user is typing):
    // "mvtxt" = voltage in mV, "vtxt" = value (e.g. "32,5"). They are checked
    // only when "Scrivi sulla scheda" is clicked.
    ListModel { id: cfgRows }

    // Scrollable list of rows, placed in the "tableArea" box of the page.
    Flickable {
        id: tableFlick
        parent: mainScreen.pageConfig.tableArea
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: cfgRows.count * 34             // row 30 + 4 of spacing
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar { }

        Repeater {
            model: cfgRows

            delegate: Rectangle {
                id: rowItem
                x: 0
                y: index * 34
                width: tableFlick.width - 14          // space for the scroll bar
                height: 30
                radius: 6
                color: window.cfgSel === index ? "#10264A" : "transparent"
                border.color: window.cfgSel === index ? "#1E7BFF" : "transparent"
                border.width: 1

                // Row number
                Text {
                    x: 4
                    width: 30
                    height: parent.height
                    text: index + 1
                    color: "#8FA3BF"
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                }

                // Voltage (mV)
                Rectangle {
                    x: 40
                    width: 150
                    height: 30
                    radius: 6
                    color: "#0A1830"
                    border.color: "#2A4570"
                    border.width: 1

                    TextInput {
                        x: 8
                        width: 134
                        height: 30
                        text: model.mvtxt
                        color: "#FFFFFF"
                        font.family: "Consolas"
                        font.pixelSize: 14
                        selectByMouse: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        onTextEdited: {
                            cfgRows.setProperty(index, "mvtxt", text)
                            window.cfgDirty = true
                        }
                        onActiveFocusChanged: if (activeFocus) window.cfgSel = index
                    }
                }

                // Value (liters)
                Rectangle {
                    x: 240
                    width: 150
                    height: 30
                    radius: 6
                    color: "#0A1830"
                    border.color: "#2A4570"
                    border.width: 1

                    TextInput {
                        x: 8
                        width: 134
                        height: 30
                        text: model.vtxt
                        color: "#FFFFFF"
                        font.family: "Consolas"
                        font.pixelSize: 14
                        selectByMouse: true
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        onTextEdited: {
                            cfgRows.setProperty(index, "vtxt", text)
                            window.cfgDirty = true
                        }
                        onActiveFocusChanged: if (activeFocus) window.cfgSel = index
                    }
                }

                // Delete this row
                Text {
                    x: 408
                    width: 30
                    height: parent.height
                    text: "✕"
                    color: "#F87171"
                    font.pixelSize: 15
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        id: delMouse
                        anchors.fill: parent
                        onClicked: {
                            var row = index
                            // Delete after this click is finished (the row disappears).
                            Qt.callLater(function() {
                                cfgRows.remove(row)
                                window.cfgSel = -1
                                window.cfgDirty = true
                            })
                        }
                        Component.onCompleted: window.addHover(delMouse)    // HOVER
                    }
                }
            }
        }
    }

    // "+ Aggiungi punto": adds a row at the end (maximum 16, like the board).
    // If the board is online, the new row starts with the voltage of this moment.
    Connections {
        target: mainScreen.pageConfig.maAddPt
        function onClicked() {
            if (!window.cfgFresh)
                return
            if (cfgRows.count >= 16) {
                window.showToast(qsTr("Massimo 16 punti"), true)
                return
            }
            cfgRows.append({ mvtxt: String(window.cfgSensor.mv), vtxt: "" })
            window.cfgSel = cfgRows.count - 1
            window.cfgDirty = true
            tableFlick.contentY = Math.max(0, tableFlick.contentHeight - tableFlick.height)  // show it
        }
    }

    // "Cattura tensione attuale": copies the voltage of this moment into the selected row.
    Connections {
        target: mainScreen.pageConfig.maCapture
        function onClicked() {
            if (!window.cfgFresh)
                return
            if (window.cfgSel < 0 || window.cfgSel >= cfgRows.count) {
                window.showToast(qsTr("Prima clicca su una riga della tabella"), true)
                return
            }
            cfgRows.setProperty(window.cfgSel, "mvtxt", String(window.cfgSensor.mv))
            window.cfgDirty = true
        }
    }
    /* ---------- Configuration page: curve graph ---------- */

    // The graph is drawn by code on a Canvas (a sheet where we draw lines and dots).
    // It is drawn again 5 times per second by the timer of the live values, and at
    // once while a point is dragged. It follows the rows of the table, the fault
    // limits and the live point.
    // The points can be moved with the mouse: left/right changes the voltage,
    // up/down changes the value. The rows of the table are changed too.
    Canvas {
        id: curveCanvas
        parent: mainScreen.pageConfig.curveArea
        anchors.fill: parent

        // Plot rectangle, in pixels inside the canvas (room left and below for the labels).
        readonly property real plotL: 40
        readonly property real plotR: width - 10
        readonly property real plotT: 12
        readonly property real plotB: height - 26

        // Row being dragged (-1 = none) and row under the mouse (-1 = none).
        property int dragIdx: -1
        property int hoverIdx: -1
        // Vertical scale kept fixed while dragging (0 = not dragging), so the
        // graph does not change size under the mouse.
        property real dragVmax: 0

        // Reads the rows of the table as numbers, lowest voltage first.
        // "idx" is the number of the row in the table. Rows with a text that is
        // not a number yet are skipped.
        function readPoints() {
            var pts = []
            for (var i = 0; i < cfgRows.count; ++i) {
                var r  = cfgRows.get(i)
                var mv = parseInt(r.mvtxt)
                var v  = parseFloat(String(r.vtxt).replace(",", "."))
                if (!isNaN(mv) && !isNaN(v))
                    pts.push({ idx: i, mv: mv, v: v })
            }
            pts.sort(function(a, b) { return a.mv - b.mv })
            return pts
        }

        // Top of the vertical scale: the highest value of the table, in steps of 10
        // (never below 10). It stays fixed while a point is dragged.
        function scaleMax(pts) {
            if (dragVmax > 0)
                return dragVmax
            var m = 10
            for (var i = 0; i < pts.length; ++i)
                m = Math.max(m, pts[i].v)
            return Math.ceil(m / 10) * 10
        }

        // Voltage (mV) and value -> pixel.
        function xOf(mv) {
            return plotL + Math.max(0, Math.min(5000, mv)) / 5000 * (plotR - plotL)
        }
        function yOf(v, vmax) {
            return plotB - Math.max(0, Math.min(vmax, v)) / vmax * (plotB - plotT)
        }

        // Number of the row whose point is within 12 px of the mouse (-1 = none).
        function nearest(mx, my) {
            var pts = readPoints()
            var vmax = scaleMax(pts)
            var best = -1
            var bestD = 144                              // 12 px, squared
            for (var i = 0; i < pts.length; ++i) {
                var dx = xOf(pts[i].mv) - mx
                var dy = yOf(pts[i].v, vmax) - my
                var d = dx * dx + dy * dy
                if (d < bestD) {
                    bestD = d
                    best = pts[i].idx
                }
            }
            return best
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var L = plotL, R = plotR, T = plotT, B = plotB
            var pts = readPoints()
            var vmax = scaleMax(pts)

            // Red zones: below the low limit and above the high limit, with the word "guasto".
            var pg = mainScreen.pageConfig
            var lo = parseInt(pg.inLow.text)
            var hi = parseInt(pg.inHigh.text)
            var hasLo = !isNaN(lo) && lo > 0
            var hasHi = !isNaN(hi) && hi < 5000
            ctx.fillStyle = "rgba(239, 83, 80, 0.12)"
            if (hasLo)
                ctx.fillRect(L, T, xOf(lo) - L, B - T)
            if (hasHi)
                ctx.fillRect(xOf(hi), T, R - xOf(hi), B - T)
            ctx.font = "10px sans-serif"
            ctx.fillStyle = "#FF8A80"
            if (hasLo) {
                ctx.textAlign = "left"
                ctx.fillText("guasto", L + 4, T + 12)
            }
            if (hasHi) {
                ctx.textAlign = "right"
                ctx.fillText("guasto", R - 4, T + 12)
            }

            // Vertical grid lines every volt, with the labels.
            ctx.font = "11px Consolas"
            ctx.textAlign = "center"
            for (var g = 0; g <= 5; ++g) {
                var gx = xOf(g * 1000)
                ctx.strokeStyle = "#16294A"
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(gx, T)
                ctx.lineTo(gx, B)
                ctx.stroke()
                ctx.fillStyle = "#8FA3BF"
                ctx.fillText(g + " V", gx, B + 16)
            }

            // Axes and the labels of the vertical axis (0 and the maximum).
            ctx.strokeStyle = "#2A4570"
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(L, T)
            ctx.lineTo(L, B)
            ctx.lineTo(R, B)
            ctx.stroke()
            ctx.textAlign = "right"
            ctx.fillStyle = "#8FA3BF"
            ctx.fillText(String(vmax), L - 5, T + 4)
            ctx.fillText("0", L - 5, B + 4)

            // The curve: a line through the points of the table.
            if (pts.length >= 2) {
                ctx.strokeStyle = "#2BB6E8"
                ctx.lineWidth = 3
                ctx.lineJoin = "round"
                ctx.beginPath()
                ctx.moveTo(xOf(pts[0].mv), yOf(pts[0].v, vmax))
                for (var k = 1; k < pts.length; ++k)
                    ctx.lineTo(xOf(pts[k].mv), yOf(pts[k].v, vmax))
                ctx.stroke()
            }

            // A circle on every point. The selected row is filled, the one under the
            // mouse (or being dragged) is bigger.
            ctx.lineWidth = 2
            for (var d = 0; d < pts.length; ++d) {
                var active = (pts[d].idx === dragIdx || pts[d].idx === hoverIdx)
                ctx.beginPath()
                ctx.arc(xOf(pts[d].mv), yOf(pts[d].v, vmax), active ? 6 : 4, 0, 2 * Math.PI)
                ctx.fillStyle = (pts[d].idx === window.cfgSel) ? "#2BB6E8" : "#0A1830"
                ctx.fill()
                ctx.strokeStyle = "#2BB6E8"
                ctx.stroke()
            }

            // The point of this moment: DASHED vertical line + dot on the curve.
            // The line is made of small pieces (4 px drawn, 4 px empty), because it
            // works in every version of Qt. Red line (no dot) if the sensor is in fault.
            if (window.cfgFresh) {
                var lx = xOf(window.cfgSensor.mv)
                ctx.lineWidth = 1.5
                ctx.strokeStyle = window.cfgFault ? "#F87171" : "#F5B544"
                ctx.beginPath()
                for (var y = T; y < B; y += 8) {
                    ctx.moveTo(lx, y)
                    ctx.lineTo(lx, Math.min(y + 4, B))
                }
                ctx.stroke()
                if (!window.cfgFault && window.cfgSensor.valueX10 >= 0) {
                    ctx.beginPath()
                    ctx.arc(lx, yOf(window.cfgSensor.valueX10 / 10, vmax), 6, 0, 2 * Math.PI)
                    ctx.fillStyle = "#F5B544"
                    ctx.fill()
                }
            }
        }

        // Moving the points with the mouse.
        MouseArea {
            id: curveMouse
            anchors.fill: parent
            // "hoverEnabled: true" also tells the global hover code of this file that
            // this area has its own hover: it does not add the light blue veil on it.
            hoverEnabled: true
            cursorShape: (curveCanvas.dragIdx >= 0 || curveCanvas.hoverIdx >= 0)
                         ? Qt.SizeAllCursor : Qt.ArrowCursor

            // Click: take the point under the mouse (if any) and select its row.
            onPressed: (mouse) => {
                var i = curveCanvas.nearest(mouse.x, mouse.y)
                curveCanvas.dragIdx = i
                if (i >= 0) {
                    window.cfgSel = i
                    // Fix the vertical scale for the whole drag.
                    curveCanvas.dragVmax = curveCanvas.scaleMax(curveCanvas.readPoints())
                }
                curveCanvas.requestPaint()
            }

            onPositionChanged: (mouse) => {
                if (pressed && curveCanvas.dragIdx >= 0) {
                    // Mouse position -> voltage (steps of 10 mV) and value (steps of 0.1).
                    var vmax = curveCanvas.dragVmax
                    var mv = Math.round((mouse.x - curveCanvas.plotL)
                                        / (curveCanvas.plotR - curveCanvas.plotL) * 500) * 10
                    mv = Math.max(0, Math.min(5000, mv))
                    var v10 = Math.round((curveCanvas.plotB - mouse.y)
                                         / (curveCanvas.plotB - curveCanvas.plotT) * vmax * 10)
                    v10 = Math.max(0, Math.min(vmax * 10, v10))

                    // Write the new numbers in the row: the table follows the mouse.
                    cfgRows.setProperty(curveCanvas.dragIdx, "mvtxt", String(mv))
                    cfgRows.setProperty(curveCanvas.dragIdx, "vtxt", window.fmtX10(v10))
                    window.cfgDirty = true
                    curveCanvas.requestPaint()
                } else {
                    // Not dragging: only check if the mouse is over a point.
                    var h = curveCanvas.nearest(mouse.x, mouse.y)
                    if (h !== curveCanvas.hoverIdx) {
                        curveCanvas.hoverIdx = h
                        curveCanvas.requestPaint()
                    }
                }
            }

            // Mouse released: the point stays where it is, the scale is free again.
            onReleased: {
                curveCanvas.dragIdx = -1
                curveCanvas.dragVmax = 0
                curveCanvas.requestPaint()
            }

            onExited: {
                curveCanvas.hoverIdx = -1
                curveCanvas.requestPaint()
            }
        }
    }
    /* ---------- Configuration page: node ID ---------- */

    // "Cambia nodo e riavvia": checks the number, then asks for a confirmation.
    Connections {
        target: mainScreen.pageConfig.maNode
        function onClicked() {
            if (!window.cfgFresh)
                return
            // The text is always read as hexadecimal: "46" and "0x46" are the same.
            var id = parseInt(mainScreen.pageConfig.inNode.text, 16)
            if (isNaN(id) || id < 1 || id > 0x7F) {
                window.showToast(qsTr("Nodo: da 0x01 a 0x7F"), true)
                return
            }
            if (id === window.cfgNode) {
                window.showToast(qsTr("È già il nodo di questa scheda"), true)
                return
            }
            if (can.devices.infoFor(id).nodeId !== undefined) {
                window.showToast(qsTr("Sul bus c'è già una scheda con il nodo ") + window.hexId(id), true)
                return
            }
            nodeDialog.newId = id
            nodeDialog.open()
        }
    }
    MessageDialog {
        id: nodeDialog
        property int newId: -1
        title: qsTr("Cambia nodo")
        text: qsTr("La scheda passa dal nodo %1 al nodo %2 e si riavvia. Continuare?")
              .arg(window.hexId(window.cfgNode)).arg(window.hexId(newId))
        buttons: MessageDialog.Yes | MessageDialog.No
        onAccepted: {
            window.cfgNodeTarget = newId
            can.writeParam(window.cfgNode, 0x04, 0, newId)      // saved at once by the board
        }
    }
    /* ---------- Configuration page: Display tab ---------- */

    // Decimals: 0, 1 or 2.
    Instantiator {
        model: [mainScreen.pageConfig.maDec0, mainScreen.pageConfig.maDec1,
                mainScreen.pageConfig.maDec2]
        delegate: Connections {
            target: modelData
            function onClicked() {
                window.cfgDecimals = index
                window.cfgDirty = true
            }
        }
    }

    // On fault: 0 = "- - -" blinking, 1 = last valid value.
    Instantiator  {
        model: [mainScreen.pageConfig.maFm0, mainScreen.pageConfig.maFm1]
        delegate: Connections {
            target: modelData
            function onClicked() {
                window.cfgFaultMode = index
                window.cfgDirty = true
            }
        }
    }
    /* ---------- Configuration page: Alarms tab ---------- */

    // One text field of an alarm row (right aligned number). It tells the page what
    // the user typed with the signal "edited"; the page checks the text only on "Scrivi".
    component AlarmField: Rectangle {
        id: af
        property alias text: inp.text
        signal edited(string t)
        width: 90
        height: 34
        radius: 6
        color: "#0A1830"
        border.color: "#2A4570"
        border.width: 1

        TextInput {
            id: inp
            x: 8
            width: 74
            height: 34
            color: "#FFFFFF"
            font.family: "Consolas"
            font.pixelSize: 14
            selectByMouse: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            onTextEdited: af.edited(text)
        }
    }

    // The three alarms (what the user sees; checked when "Scrivi sulla scheda" is clicked).
    // The first values are the factory ones of the firmware.
    // en = switched on, thr = threshold, hys = hysteresis, del = delay in seconds.
    ListModel {
        id: alarmRows
        ListElement { name: "Riserva";         sub: "scatta sotto la soglia";                 en: true;  thr: "12,0"; hys: "1,0"; del: "2,0" }
        ListElement { name: "Riserva critica"; sub: "scatta sotto la soglia (più bassa)";     en: true;  thr: "6,0";  hys: "1,0"; del: "2,0" }
        ListElement { name: "Valore alto";     sub: "scatta sopra la soglia";                 en: false; thr: "60,0"; hys: "1,0"; del: "2,0" }
    }

    // The rows, placed in the "alarmArea" box of the page.
    Item {
        parent: mainScreen.pageConfig.alarmArea
        anchors.fill: parent

        Repeater {
            model: alarmRows

            delegate: Rectangle {
                id: alRow
                // The bit of this alarm in the flags of the sensor frame (live state).
                readonly property int bit: index === 0 ? 0x02 : (index === 1 ? 0x08 : 0x04)
                readonly property bool inAlarm: window.cfgFresh && ((window.cfgSensor.flags & bit) !== 0)

                x: 0
                y: index * 62
                width: 912
                height: 56
                radius: 8
                color: "#0A1830"
                border.color: inAlarm ? "#EF5350" : "#1B3050"
                border.width: 1

                // On / off switch
                Rectangle {
                    x: 10
                    y: 16
                    width: 44
                    height: 24
                    radius: 12
                    color: model.en ? "#1E7BFF" : "#2A4570"

                    Rectangle {
                        x: model.en ? 22 : 2
                        y: 2
                        width: 20
                        height: 20
                        radius: 10
                        color: "#FFFFFF"
                    }
                    MouseArea {
                        id: togMouse
                        anchors.fill: parent
                        onClicked: {
                            alarmRows.setProperty(index, "en", !model.en)
                            window.cfgDirty = true
                        }
                        Component.onCompleted: window.addHover(togMouse)    // HOVER
                    }
                }

                // Name and short description
                Text {
                    x: 68
                    y: 8
                    width: 220
                    height: 20
                    text: model.name
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    x: 68
                    y: 30
                    width: 224
                    height: 18
                    text: model.sub
                    color: "#8FA3BF"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                // Threshold, hysteresis (in the unit of the sensor) and delay (seconds)
                AlarmField {
                    x: 300
                    y: 11
                    text: model.thr
                    onEdited: function(t) { alarmRows.setProperty(index, "thr", t); window.cfgDirty = true }
                }
                Text {
                    x: 396
                    y: 0
                    width: 44
                    height: 56
                    text: window.sensorUnit
                    color: "#8FA3BF"
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                }
                AlarmField {
                    x: 450
                    y: 11
                    text: model.hys
                    onEdited: function(t) { alarmRows.setProperty(index, "hys", t); window.cfgDirty = true }
                }
                Text {
                    x: 546
                    y: 0
                    width: 44
                    height: 56
                    text: window.sensorUnit
                    color: "#8FA3BF"
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                }
                AlarmField {
                    x: 600
                    y: 11
                    text: model.del
                    onEdited: function(t) { alarmRows.setProperty(index, "del", t); window.cfgDirty = true }
                }
                Text {
                    x: 696
                    y: 0
                    width: 30
                    height: 56
                    text: "s"
                    color: "#8FA3BF"
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                }

                // Live state, from the flags of the sensor frame.
                // With the sensor in fault the alarms are off, but "OK" would be wrong:
                // we do not know the level, so it says "sensore in guasto".
                Rectangle {
                    x: 740
                    y: 14
                    width: 160
                    height: 28
                    radius: 8
                    color: !window.cfgFresh ? "#12274A"
                           : (window.cfgFault ? "#4A3410"
                              : (alRow.inAlarm ? "#7F1D1D"
                                 : (model.en ? "#0F3D2A" : "#12274A")))

                    Text {
                        anchors.fill: parent
                        text: !window.cfgFresh ? "—"
                              : (window.cfgFault ? qsTr("sensore in guasto")
                                 : (!model.en ? qsTr("disattivato")
                                    : (alRow.inAlarm ? qsTr("IN ALLARME") : qsTr("OK"))))
                        color: !window.cfgFresh ? "#8FA3BF"
                               : (window.cfgFault ? "#F5A524"
                                  : (alRow.inAlarm ? "#FCA5A5"
                                     : (model.en ? "#4ADE80" : "#8FA3BF")))
                        font.pixelSize: 13
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
