
/*
This is a UI file (.ui.qml) that is intended to be edited in Qt Design Studio only.
It is supposed to be strictly declarative and only uses a subset of QML. If you edit
this file manually, you might introduce QML code that is not supported by Qt Design Studio.
Check out https://doc.qt.io/qtcreator/creator-quick-ui-forms.html for details on .ui.qml files.
*/
import QtQuick

Rectangle {
    id: root
    width: 1000
    height: 700
    color: "#071226"

    // ---- aliases used by App.qml (export each one with "@" if you want) ----
    property alias adapterText: adapterText
    property alias chip125: chip125
    property alias chip250: chip250
    property alias chip500: chip500
    property alias chip1000: chip1000
    property alias maChip125: maChip125
    property alias maChip250: maChip250
    property alias maChip500: maChip500
    property alias maChip1000: maChip1000
    property alias autoRescanSwitch: autoRescanSwitch
    property alias autoRescanKnob: autoRescanKnob
    property alias maAutoRescan: maAutoRescan
    property alias btnApply: btnApply
    property alias maApply: maApply
    property alias nodesArea: nodesArea
    property alias nameInput: nameInput
    property alias idInput: idInput
    property alias maOpenIcons: maOpenIcons
    property alias iconArea: iconArea
    property alias btnSave: btnSave
    property alias maSave: maSave
    property alias btnAdd: btnAdd
    property alias maAdd: maAdd
    property alias btnDelete: btnDelete
    property alias maDelete: maDelete

    /* ================= HEADER ================= */
    Rectangle {
        id: hdrCircle
        x: 28
        y: 14
        width: 64
        height: 64
        radius: 32
        color: "#0e2a52"

        Image {
            x: 17
            y: 17
            width: 30
            height: 30
            source: "images/ico_cpu.svg"
            fillMode: Image.PreserveAspectFit
        }
    }

    Text {
        x: 112
        y: 18
        text: qsTr("Impostazioni")
        color: "#ffffff"
        font.pixelSize: 26
        font.bold: true
    }

    Text {
        x: 112
        y: 54
        text: qsTr("Configura la comunicazione CAN e i nodi conosciuti della rete")
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

    /* ================= PANEL: CAN CONNECTION ================= */
    Rectangle {
        id: panelCan
        x: 28
        y: 104
        width: 360
        height: 576
        radius: 10
        color: "#0c1b33"
        border.color: "#1b3050"
        border.width: 1

        // Title bar
        Rectangle {
            x: 0
            y: 34
            width: 360
            height: 1
            color: "#1b3050"
        }
        Image {
            x: 14
            y: 7
            width: 20
            height: 20
            source: "images/ico_refresh-cw.svg"
            fillMode: Image.PreserveAspectFit
        }
        Text {
            x: 46
            y: 7
            height: 20
            text: qsTr("Connessione CAN")
            color: "#ffffff"
            font.pixelSize: 14
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }

        // Adapter
        Text {
            x: 16
            y: 52
            text: qsTr("Adattatore")
            color: "#8fa3bf"
            font.pixelSize: 12
        }
        Rectangle {
            x: 16
            y: 72
            width: 328
            height: 40
            radius: 8
            color: "#0a1830"
            border.color: "#2a4570"
            border.width: 1

            Text {
                id: adapterText
                x: 12
                width: 304
                height: 40
                text: qsTr("PCAN-USB  ·  USBBUS1")
                color: "#c9d6ea"
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Bitrate
        Text {
            x: 16
            y: 128
            text: qsTr("Velocità (kbit/s)")
            color: "#8fa3bf"
            font.pixelSize: 12
        }

        Rectangle {
            id: chip125
            x: 16
            y: 148
            width: 73
            height: 40
            radius: 8
            color: "#0a1830"
            border.color: "#2a4570"
            border.width: 1
            Text {
                anchors.fill: parent
                text: "125"
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            MouseArea {
                id: maChip125
                anchors.fill: parent
            }
        }

        Rectangle {
            id: chip250
            x: 101
            y: 148
            width: 73
            height: 40
            radius: 8
            color: "#0a1830"
            border.color: "#2a4570"
            border.width: 1
            Text {
                anchors.fill: parent
                text: "250"
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            MouseArea {
                id: maChip250
                anchors.fill: parent
            }
        }

        // 500 is shown as selected here (default)
        Rectangle {
            id: chip500
            x: 186
            y: 148
            width: 73
            height: 40
            radius: 8
            color: "#0e2a52"
            border.color: "#1e7bff"
            border.width: 1
            Text {
                anchors.fill: parent
                text: "500"
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            MouseArea {
                id: maChip500
                anchors.fill: parent
            }
        }

        Rectangle {
            id: chip1000
            x: 271
            y: 148
            width: 73
            height: 40
            radius: 8
            color: "#0a1830"
            border.color: "#2a4570"
            border.width: 1
            Text {
                anchors.fill: parent
                text: "1000"
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            MouseArea {
                id: maChip1000
                anchors.fill: parent
            }
        }

        // Warning
        Rectangle {
            x: 16
            y: 204
            width: 328
            height: 64
            radius: 8
            color: "#2a1f08"
            border.color: "#f5a524"
            border.width: 1

            Text {
                x: 12
                y: 8
                width: 304
                height: 48
                text: qsTr("Le schede sono fissate a 500 kbit/s. Con un valore diverso non risponderanno alla scansione.")
                color: "#f3d9a4"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Separator
        Rectangle {
            x: 16
            y: 284
            width: 328
            height: 1
            color: "#1b3050"
        }

        // Rescan after update
        Text {
            x: 16
            y: 300
            text: qsTr("Scansione dopo l'aggiornamento")
            color: "#ffffff"
            font.pixelSize: 14
        }
        Text {
            x: 16
            y: 322
            text: qsTr("Aggiorna le card dopo il riavvio")
            color: "#8fa3bf"
            font.pixelSize: 12
        }
        Rectangle {
            id: autoRescanSwitch
            x: 300
            y: 306
            width: 44
            height: 24
            radius: 12
            color: "#1e7bff"

            Rectangle {
                id: autoRescanKnob
                x: 23
                y: 3
                width: 18
                height: 18
                radius: 9
                color: "#ffffff"
            }
            MouseArea {
                id: maAutoRescan
                anchors.fill: parent
            }
        }

        // Apply button
        Rectangle {
            id: btnApply
            x: 16
            y: 514
            width: 328
            height: 42
            radius: 8
            color: "#1e7bff"

            Text {
                anchors.fill: parent
                text: qsTr("Applica e riconnetti")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            MouseArea {
                id: maApply
                anchors.fill: parent
            }
        }
    }

    /* ================= PANEL: KNOWN NODES ================= */
    Rectangle {
        id: panelNodes
        x: 404
        y: 104
        width: 568
        height: 576
        radius: 10
        color: "#0c1b33"
        border.color: "#1b3050"
        border.width: 1

        // Title bar
        Rectangle {
            x: 0
            y: 34
            width: 568
            height: 1
            color: "#1b3050"
        }
        Image {
            x: 14
            y: 7
            width: 20
            height: 20
            source: "images/ico_cpu.svg"
            fillMode: Image.PreserveAspectFit
        }
        Text {
            x: 46
            y: 7
            height: 20
            text: qsTr("Nodi conosciuti")
            color: "#ffffff"
            font.pixelSize: 14
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }

        // Empty area: App.qml puts the list of nodes here (like the device cards).
        Item {
            id: nodesArea
            x: 16
            y: 48
            width: 536
            height: 232
        }

        // Editor of the selected node
        Rectangle {
            x: 16
            y: 292
            width: 536
            height: 234
            radius: 10
            color: "#0a1830"
            border.color: "#2a4570"
            border.width: 1

            Text {
                x: 14
                y: 14
                text: qsTr("Modifica nodo")
                color: "#c9d6ea"
                font.pixelSize: 13
                font.bold: true
            }

            // Name
            Text {
                x: 14
                y: 40
                text: qsTr("Nome")
                color: "#8fa3bf"
                font.pixelSize: 12
            }
            Rectangle {
                x: 14
                y: 58
                width: 386
                height: 36
                radius: 8
                color: "#0c1b33"
                border.color: "#2a4570"
                border.width: 1

                TextInput {
                    id: nameInput
                    x: 12
                    width: 362
                    height: 36
                    text: ""
                    color: "#ffffff"
                    font.pixelSize: 14
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                }
            }

            // Node ID
            Text {
                x: 412
                y: 40
                text: qsTr("ID nodo")
                color: "#8fa3bf"
                font.pixelSize: 12
            }
            Rectangle {
                x: 412
                y: 58
                width: 110
                height: 36
                radius: 8
                color: "#0c1b33"
                border.color: "#2a4570"
                border.width: 1

                TextInput {
                    id: idInput
                    x: 12
                    width: 86
                    height: 36
                    text: ""
                    color: "#2bb6e8"
                    font.family: "Consolas"
                    font.pixelSize: 14
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                }
            }

            // Icon picker: App.qml fills this area with the icons.
            Text {
                x: 14
                y: 106
                text: qsTr("Icona")
                color: "#8fa3bf"
                font.pixelSize: 12
            }
            // Link that opens the folder where the user puts his own icons.
            Text {
                x: 372
                y: 106
                width: 150
                text: qsTr("Apri cartella icone")
                color: "#1e7bff"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight

                MouseArea {
                    id: maOpenIcons
                    anchors.fill: parent
                }
            }
            Item {
                id: iconArea
                x: 14
                y: 126
                width: 508
                height: 40
            }

            // Buttons
            Rectangle {
                id: btnSave
                x: 14
                y: 182
                width: 100
                height: 38
                radius: 8
                color: "#1e7bff"

                Text {
                    anchors.fill: parent
                    text: qsTr("Salva")
                    color: "#ffffff"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maSave
                    anchors.fill: parent
                }
            }

            Rectangle {
                id: btnAdd
                x: 124
                y: 182
                width: 140
                height: 38
                radius: 8
                color: "#0e2a52"
                border.color: "#1e7bff"
                border.width: 1

                Text {
                    anchors.fill: parent
                    text: qsTr("+ Aggiungi nodo")
                    color: "#ffffff"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maAdd
                    anchors.fill: parent
                }
            }

            Rectangle {
                id: btnDelete
                x: 422
                y: 182
                width: 100
                height: 38
                radius: 8
                color: "#3a1518"
                border.color: "#f87171"
                border.width: 1

                Text {
                    anchors.fill: parent
                    text: qsTr("Elimina")
                    color: "#f87171"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maDelete
                    anchors.fill: parent
                }
            }
        }
    }
}
