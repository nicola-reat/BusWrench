import QtQuick
import QtQuick.Controls
import BusWrench
import QtQuick.Dialogs

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

    /* ---------- Devices and Update pages ---------- */

    // Card selected by the user (null = no selection). The detail panel
    // on the right reads its data from this card.
    property var selectedCard: null
    readonly property bool selOnline: selectedCard ? selectedCard.online : false

    // True when an update can be started: device online, file valid, nothing running.
    readonly property bool canStart: selectedCard !== null && selOnline
                                     && updater.fileLoaded && !updater.busy

    // Node ID (e.g. "0x45") to select again after a new scan. It is set after
    // an update, so the same board is selected again when it comes back.
    property string preferredNode: ""

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
        pageUpdate.statusTitle.text: updater.statusText !== "" ? updater.statusText
                                                               : qsTr("Stato aggiornamento")
        pageUpdate.etaText.text: updater.etaText !== "" ? qsTr("Tempo stimato: ") + updater.etaText
                                                        : qsTr("Tempo stimato: --:--")

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
            height: 52
            x: window.width - width - 20             // 20 px from the right edge
            y: 20                                    // 20 px from the top
            radius: 10
            color: error ? "#3A1518" : "#11392F"
            border.color: error ? "#F87171" : "#22C55E"
            border.width: 1

            opacity: 0                               // hidden until showToast() is called
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }   // fade in / out

            Text {
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
                        anchors.fill: parent
                        onClicked: window.pickNode(index)
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
                        anchors.fill: parent
                        onClicked: window.editIcon = modelData
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

    // After a successful update the board restarts: wait a few seconds,
    // then scan the bus again so the card shows the new firmware version.
    // It can be turned off in the Settings page.
    Connections {
        target: updater
        function onFinished(ok) {
            // Message at the top right: green if ok, red if failed or cancelled.
            if (ok)
                window.showToast(qsTr("Aggiornamento completato"))
            else
                window.showToast(qsTr("Aggiornamento non riuscito"), true)

            // After a successful update, scan again to show the new version.
            if (ok && settings.autoRescan) {
                window.preferredNode = window.selectedCard ? window.selectedCard.nodeId : ""
                rescanTimer.restart()
            }
        }
    }
    Timer {
        id: rescanTimer
        interval: 4000
        onTriggered: can.scan()
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

    // Answer of the board to an action: green message if ok, red if not.
    Connections {
        target: can
        function onActionResult(nodeId, cmd, result) {
            if (nodeId !== window.detailNodeId)
                return
            var ok = (result === 0)

            if (cmd === window.cmdReboot) {
                window.showToast(ok ? qsTr("Riavvio in corso...") : qsTr("Riavvio non riuscito"), !ok)
            } else if (cmd === window.cmdIdentify) {
                window.showToast(ok ? qsTr("La scheda sta lampeggiando")
                                    : qsTr("Identificazione non riuscita"), !ok)
            } else if (cmd === window.cmdRollback) {
                if (ok) {
                    window.showToast(qsTr("Riavvio sulla versione precedente..."))
                    // The firmware version changes: scan again when the board is back.
                    if (settings.autoRescan) {
                        window.preferredNode = window.selectedCard ? window.selectedCard.nodeId : ""
                        rescanTimer.restart()
                    }
                } else {
                    window.showToast(qsTr("Nessuna versione precedente valida"), true)
                }
            }
        }
    }

}
