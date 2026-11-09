

/*
This is a UI file (.ui.qml) that is intended to be edited in Qt Design Studio only.
It is supposed to be strictly declarative and only uses a subset of QML. If you edit
this file manually, you might introduce QML code that is not supported by Qt Design Studio.
Check out https://doc.qt.io/qtcreator/creator-quick-ui-forms.html for details on .ui.qml files.
*/
import QtQuick


/*
 * Details page of a device (1000 x 700). Same style as the other pages.
 * Layout:  header | Identity + Flash partitions | State and bus + Actions
 * App.qml fills the values; here there is only the design and the aliases.
 */
Rectangle {
    id: root
    width: 1000
    height: 700
    color: "#071226"

    // ---- header ----
    property alias detailIcon: detailIcon
    property alias hdrName: hdrName
    property alias hdrSub: hdrSub
    property alias detailBadge: detailBadge
    property alias detailBadgeDot: detailBadgeDot
    property alias detailBadgeText: detailBadgeText
    property alias maDetailsBack: maDetailsBack

    // ---- identity values ----
    property alias dvName: dvName
    property alias dvNode: dvNode
    property alias dvChip: dvChip
    property alias dvHw: dvHw
    property alias dvFw: dvFw
    property alias dvBuild: dvBuild
    property alias dvCommit: dvCommit
    property alias dvUid: dvUid

    // ---- state and bus values ----
    property alias svLast: svLast
    property alias svFrames: svFrames
    property alias svUptime: svUptime
    property alias svReset: svReset
    property alias svErrors: svErrors
    property alias svTemp: svTemp

    // ---- flash partitions (ESP32 only) ----
    property alias panelPartitions: panelPartitions
    property alias slot0Box: slot0Box
    property alias p0Tag: p0Tag
    property alias p0TagText: p0TagText
    property alias p0Version: p0Version
    property alias p0Addr: p0Addr
    property alias p0Bar: p0Bar
    property alias p0Used: p0Used
    property alias slot1Box: slot1Box
    property alias p1Tag: p1Tag
    property alias p1TagText: p1TagText
    property alias p1Version: p1Version
    property alias p1Addr: p1Addr
    property alias p1Bar: p1Bar
    property alias p1Used: p1Used
    property alias partNote: partNote

    // ---- actions ----
    property alias actUpdate: actUpdate
    property alias actReboot: actReboot
    property alias actIdentify: actIdentify
    property alias actRollback: actRollback
    property alias actBootloader: actBootloader
    property alias actCopyUid: actCopyUid
    property alias maActUpdate: maActUpdate
    property alias maActReboot: maActReboot
    property alias maActIdentify: maActIdentify
    property alias maActRollback: maActRollback
    property alias maActBootloader: maActBootloader
    property alias maActCopyUid: maActCopyUid

    // Blocks the mouse for the pages under this one, so the hand cursor and the
    // clicks of the hidden Devices page do not come through.
    // It must stay the first child: everything below is drawn above it.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
    }

    /* ================= HEADER ================= */
    Rectangle {
        x: 28
        y: 14
        width: 64
        height: 64
        radius: 32
        color: "#0e2a52"

        Image {
            id: detailIcon
            x: 17
            y: 17
            width: 30
            height: 30
            source: "images/ico_cpu.svg"
            fillMode: Image.PreserveAspectFit
        }
    }

    Text {
        id: hdrName
        x: 112
        y: 18
        text: qsTr("Dispositivo")
        color: "#ffffff"
        font.pixelSize: 26
        font.bold: true
    }

    Text {
        id: hdrSub
        x: 112
        y: 54
        text: qsTr("Dettagli dispositivo")
        color: "#c9d6ea"
        font.pixelSize: 14
    }

    Rectangle {
        x: 28
        y: 88
        width: 944
        height: 2
        color: "#1e7bff"
    }

    // Online / Offline badge
    Rectangle {
        id: detailBadge
        x: 748
        y: 24
        width: 90
        height: 32
        radius: 16
        color: "#11392f"

        Rectangle {
            id: detailBadgeDot
            x: 14
            y: 12
            width: 8
            height: 8
            radius: 4
            color: "#22c55e"
        }
        Text {
            id: detailBadgeText
            x: 30
            y: 0
            height: 32
            text: qsTr("Online")
            color: "#22c55e"
            font.pixelSize: 13
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Back to the Devices page
    Rectangle {
        x: 850
        y: 24
        width: 122
        height: 32
        radius: 8
        color: "#0e2a52"
        border.color: "#1e7bff"
        border.width: 1

        Text {
            anchors.fill: parent
            text: qsTr("←  Dispositivi")
            color: "#ffffff"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        MouseArea {
            id: maDetailsBack
            anchors.fill: parent
        }
    }

    /* ================= PANEL: IDENTITY ================= */
    Rectangle {
        id: panelIdentity
        x: 28
        y: 104
        width: 300
        height: 300
        radius: 10
        color: "#0c1b33"
        border.color: "#1b3050"
        border.width: 1

        Rectangle {
            x: 0
            y: 34
            width: 300
            height: 1
            color: "#1b3050"
        }
        Image {
            x: 14
            y: 8
            width: 18
            height: 18
            source: "images/circuit-board-White.svg"
            fillMode: Image.PreserveAspectFit
        }
        Text {
            x: 40
            y: 7
            height: 20
            text: qsTr("Identità")
            color: "#ffffff"
            font.pixelSize: 14
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }

        // Each row: label on the left, value on the right, thin line below.
        // Row i is at y = 42 + i * 31.
        Text {
            x: 16
            y: 42
            width: 120
            height: 31
            text: qsTr("Nome")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: dvName
            x: 120
            y: 42
            width: 164
            height: 31
            text: "-"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 72
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 73
            width: 120
            height: 31
            text: qsTr("ID nodo")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: dvNode
            x: 120
            y: 73
            width: 164
            height: 31
            text: "-"
            color: "#2bb6e8"
            font.family: "Consolas"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 103
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 104
            width: 120
            height: 31
            text: qsTr("Chip")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: dvChip
            x: 120
            y: 104
            width: 164
            height: 31
            text: "-"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 134
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 135
            width: 120
            height: 31
            text: qsTr("Hardware")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: dvHw
            x: 120
            y: 135
            width: 164
            height: 31
            text: "-"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 165
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 166
            width: 120
            height: 31
            text: qsTr("Firmware")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: dvFw
            x: 120
            y: 166
            width: 164
            height: 31
            text: "-"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 196
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 197
            width: 120
            height: 31
            text: qsTr("Compilato il")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: dvBuild
            x: 120
            y: 197
            width: 164
            height: 31
            text: "-"
            color: "#c9d6ea"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 227
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 228
            width: 120
            height: 31
            text: qsTr("Commit")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: dvCommit
            x: 120
            y: 228
            width: 164
            height: 31
            text: "-"
            color: "#c9d6ea"
            font.family: "Consolas"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 258
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 259
            width: 120
            height: 31
            text: qsTr("UID")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: dvUid
            x: 120
            y: 259
            width: 164
            height: 31
            text: "-"
            color: "#ffffff"
            font.family: "Consolas"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    /* ================= PANEL: FLASH PARTITIONS (ESP32) ================= */
    Rectangle {
        id: panelPartitions
        x: 344
        y: 104
        width: 628
        height: 300
        radius: 10
        color: "#0c1b33"
        border.color: "#1b3050"
        border.width: 1

        Rectangle {
            x: 0
            y: 34
            width: 628
            height: 1
            color: "#1b3050"
        }
        Image {
            x: 14
            y: 8
            width: 18
            height: 18
            source: "images/ico_microchip.svg"
            fillMode: Image.PreserveAspectFit
        }
        Text {
            x: 40
            y: 7
            height: 20
            text: qsTr("Partizioni flash")
            color: "#ffffff"
            font.pixelSize: 14
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            x: 400
            y: 7
            width: 214
            height: 20
            text: qsTr("8 MB · schema OTA")
            color: "#8fa3bf"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }

        // Map of the flash: system | ota_0 | ota_1 | data (static drawing)
        Rectangle {
            x: 16
            y: 50
            width: 30
            height: 28
            radius: 4
            color: "#2a4570"
        }
        Rectangle {
            x: 48
            y: 50
            width: 221
            height: 28
            radius: 4
            color: "#1e7bff"
            Text {
                x: 10
                width: 100
                height: 28
                text: "ota_0"
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
        }
        Rectangle {
            x: 271
            y: 50
            width: 221
            height: 28
            radius: 4
            color: "#16305a"
            Text {
                x: 10
                width: 100
                height: 28
                text: "ota_1"
                color: "#c9d6ea"
                font.pixelSize: 12
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
        }
        Rectangle {
            x: 494
            y: 50
            width: 118
            height: 28
            radius: 4
            color: "#0e2a52"
        }

        Text {
            x: 16
            y: 86
            text: qsTr("Sistema · bootloader, nvs")
            color: "#8fa3bf"
            font.pixelSize: 12
        }
        Text {
            x: 190
            y: 86
            text: qsTr("App · 3.0 MB ciascuna")
            color: "#8fa3bf"
            font.pixelSize: 12
        }
        Text {
            x: 350
            y: 86
            text: qsTr("Dati · 1.9 MB")
            color: "#8fa3bf"
            font.pixelSize: 12
        }

        // Slot 0 (ota_0)
        Rectangle {
            id: slot0Box
            x: 16
            y: 116
            width: 292
            height: 124
            radius: 10
            color: "#10264a"
            border.color: "#1e7bff"
            border.width: 1

            Text {
                x: 14
                y: 12
                text: "ota_0"
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
            }
            Rectangle {
                id: p0Tag
                x: 168
                y: 12
                width: 110
                height: 20
                radius: 10
                color: "#11392f"
                Text {
                    id: p0TagText
                    anchors.fill: parent
                    text: qsTr("In esecuzione")
                    color: "#22c55e"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                id: p0Version
                x: 14
                y: 40
                text: qsTr("Versione -")
                color: "#c9d6ea"
                font.pixelSize: 13
            }
            Text {
                id: p0Addr
                x: 14
                y: 62
                text: qsTr("Indirizzo -")
                color: "#8fa3bf"
                font.pixelSize: 12
            }
            Rectangle {
                x: 14
                y: 84
                width: 264
                height: 6
                radius: 3
                color: "#0a1830"
                Rectangle {
                    id: p0Bar
                    width: 0
                    height: 6
                    radius: 3
                    color: "#1e7bff"
                }
            }
            Text {
                id: p0Used
                x: 14
                y: 94
                text: qsTr("Occupata: -")
                color: "#8fa3bf"
                font.pixelSize: 12
            }
        }

        // Slot 1 (ota_1)
        Rectangle {
            id: slot1Box
            x: 320
            y: 116
            width: 292
            height: 124
            radius: 10
            color: "#0e1d36"
            border.color: "#1b3050"
            border.width: 1

            Text {
                x: 14
                y: 12
                text: "ota_1"
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
            }
            Rectangle {
                id: p1Tag
                x: 188
                y: 12
                width: 90
                height: 20
                radius: 10
                color: "#16305a"
                Text {
                    id: p1TagText
                    anchors.fill: parent
                    text: qsTr("Precedente")
                    color: "#c9d6ea"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                id: p1Version
                x: 14
                y: 40
                text: qsTr("Versione -")
                color: "#c9d6ea"
                font.pixelSize: 13
            }
            Text {
                id: p1Addr
                x: 14
                y: 62
                text: qsTr("Indirizzo -")
                color: "#8fa3bf"
                font.pixelSize: 12
            }
            Rectangle {
                x: 14
                y: 84
                width: 264
                height: 6
                radius: 3
                color: "#0a1830"
                Rectangle {
                    id: p1Bar
                    width: 0
                    height: 6
                    radius: 3
                    color: "#2a4570"
                }
            }
            Text {
                id: p1Used
                x: 14
                y: 94
                text: qsTr("Occupata: -")
                color: "#8fa3bf"
                font.pixelSize: 12
            }
        }

        Text {
            id: partNote
            x: 16
            y: 254
            width: 596
            text: qsTr("Dati letti dalla scheda")
            color: "#8fa3bf"
            font.pixelSize: 12
        }
    }

    /* ================= PANEL: STATE AND BUS ================= */
    Rectangle {
        id: panelStats
        x: 28
        y: 420
        width: 300
        height: 260
        radius: 10
        color: "#0c1b33"
        border.color: "#1b3050"
        border.width: 1

        Rectangle {
            x: 0
            y: 34
            width: 300
            height: 1
            color: "#1b3050"
        }
        Image {
            x: 14
            y: 8
            width: 18
            height: 18
            source: "images/ico_zap.svg"
            fillMode: Image.PreserveAspectFit
        }
        Text {
            x: 40
            y: 7
            height: 20
            text: qsTr("Stato e bus")
            color: "#ffffff"
            font.pixelSize: 14
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            x: 16
            y: 42
            width: 140
            height: 31
            text: qsTr("Ultimo contatto")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: svLast
            x: 120
            y: 42
            width: 164
            height: 31
            text: "-"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 72
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 73
            width: 140
            height: 31
            text: qsTr("Frame ricevuti")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: svFrames
            x: 120
            y: 73
            width: 164
            height: 31
            text: "-"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 103
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 104
            width: 140
            height: 31
            text: qsTr("Uptime")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: svUptime
            x: 120
            y: 104
            width: 164
            height: 31
            text: "-"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 134
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 135
            width: 140
            height: 31
            text: qsTr("Motivo ultimo reset")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: svReset
            x: 150
            y: 135
            width: 134
            height: 31
            text: "-"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 165
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 166
            width: 160
            height: 31
            text: qsTr("Errori CAN (TX / RX)")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: svErrors
            x: 170
            y: 166
            width: 114
            height: 31
            text: "-"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            x: 16
            y: 196
            width: 268
            height: 1
            color: "#12274a"
        }

        Text {
            x: 16
            y: 197
            width: 140
            height: 31
            text: qsTr("Temperatura chip")
            color: "#8fa3bf"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            id: svTemp
            x: 120
            y: 197
            width: 164
            height: 31
            text: "-"
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    /* ================= PANEL: ACTIONS ================= */
    Rectangle {
        id: panelActions
        x: 344
        y: 420
        width: 628
        height: 260
        radius: 10
        color: "#0c1b33"
        border.color: "#1b3050"
        border.width: 1

        Rectangle {
            x: 0
            y: 34
            width: 628
            height: 1
            color: "#1b3050"
        }
        Image {
            x: 14
            y: 8
            width: 18
            height: 18
            source: "images/ico_play.svg"
            fillMode: Image.PreserveAspectFit
        }
        Text {
            x: 40
            y: 7
            height: 20
            text: qsTr("Azioni")
            color: "#ffffff"
            font.pixelSize: 14
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }

        // Cards of 190 x 92: columns at x = 16, 219, 422; rows at y = 50, 154.
        Rectangle {
            id: actUpdate
            x: 16
            y: 50
            width: 190
            height: 92
            radius: 10
            color: "#0e1d36"
            border.color: "#1e7bff"
            border.width: 1
            Text {
                x: 14
                y: 12
                text: qsTr("Aggiorna firmware")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                x: 14
                y: 34
                width: 162
                height: 50
                text: qsTr("Apre la pagina Aggiornamento per questa scheda.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            MouseArea {
                id: maActUpdate
                anchors.fill: parent
            }
        }

        Rectangle {
            id: actReboot
            x: 219
            y: 50
            width: 190
            height: 92
            radius: 10
            color: "#0e1d36"
            border.color: "#2a4570"
            border.width: 1
            Text {
                x: 14
                y: 12
                text: qsTr("Riavvia scheda")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                x: 14
                y: 34
                width: 162
                height: 50
                text: qsTr("Riavvio software. La scheda torna online in pochi secondi.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            MouseArea {
                id: maActReboot
                anchors.fill: parent
            }
        }

        Rectangle {
            id: actIdentify
            x: 422
            y: 50
            width: 190
            height: 92
            radius: 10
            color: "#0e1d36"
            border.color: "#2a4570"
            border.width: 1
            Text {
                x: 14
                y: 12
                text: qsTr("Identifica scheda")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                x: 14
                y: 34
                width: 162
                height: 50
                text: qsTr("Fa lampeggiare lo schermo per riconoscerla tra più schede.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            MouseArea {
                id: maActIdentify
                anchors.fill: parent
            }
        }

        Rectangle {
            id: actRollback
            x: 16
            y: 154
            width: 190
            height: 92
            radius: 10
            color: "#0e1d36"
            border.color: "#f5a524"
            border.width: 1
            Text {
                x: 14
                y: 12
                text: qsTr("Versione precedente")
                color: "#f5a524"
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                x: 14
                y: 34
                width: 162
                height: 50
                text: qsTr("Riavvia sull'altra partizione senza riscrivere la flash.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            MouseArea {
                id: maActRollback
                anchors.fill: parent
            }
        }

        Rectangle {
            id: actBootloader
            x: 219
            y: 154
            width: 190
            height: 92
            radius: 10
            color: "#0e1d36"
            border.color: "#1b3050"
            border.width: 1
            Text {
                x: 14
                y: 12
                text: qsTr("Entra in bootloader")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                x: 14
                y: 34
                width: 162
                height: 50
                text: qsTr("Solo STM32. L'ESP32 si aggiorna direttamente via OTA.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            MouseArea {
                id: maActBootloader
                anchors.fill: parent
            }
        }

        Rectangle {
            id: actCopyUid
            x: 422
            y: 154
            width: 190
            height: 92
            radius: 10
            color: "#0e1d36"
            border.color: "#2a4570"
            border.width: 1
            Text {
                x: 14
                y: 12
                text: qsTr("Copia UID")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                x: 14
                y: 34
                width: 162
                height: 50
                text: qsTr("Copia negli appunti l'identificativo della scheda.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            MouseArea {
                id: maActCopyUid
                anchors.fill: parent
            }
        }
    }
}
