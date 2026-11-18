/*
This is a UI file (.ui.qml) that is intended to be edited in Qt Design Studio only.
It is supposed to be strictly declarative and only uses a subset of QML. If you edit
this file manually, you might introduce QML code that is not supported by Qt Design Studio.
Check out https://doc.qt.io/qtcreator/creator-quick-ui-forms.html for details on .ui.qml files.
*/
import QtQuick

/*
 * Configuration page (1000 x 700) of a CAN_GAUGE board.
 * Layout:  header + buttons | live strip | tabs | content of the selected tab
 * "Sensor" tab: table (left) + curve graph (right), filter and limits below.
 * Only the design lives here. App.qml fills the values, draws the rows of the
 * table and the curve, switches the tabs and handles the buttons, through the
 * aliases below.
 */
Rectangle {
    id: root
    width: 1000
    height: 700
    color: "#071226"

    // ---- header and buttons ----
    property alias cName: cName
    property alias cSub: cSub
    property alias cBadge: cBadge
    property alias cBadgeDot: cBadgeDot
    property alias cBadgeText: cBadgeText
    property alias cHint: cHint
    property alias btnRead: btnRead
    property alias maRead: maRead
    property alias btnWrite: btnWrite
    property alias maWrite: maWrite
    property alias btnSave: btnSave
    property alias maSave: maSave
    property alias btnFactory: btnFactory
    property alias maFactory: maFactory

    // ---- live strip ----
    property alias cValue: cValue
    property alias cVolt: cVolt
    property alias cState: cState

    // ---- tabs ----
    property alias tabLbl0: tabLbl0
    property alias tabLbl1: tabLbl1
    property alias tabLbl2: tabLbl2
    property alias tabLbl3: tabLbl3
    property alias maTab0: maTab0
    property alias maTab1: maTab1
    property alias maTab2: maTab2
    property alias maTab3: maTab3
    property alias tabLine: tabLine
    property alias tabSensor: tabSensor

    // ---- "Sensor" tab ----
    property alias tableArea: tableArea
    property alias btnAddPt: btnAddPt
    property alias maAddPt: maAddPt
    property alias btnCapture: btnCapture
    property alias maCapture: maCapture
    property alias curveArea: curveArea
    property alias cCurveInfo: cCurveInfo
    property alias inFilter: inFilter
    property alias inLow: inLow
    property alias inHigh: inHigh
    // ---- "CAN" tab ----
    property alias tabCan: tabCan
    property alias inNode: inNode
    property alias btnNode: btnNode
    property alias maNode: maNode
    property alias cNodeIds: cNodeIds
    // ---- "Display" tab ----
    property alias tabDisplay: tabDisplay
    property alias inName: inName
    property alias inUnit: inUnit
    property alias dec0: dec0
    property alias dec1: dec1
    property alias dec2: dec2
    property alias maDec0: maDec0
    property alias maDec1: maDec1
    property alias maDec2: maDec2
    property alias fm0: fm0
    property alias fm1: fm1
    property alias maFm0: maFm0
    property alias maFm1: maFm1
    property alias cPrevName: cPrevName
    property alias cPrevValue: cPrevValue
    // ---- "Allarmi" tab ----
    property alias tabAlarm: tabAlarm
    property alias alarmArea: alarmArea
    property alias inStartup: inStartup
    // ---- "CAN" tab: period and live frame ----
    property alias inPeriod: inPeriod
    property alias cFrameId: cFrameId
    property alias cFrameHex: cFrameHex
    property alias cFrameInfo: cFrameInfo
    /* ================= HEADER ================= */
    Rectangle {
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
            source: "images/ico_microchip.svg"
            fillMode: Image.PreserveAspectFit
        }
    }

    Text {
        id: cName
        x: 112
        y: 18
        text: qsTr("Gauge 0x45")
        color: "#ffffff"
        font.pixelSize: 26
        font.bold: true
    }

    Text {
        id: cSub
        x: 112
        y: 54
        text: qsTr("Configurazione del sensore")
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

    // Online / Offline badge of the board
    Rectangle {
        id: cBadge
        x: 882
        y: 24
        width: 90
        height: 32
        radius: 16
        color: "#11392f"

        Rectangle {
            id: cBadgeDot
            x: 14
            y: 12
            width: 8
            height: 8
            radius: 4
            color: "#22c55e"
        }
        Text {
            id: cBadgeText
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

    /* ================= BUTTONS ================= */
    Rectangle {
        id: btnRead
        x: 28
        y: 102
        width: 170
        height: 36
        radius: 8
        color: "#16305a"

        Text {
            anchors.fill: parent
            text: qsTr("Leggi dalla scheda")
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        MouseArea {
            id: maRead
            anchors.fill: parent
        }
    }

    Rectangle {
        id: btnWrite
        x: 206
        y: 102
        width: 180
        height: 36
        radius: 8
        color: "#1e7bff"

        Text {
            anchors.fill: parent
            text: qsTr("Invia alla scheda")
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        MouseArea {
            id: maWrite
            anchors.fill: parent
        }
    }

    Rectangle {
        id: btnSave
        x: 394
        y: 102
        width: 140
        height: 36
        radius: 8
        color: "#16305a"

        Text {
            anchors.fill: parent
            text: qsTr("Salva sulla scheda")
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        MouseArea {
            id: maSave
            anchors.fill: parent
        }
    }

    // Message on the right: are there changes not written to the board yet?
    Text {
        id: cHint
        x: 548
        y: 102
        width: 270
        height: 36
        text: qsTr("Nessuna modifica")
        color: "#8fa3bf"
        font.pixelSize: 13
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        id: btnFactory
        x: 832
        y: 102
        width: 140
        height: 36
        radius: 8
        color: "#3a1518"

        Text {
            anchors.fill: parent
            text: qsTr("Fabbrica")
            color: "#f87171"
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        MouseArea {
            id: maFactory
            anchors.fill: parent
        }
    }

    /* ================= LIVE STRIP ================= */
    Rectangle {
        x: 28
        y: 150
        width: 300
        height: 64
        radius: 10
        color: "#0c1b33"
        border.color: "#1b3050"
        border.width: 1

        Text {
            x: 14
            y: 6
            text: qsTr("Valore")
            color: "#8fa3bf"
            font.pixelSize: 12
        }
        Text {
            id: cValue
            x: 14
            y: 22
            width: 272
            height: 36
            text: qsTr("32,5 L")
            color: "#ffffff"
            font.pixelSize: 26
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }
    }

    Rectangle {
        x: 344
        y: 150
        width: 300
        height: 64
        radius: 10
        color: "#0c1b33"
        border.color: "#1b3050"
        border.width: 1

        Text {
            x: 14
            y: 6
            text: qsTr("Tensione sensore")
            color: "#8fa3bf"
            font.pixelSize: 12
        }
        Text {
            id: cVolt
            x: 14
            y: 22
            width: 272
            height: 36
            text: qsTr("2,00 V")
            color: "#ffffff"
            font.family: "Consolas"
            font.pixelSize: 26
            font.bold: true
            verticalAlignment: Text.AlignVCenter
        }
    }

    Rectangle {
        x: 660
        y: 150
        width: 312
        height: 64
        radius: 10
        color: "#0c1b33"
        border.color: "#1b3050"
        border.width: 1

        Text {
            x: 14
            y: 6
            text: qsTr("Stato del sensore")
            color: "#8fa3bf"
            font.pixelSize: 12
        }
        Text {
            id: cState
            x: 14
            y: 22
            width: 284
            height: 36
            text: qsTr("OK")
            color: "#22c55e"
            font.pixelSize: 16
            font.bold: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    /* ================= TABS ================= */
    Rectangle {
        x: 28
        y: 268
        width: 944
        height: 1
        color: "#1b3050"
    }

    // Blue line under the selected tab (App.qml moves it).
    Rectangle {
        id: tabLine
        x: 28
        y: 267
        width: 110
        height: 3
        color: "#1e7bff"
    }

    Text {
        id: tabLbl0
        x: 28
        y: 228
        width: 110
        height: 40
        text: qsTr("Sensore")
        color: "#ffffff"
        font.pixelSize: 14
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    Text {
        id: tabLbl1
        x: 146
        y: 228
        width: 110
        height: 40
        text: qsTr("Display")
        color: "#8fa3bf"
        font.pixelSize: 14
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    Text {
        id: tabLbl2
        x: 264
        y: 228
        width: 110
        height: 40
        text: qsTr("Allarmi")
        color: "#8fa3bf"
        font.pixelSize: 14
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    Text {
        id: tabLbl3
        x: 382
        y: 228
        width: 110
        height: 40
        text: qsTr("CAN")
        color: "#8fa3bf"
        font.pixelSize: 14
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: maTab0
        x: 28
        y: 228
        width: 110
        height: 40
    }
    MouseArea {
        id: maTab1
        x: 146
        y: 228
        width: 110
        height: 40
    }
    MouseArea {
        id: maTab2
        x: 264
        y: 228
        width: 110
        height: 40
    }
    MouseArea {
        id: maTab3
        x: 382
        y: 228
        width: 110
        height: 40
    }


    /* ================= TAB "SENSOR" ================= */
    Item {
        id: tabSensor
        x: 28
        y: 282
        width: 944
        height: 406

        // ---- calibration table (left) ----
        Rectangle {
            id: panelTable
            x: 0
            y: 0
            width: 560
            height: 330
            radius: 10
            color: "#0c1b33"
            border.color: "#1b3050"
            border.width: 1

            Rectangle {
                x: 0
                y: 34
                width: 560
                height: 1
                color: "#1b3050"
            }
            Text {
                x: 16
                y: 7
                height: 20
                text: qsTr("Tabella di calibrazione")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                x: 300
                y: 7
                width: 244
                height: 20
                text: qsTr("interpolazione lineare")
                color: "#8fa3bf"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }

            // Column titles (they sit over the boxes of the rows)
            Text {
                x: 20
                y: 42
                width: 30
                height: 22
                text: qsTr("#")
                color: "#8fa3bf"
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                x: 60
                y: 42
                width: 146
                height: 22
                text: qsTr("Tensione (mV)")
                color: "#8fa3bf"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                x: 260
                y: 42
                width: 146
                height: 22
                text: qsTr("Valore")
                color: "#8fa3bf"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }

            // Box where App.qml puts the rows of the table (6 rows are visible).
            Item {
                id: tableArea
                x: 16
                y: 70
                width: 528
                height: 204
            }

            Rectangle {
                id: btnAddPt
                x: 16
                y: 284
                width: 150
                height: 34
                radius: 8
                color: "#16305a"

                Text {
                    anchors.fill: parent
                    text: qsTr("+ Aggiungi punto")
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maAddPt
                    anchors.fill: parent
                }
            }

            Rectangle {
                id: btnCapture
                x: 176
                y: 284
                width: 214
                height: 34
                radius: 8
                color: "#0e2a52"
                border.color: "#1e7bff"
                border.width: 1

                Text {
                    anchors.fill: parent
                    text: qsTr("Cattura tensione attuale")
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maCapture
                    anchors.fill: parent
                }
            }
        }

        // ---- curve of the sensor (right) ----
        Rectangle {
            id: panelCurve
            x: 576
            y: 0
            width: 368
            height: 330
            radius: 10
            color: "#0c1b33"
            border.color: "#1b3050"
            border.width: 1

            Rectangle {
                x: 0
                y: 34
                width: 368
                height: 1
                color: "#1b3050"
            }
            Text {
                x: 16
                y: 7
                height: 20
                text: qsTr("Curva del sensore")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            // Live point: "2,00 V → 20,0 L" (App.qml fills it)
            Text {
                id: cCurveInfo
                x: 150
                y: 7
                width: 202
                height: 20
                text: qsTr("2,00 V → 20,0 L")
                color: "#8fa3bf"
                font.family: "Consolas"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }

            // Box where App.qml draws the graph.
            Item {
                id: curveArea
                x: 8
                y: 42
                width: 352
                height: 280
            }
        }

        // ---- filter and fault limits (bottom row) ----
        Rectangle {
            id: panelFilter
            x: 0
            y: 342
            width: 944
            height: 64
            radius: 10
            color: "#0c1b33"
            border.color: "#1b3050"
            border.width: 1

            // Filter time
            Text {
                x: 16
                y: 6
                width: 292
                height: 16
                text: qsTr("Filtro (media mobile)")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            Rectangle {
                x: 16
                y: 24
                width: 292
                height: 34
                radius: 8
                color: "#0a1830"
                border.color: "#2a4570"
                border.width: 1

                TextInput {
                    id: inFilter
                    x: 10
                    y: 0
                    width: 240
                    height: 34
                    text: qsTr("1000")
                    color: "#ffffff"
                    font.family: "Consolas"
                    font.pixelSize: 14
                    selectByMouse: true
                    inputMethodHints: Qt.ImhDigitsOnly
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    x: 256
                    y: 0
                    width: 28
                    height: 34
                    text: qsTr("ms")
                    color: "#8fa3bf"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Low fault limit
            Text {
                x: 326
                y: 6
                width: 292
                height: 16
                text: qsTr("Guasto se sotto")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            Rectangle {
                x: 326
                y: 24
                width: 292
                height: 34
                radius: 8
                color: "#0a1830"
                border.color: "#2a4570"
                border.width: 1

                TextInput {
                    id: inLow
                    x: 10
                    y: 0
                    width: 240
                    height: 34
                    text: qsTr("250")
                    color: "#ffffff"
                    font.family: "Consolas"
                    font.pixelSize: 14
                    selectByMouse: true
                    inputMethodHints: Qt.ImhDigitsOnly
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    x: 256
                    y: 0
                    width: 28
                    height: 34
                    text: qsTr("mV")
                    color: "#8fa3bf"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // High fault limit
            Text {
                x: 636
                y: 6
                width: 292
                height: 16
                text: qsTr("Guasto se sopra")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            Rectangle {
                x: 636
                y: 24
                width: 292
                height: 34
                radius: 8
                color: "#0a1830"
                border.color: "#2a4570"
                border.width: 1

                TextInput {
                    id: inHigh
                    x: 10
                    y: 0
                    width: 240
                    height: 34
                    text: qsTr("4600")
                    color: "#ffffff"
                    font.family: "Consolas"
                    font.pixelSize: 14
                    selectByMouse: true
                    inputMethodHints: Qt.ImhDigitsOnly
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    x: 256
                    y: 0
                    width: 28
                    height: 34
                    text: qsTr("mV")
                    color: "#8fa3bf"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
    /* ================= TAB "ALLARMI" ================= */
    Item {
        id: tabAlarm
        x: 28
        y: 282
        width: 944
        height: 406
        visible: false

        Rectangle {
            x: 0
            y: 0
            width: 944
            height: 406
            radius: 10
            color: "#0c1b33"
            border.color: "#1b3050"
            border.width: 1

            Rectangle {
                x: 0
                y: 34
                width: 944
                height: 1
                color: "#1b3050"
            }
            Text {
                x: 16
                y: 7
                height: 20
                text: qsTr("Soglie di allarme")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }

            // Column titles (the rows are drawn by App.qml inside "alarmArea")
            Text {
                x: 26
                y: 44
                height: 16
                text: qsTr("Attivo")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                x: 84
                y: 44
                height: 16
                text: qsTr("Allarme")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                x: 316
                y: 44
                height: 16
                text: qsTr("Soglia")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                x: 466
                y: 44
                height: 16
                text: qsTr("Isteresi")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                x: 616
                y: 44
                height: 16
                text: qsTr("Ritardo")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                x: 756
                y: 44
                height: 16
                text: qsTr("Stato")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }

            Item {
                id: alarmArea
                x: 16
                y: 66
                width: 912
                height: 186
            }

            // Ignore the alarms just after power on
            Text {
                x: 16
                y: 268
                width: 210
                height: 34
                text: qsTr("Ignora gli allarmi nei primi")
                color: "#c9d6ea"
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
            }
            Rectangle {
                x: 228
                y: 268
                width: 70
                height: 34
                radius: 6
                color: "#0a1830"
                border.color: "#2a4570"
                border.width: 1

                TextInput {
                    id: inStartup
                    x: 8
                    y: 0
                    width: 54
                    height: 34
                    text: qsTr("5")
                    color: "#ffffff"
                    font.family: "Consolas"
                    font.pixelSize: 14
                    selectByMouse: true
                    inputMethodHints: Qt.ImhDigitsOnly
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                x: 312
                y: 268
                width: 300
                height: 34
                text: qsTr("secondi dopo l'accensione")
                color: "#c9d6ea"
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                x: 16
                y: 316
                width: 912
                height: 80
                text: qsTr("Soglia: il valore oltre il quale scatta l'allarme. Isteresi: quanto il valore deve rientrare prima che l'allarme si spenga (evita lo sfarfallio). Ritardo: per quanti secondi il valore deve restare oltre la soglia prima che scatti. Lo stato a destra è quello vero della scheda; sul display lo mostri con SquareLine.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }

    /* ================= TAB "DISPLAY" ================= */
    Item {
        id: tabDisplay
        x: 28
        y: 282
        width: 944
        height: 406
        visible: false

        // ---- texts and options (left) ----
        Rectangle {
            x: 0
            y: 0
            width: 560
            height: 406
            radius: 10
            color: "#0c1b33"
            border.color: "#1b3050"
            border.width: 1

            Rectangle {
                x: 0
                y: 34
                width: 560
                height: 1
                color: "#1b3050"
            }
            Text {
                x: 16
                y: 7
                height: 20
                text: qsTr("Testi sul display")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }

            // Name
            Text {
                x: 16
                y: 44
                width: 200
                height: 16
                text: qsTr("Nome")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Rectangle {
                x: 16
                y: 62
                width: 300
                height: 34
                radius: 8
                color: "#0a1830"
                border.color: "#2a4570"
                border.width: 1

                TextInput {
                    id: inName
                    x: 10
                    y: 0
                    width: 280
                    height: 34
                    text: qsTr("FUEL")
                    color: "#ffffff"
                    font.family: "Consolas"
                    font.pixelSize: 14
                    selectByMouse: true
                    maximumLength: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                x: 330
                y: 62
                width: 214
                height: 34
                text: qsTr("massimo 12 caratteri")
                color: "#8fa3bf"
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
            }

            // Unit
            Text {
                x: 16
                y: 112
                width: 200
                height: 16
                text: qsTr("Unità")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Rectangle {
                x: 16
                y: 130
                width: 120
                height: 34
                radius: 8
                color: "#0a1830"
                border.color: "#2a4570"
                border.width: 1

                TextInput {
                    id: inUnit
                    x: 10
                    y: 0
                    width: 100
                    height: 34
                    text: qsTr("L")
                    color: "#ffffff"
                    font.family: "Consolas"
                    font.pixelSize: 14
                    selectByMouse: true
                    maximumLength: 4
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                x: 150
                y: 130
                width: 394
                height: 34
                text: qsTr("massimo 4 byte: \"L\", \"bar\", \"°C\" vanno bene")
                color: "#8fa3bf"
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
            }

            // Decimals
            Text {
                x: 16
                y: 180
                width: 200
                height: 16
                text: qsTr("Decimali")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Rectangle {
                x: 16
                y: 198
                width: 240
                height: 36
                radius: 10
                color: "#12274a"
            }
            Rectangle {
                id: dec0
                x: 20
                y: 202
                width: 74
                height: 28
                radius: 8
                color: "#1e7bff"

                Text {
                    anchors.fill: parent
                    text: qsTr("0")
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maDec0
                    anchors.fill: parent
                }
            }
            Rectangle {
                id: dec1
                x: 98
                y: 202
                width: 74
                height: 28
                radius: 8
                color: "transparent"

                Text {
                    anchors.fill: parent
                    text: qsTr("1")
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maDec1
                    anchors.fill: parent
                }
            }
            Rectangle {
                id: dec2
                x: 176
                y: 202
                width: 74
                height: 28
                radius: 8
                color: "transparent"

                Text {
                    anchors.fill: parent
                    text: qsTr("2")
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maDec2
                    anchors.fill: parent
                }
            }

            // On fault show
            Text {
                x: 16
                y: 248
                width: 300
                height: 16
                text: qsTr("In caso di guasto mostra")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Rectangle {
                x: 16
                y: 266
                width: 430
                height: 36
                radius: 10
                color: "#12274a"
            }
            Rectangle {
                id: fm0
                x: 20
                y: 270
                width: 209
                height: 28
                radius: 8
                color: "#1e7bff"

                Text {
                    anchors.fill: parent
                    text: qsTr("\"- - -\" lampeggiante")
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maFm0
                    anchors.fill: parent
                }
            }
            Rectangle {
                id: fm1
                x: 233
                y: 270
                width: 209
                height: 28
                radius: 8
                color: "transparent"

                Text {
                    anchors.fill: parent
                    text: qsTr("Ultimo valore valido")
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maFm1
                    anchors.fill: parent
                }
            }

            Text {
                x: 16
                y: 322
                width: 528
                height: 70
                text: qsTr("Questi testi li legge il firmware dalla memoria della scheda: lo stesso programma va bene per tutti i gauge. Premi \"Invia alla scheda\" per provarli e \"Salva sulla scheda\" per tenerli.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }

        // ---- preview of the texts (right) ----
        Rectangle {
            x: 576
            y: 0
            width: 368
            height: 406
            radius: 10
            color: "#0c1b33"
            border.color: "#1b3050"
            border.width: 1

            Rectangle {
                x: 0
                y: 34
                width: 368
                height: 1
                color: "#1b3050"
            }
            Text {
                x: 16
                y: 7
                height: 20
                text: qsTr("Anteprima dei testi")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: cPrevName
                x: 16
                y: 64
                width: 336
                height: 28
                text: qsTr("FUEL")
                color: "#c9d6ea"
                font.pixelSize: 20
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            Text {
                id: cPrevValue
                x: 16
                y: 104
                width: 336
                height: 80
                text: qsTr("32,5 L")
                color: "#ffffff"
                font.pixelSize: 52
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                minimumPixelSize: 20
            }
            Text {
                x: 16
                y: 210
                width: 336
                height: 80
                text: qsTr("Il valore è quello vero del sensore. L'aspetto del display lo disegni in SquareLine: qui vedi solo come escono i testi.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    /* ================= TAB "CAN" ================= */
    Item {
        id: tabCan
        x: 28
        y: 282
        width: 944
        height: 406
        visible: false

        Rectangle {
            x: 0
            y: 0
            width: 560
            height: 406
            radius: 10
            color: "#0c1b33"
            border.color: "#1b3050"
            border.width: 1

            Rectangle {
                x: 0
                y: 34
                width: 560
                height: 1
                color: "#1b3050"
            }
            Text {
                x: 16
                y: 7
                height: 20
                text: qsTr("Bus e messaggi")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }

            // Node ID
            Text {
                x: 16
                y: 44
                width: 120
                height: 16
                text: qsTr("Nodo")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Rectangle {
                x: 16
                y: 62
                width: 120
                height: 34
                radius: 8
                color: "#0a1830"
                border.color: "#2a4570"
                border.width: 1

                TextInput {
                    id: inNode
                    x: 10
                    y: 0
                    width: 100
                    height: 34
                    text: qsTr("0x45")
                    color: "#ffffff"
                    font.family: "Consolas"
                    font.pixelSize: 14
                    selectByMouse: true
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Rectangle {
                id: btnNode
                x: 152
                y: 62
                width: 230
                height: 34
                radius: 8
                color: "#1e7bff"

                Text {
                    anchors.fill: parent
                    text: qsTr("Cambia nodo e riavvia")
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: maNode
                    anchors.fill: parent
                }
            }
            Text {
                x: 16
                y: 108
                width: 528
                height: 54
                text: qsTr("Il nuovo nodo viene salvato subito nella scheda e vale dopo il riavvio. Cambia il nodo con una sola scheda alla volta sul bus: due schede con lo stesso numero si disturbano.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            // Period of the sensor frame
            Text {
                x: 16
                y: 176
                width: 400
                height: 16
                text: qsTr("Periodo del frame del sensore")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Rectangle {
                x: 16
                y: 194
                width: 120
                height: 34
                radius: 8
                color: "#0a1830"
                border.color: "#2a4570"
                border.width: 1

                TextInput {
                    id: inPeriod
                    x: 10
                    y: 0
                    width: 100
                    height: 34
                    text: qsTr("100")
                    color: "#ffffff"
                    font.family: "Consolas"
                    font.pixelSize: 14
                    selectByMouse: true
                    inputMethodHints: Qt.ImhDigitsOnly
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                x: 150
                y: 194
                width: 394
                height: 34
                text: qsTr("ms (da 20 a 500)")
                color: "#8fa3bf"
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                x: 16
                y: 238
                width: 528
                height: 46
                text: qsTr("Ogni quanti millisecondi la scheda manda il valore sul bus. 100 va bene per quasi tutto: meno ms vuol dire più traffico sul bus.")
                color: "#8fa3bf"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            // IDs used by this node (BusWrench fills the text)
            Rectangle {
                x: 16
                y: 292
                width: 528
                height: 1
                color: "#1b3050"
            }
            Text {
                x: 16
                y: 300
                width: 528
                height: 18
                text: qsTr("ID usati da questo nodo (si calcolano dal numero del nodo)")
                color: "#8fa3bf"
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                id: cNodeIds
                x: 16
                y: 326
                width: 528
                height: 76
                text: qsTr("0x545   valore del sensore, ogni 100 ms\n0x645   comandi ricevuti dalla scheda\n0x6C5   risposte e heartbeat\n0x745   dati del file durante l'aggiornamento")
                color: "#c9d6ea"
                font.family: "Consolas"
                font.pixelSize: 12
                lineHeight: 1.4
            }
        }
        // ---- live sensor frame (right) ----
        Rectangle {
            x: 576
            y: 0
            width: 368
            height: 406
            radius: 10
            color: "#0c1b33"
            border.color: "#1b3050"
            border.width: 1

            Rectangle {
                x: 0
                y: 34
                width: 368
                height: 1
                color: "#1b3050"
            }
            Text {
                x: 16
                y: 7
                height: 20
                text: qsTr("Frame del sensore (dal vivo)")
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: cFrameId
                x: 16
                y: 46
                width: 336
                height: 20
                text: qsTr("0x545   DLC 6")
                color: "#8fa3bf"
                font.family: "Consolas"
                font.pixelSize: 13
            }
            Text {
                id: cFrameHex
                x: 16
                y: 70
                width: 336
                height: 34
                text: qsTr("00 C8  07 D0  00  2A")
                color: "#ffffff"
                font.family: "Consolas"
                font.pixelSize: 22
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: cFrameInfo
                x: 16
                y: 116
                width: 336
                height: 280
                text: qsTr("Nessun frame ricevuto")
                color: "#c9d6ea"
                font.family: "Consolas"
                font.pixelSize: 12
                lineHeight: 1.35
            }
        }
    }
}
