import QtQuick
import QtQuick.Controls
import QtQuick.Studio.Components

Item {
    id: pageUpdate
    y: 0
    width: 1000
    height: 700
    property alias logArea: logArea
    property alias maChange: maChange
    property alias btnChange: btnChange
    property alias etaText: etaText
    property alias barFg: barFg
    property alias statusTitle: statusTitle
    property alias pctText: pctText
    property alias pctFg: pctFg
    property alias maStart: maStart
    property alias btnStartTxt: btnStartTxt
    property alias btnStart: btnStart
    property alias infoSHAData: infoSHAData
    property alias infoDimensionData: infoDimensionData
    property alias infoVersionData: infoVersionData
    property alias infoNameData: infoNameData
    property alias maBrowse: maBrowse
    property alias dropZone: dropZone
    property alias data3: data3
    property alias data2: data2
    property alias data1: data1
    property alias badgeStatusTxt: badgeStatusTxt
    property alias badgeStatus: badgeStatus
    property alias badge: badge
    property alias devName: devName

    Rectangle {
        id: hdrCircle
        x: 28
        y: 14
        width: 64
        height: 64
        color: "#0e2a52"
        radius: 32
        border.width: 0

        Image {
            id: hdrIcon
            x: 16
            y: 16
            width: 32
            height: 32
            source: "images/ico_refresh-cw - Blu.svg"
            sourceSize.height: 32
            sourceSize.width: 32
            fillMode: Image.PreserveAspectFit
        }
    }

    Text {
        id: hdrTitle
        x: 112
        y: 18
        width: 700
        height: 34
        color: "#ffffff"
        text: qsTr("Aggiornamento Firmware")
        font.pixelSize: 26
        verticalAlignment: Text.AlignVCenter
        font.weight: Font.Bold
    }

    Text {
        id: hdrSub
        x: 112
        y: 54
        width: 800
        height: 22
        color: "#c9d6ea"
        text: qsTr("Seleziona il dispositivo e il file firmware per avviare l’aggiornamento")
        font.pixelSize: 14
        verticalAlignment: Text.AlignVCenter
        font.weight: Font.Bold
    }

    Rectangle {
        id: hdrLine
        x: 28
        y: 88
        width: 944
        height: 2
        color: "#1e7bff"
    }

    Rectangle {
        id: panelDevice
        x: 28
        y: 100
        width: 944
        height: 124
        color: "#0c1b33"
        radius: 10
        border.width: 1

        Rectangle {
            id: titleLine
            x: 0
            y: 34
            width: 944
            height: 1
            color: "#1b3050"
            border.width: 0
        }

        Text {
            id: title
            x: 46
            y: 0
            width: 400
            height: 34
            color: "#ffffff"
            text: qsTr("Dispositivo selezionato")
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Bold
        }

        Image {
            id: titleIcon
            x: 14
            y: 6
            width: 22
            height: 22
            source: "images/ico_microchip - Blu.svg"
            sourceSize.height: 22
            sourceSize.width: 22
            fillMode: Image.PreserveAspectFit
        }

        ArcItem {
            id: ringBg
            x: 48
            y: 40
            width: 64
            height: 64
            strokeColor: "#1b3050"
            end: 360
            fillColor: "#00000000"
        }

        ArcItem {
            id: ringFg
            x: 48
            y: 40
            width: 64
            height: 64
            capStyle: 32
            strokeColor: "#2bb6e8"
            fillColor: "#00000000"
            end: 360
        }

        Image {
            id: chipIcon
            x: 66
            y: 58
            width: 28
            height: 28
            source: "images/ico_microchip.svg"
            fillMode: Image.PreserveAspectFit
        }

        Text {
            id: devName
            x: 140
            y: 40
            width: 130
            height: 26
            color: "#ffffff"
            text: qsTr("ESP32-S3")
            font.pixelSize: 18
            font.styleName: "Bold"
        }

        Rectangle {
            id: badge
            x: 276
            y: 42
            width: 84
            height: 24
            color: "#11392f"
            radius: 12
            border.width: 0

            Rectangle {
                id: badgeStatus
                x: 12
                y: 8
                width: 8
                height: 8
                color: "#22c55e"
                radius: 4
                border.width: 0
            }

            Text {
                id: badgeStatusTxt
                x: 26
                y: 0
                width: 56
                height: 24
                color: "#22c55e"
                text: qsTr("Online")
                font.pixelSize: 12
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
        }

        Rectangle {
            id: devSep
            x: 750
            y: 46
            width: 1
            height: 60
            color: "#1b3050"
        }

        Rectangle {
            id: btnChange
            x: 774
            y: 52
            width: 150
            height: 40
            color: "#0e2a52"
            radius: 8
            border.color: "#1e7bff"

            Text {
                id: btnChangeTxt
                x: 34
                width: 112
                height: 40
                color: "#ffffff"
                text: qsTr("Cambia dispositivo")
                font.pixelSize: 13
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            Image {
                id: btnChangeIcon
                x: 12
                y: 12
                width: 16
                height: 16
                source: "images/ico_refresh-cw.svg"
                sourceSize.height: 16
                sourceSize.width: 16
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                id: maChange
                anchors.fill: parent
            }
        }

        Text {
            id: dataTitle1
            x: 140
            y: 66
            width: 90
            color: "#c9d6ea"
            text: qsTr("Nodo ID")
            font.pixelSize: 13
        }

        Text {
            id: data1
            x: 232
            y: 66
            width: 150
            color: "#ffffff"
            text: qsTr("0x40")
            font.pixelSize: 13
        }

        Text {
            id: dataTitle2
            x: 140
            y: 84
            width: 90
            color: "#c9d6ea"
            text: qsTr("Firmware")
            font.pixelSize: 13
        }

        Text {
            id: data2
            x: 232
            y: 84
            width: 150
            color: "#ffffff"
            text: qsTr("0.9.1")
            font.pixelSize: 13
        }

        Text {
            id: dataTitle3
            x: 140
            y: 102
            width: 90
            color: "#c9d6ea"
            text: qsTr("Hardware")
            font.pixelSize: 13
        }

        Text {
            id: data3
            x: 232
            y: 102
            width: 90
            color: "#ffffff"
            text: qsTr("REV_A")
            font.pixelSize: 13
        }
    }

    Rectangle {
        id: panelFile
        x: 28
        y: 232
        width: 944
        height: 150
        color: "#0c1b33"
        radius: 10
        border.width: 1

        Rectangle {
            id: titleLine1
            x: 0
            y: 34
            width: 944
            height: 1
            color: "#1b3050"
            border.width: 0
        }

        Text {
            id: title1
            x: 46
            y: 0
            width: 400
            height: 34
            color: "#ffffff"
            text: qsTr("Seleziona file firmware")
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Bold
        }

        Image {
            id: titleIcon1
            x: 14
            y: 6
            width: 22
            height: 22
            source: "images/ico_folder-open - Blu.svg"
            sourceSize.width: 22
            sourceSize.height: 22
            fillMode: Image.PreserveAspectFit
        }

        Rectangle {
            id: dropZone
            x: 14
            y: 42
            width: 596
            height: 100
            color: "#0a1830"
            radius: 8
            border.color: "#2a4570"
            border.width: 1

            Image {
                id: dropIcon
                x: 190
                y: 30
                width: 40
                height: 40
                source: "images/ico_file-up.svg"
                sourceSize.height: 160
                sourceSize.width: 160
                fillMode: Image.PreserveAspectFit
            }

            Text {
                id: dropText
                x: 246
                y: 22
                width: 300
                height: 20
                color: "#ffffff"
                text: qsTr("Trascina qui il file .bin oppure")
                font.pixelSize: 13
            }

            Rectangle {
                id: btnBrowse
                x: 246
                y: 60
                width: 136
                height: 30
                color: "#1e7bff"
                radius: 6
                border.width: 0

                Image {
                    id: btnBrowseIcon
                    x: 14
                    y: 3
                    width: 24
                    height: 24
                    source: "images/ico_folder-open.svg"
                    sourceSize.height: 24
                    sourceSize.width: 24
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    id: btnBrowseTxt
                    x: 44
                    y: 6
                    color: "#ffffff"
                    text: qsTr("Sfoglia file...")
                    font.pixelSize: 13
                    font.styleName: "Bold"
                }

                MouseArea {
                    id: maBrowse
                    anchors.fill: parent
                }
            }
        }

        Rectangle {
            id: infoBox
            x: 626
            y: 42
            width: 304
            height: 100
            color: "#0a1830"
            radius: 8
            border.color: "#1b3050"

            Image {
                id: infoIcon
                x: 14
                y: 8
                width: 24
                height: 24
                source: "images/ico_info - blu.svg"
                sourceSize.height: 24
                sourceSize.width: 24
                fillMode: Image.PreserveAspectFit
            }

            Text {
                id: infoTitle
                x: 45
                y: 6
                width: 220
                height: 22
                color: "#ffffff"
                text: qsTr("Informazioni file")
                font.pixelSize: 14
                font.styleName: "Bold"
            }

            Text {
                id: infoName
                x: 45
                y: 32
                width: 90
                height: 16
                color: "#c9d6ea"
                text: qsTr("Nome:")
                font.pixelSize: 12
                font.styleName: "Regular"
            }

            Text {
                id: infoNameData
                x: 120
                y: 32
                width: 180
                height: 16
                color: "#ffffff"
                text: qsTr("esp32s3_firmware.bin")
                font.pixelSize: 12
                horizontalAlignment: Text.AlignLeft
                font.styleName: "Regular"
            }

            Text {
                id: infoVersion
                x: 45
                y: 47
                width: 90
                height: 16
                color: "#c9d6ea"
                text: qsTr("Versione:")
                font.pixelSize: 12
                font.styleName: "Regular"
            }

            Text {
                id: infoVersionData
                x: 120
                y: 47
                width: 180
                height: 16
                color: "#ffffff"
                text: qsTr("1.0.0")
                font.pixelSize: 12
                horizontalAlignment: Text.AlignLeft
                font.styleName: "Regular"
            }

            Text {
                id: infoDimension
                x: 45
                y: 62
                width: 90
                height: 16
                color: "#c9d6ea"
                text: qsTr("Dimensione:")
                font.pixelSize: 12
                font.styleName: "Regular"
            }

            Text {
                id: infoDimensionData
                x: 120
                y: 62
                width: 90
                height: 16
                color: "#c9d6ea"
                text: qsTr("8.4 MB")
                font.pixelSize: 12
                horizontalAlignment: Text.AlignLeft
                font.styleName: "Regular"
            }

            Text {
                id: infoSHA
                x: 45
                y: 77
                width: 90
                height: 16
                color: "#c9d6ea"
                text: qsTr("SHA-256:")
                font.pixelSize: 12
                font.styleName: "Regular"
            }

            Text {
                id: infoSHAData
                x: 120
                y: 77
                width: 90
                height: 16
                color: "#c9d6ea"
                text: qsTr("4f2c8e...9a7e")
                font.pixelSize: 12
                horizontalAlignment: Text.AlignLeft
                font.styleName: "Regular"
            }
        }
    }

    Rectangle {
        id: panelStart
        x: 28
        y: 390
        width: 944
        height: 84
        color: "#0c1b33"
        radius: 10
        border.width: 1

        Rectangle {
            id: titleLine2
            x: 0
            y: 34
            width: 944
            height: 1
            color: "#1b3050"
            border.width: 0
        }

        Text {
            id: title2
            x: 46
            y: 0
            width: 400
            height: 34
            color: "#ffffff"
            text: qsTr("Avvia aggiornamento")
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Bold
        }

        Image {
            id: titleIcon2
            x: 14
            y: 6
            width: 22
            height: 22
            source: "images/ico_zap - Blu.svg"
            sourceSize.width: 22
            sourceSize.height: 22
            fillMode: Image.PreserveAspectFit
        }

        Rectangle {
            id: btnStart
            x: 14
            y: 38
            width: 270
            height: 38
            color: "#1e7bff"
            radius: 8
            border.width: 0

            Image {
                id: btnStartIcon
                x: 22
                y: 7
                width: 24
                height: 24
                source: "images/ico_play.svg"
                sourceSize.height: 24
                sourceSize.width: 24
                fillMode: Image.PreserveAspectFit
            }

            Text {
                id: btnStartTxt
                x: 52
                y: 0
                width: 210
                height: 38
                color: "#ffffff"
                text: qsTr("Avvia Aggiornamento")
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                id: maStart
                anchors.fill: parent
            }
        }

        Rectangle {
            id: startSep
            x: 300
            y: 40
            width: 1
            height: 34
            color: "#1b3050"
            border.width: 0
        }

        Image {
            id: warnIcon
            x: 320
            y: 46
            width: 22
            height: 22
            source: "images/ico_circle-alert-Orange.svg"
            sourceSize.height: 22
            sourceSize.width: 22
            fillMode: Image.PreserveAspectFit
        }

        Text {
            id: warnText
            x: 354
            y: 38
            width: 560
            height: 38
            color: "#f5a524"
            text: qsTr("Durante l’aggiornamento non scollegare il dispositivo e non chiudere l’applicazione")
            font.pixelSize: 13
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        id: panelStatus
        x: 28
        y: 482
        width: 944
        height: 82
        color: "#0c1b33"
        radius: 10
        border.width: 1

        ArcItem {
            id: pctBg
            x: 16
            y: 13
            width: 56
            height: 56
            strokeColor: "#1b3050"
            end: 360
            fillColor: "#00000000"
        }

        ArcItem {
            id: pctFg
            x: 16
            y: 13
            width: 56
            height: 56
            capStyle: 32
            strokeColor: "#1e7bff"
            fillColor: "#00000000"
            end: 0
        }

        Text {
            id: pctText
            x: 16
            y: 13
            width: 56
            height: 56
            color: "#ffffff"
            text: qsTr("0%")
            font.pixelSize: 15
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.styleName: "Bold"
        }

        Text {
            id: statusTitle
            x: 100
            y: 10
            width: 400
            height: 22
            visible: true
            color: "#ffffff"
            text: qsTr("Stato aggiornamento")
            font.pixelSize: 14
            font.styleName: "Bold"
        }

        Rectangle {
            id: barBg
            x: 100
            y: 38
            width: 828
            height: 12
            color: "#16305a"
            radius: 6
            border.color: "#16305a"
            border.width: 0
        }

        Rectangle {
            id: barFg
            x: 100
            y: 38
            width: 0
            height: 12
            color: "#1e7bff"
            radius: 6
            border.color: "#16305a"
            border.width: 0
        }

        Image {
            id: clockIcon
            x: 758
            y: 59
            width: 16
            height: 16
            source: "images/ico_clock.svg"
            sourceSize.height: 16
            sourceSize.width: 16
            fillMode: Image.PreserveAspectFit
        }

        Text {
            id: etaText
            x: 780
            y: 58
            width: 148
            height: 18
            color: "#c9d6ea"
            text: qsTr("Tempo stimato: --:--")
            font.pixelSize: 12
        }
    }

    Rectangle {
        id: panelLog
        x: 28
        y: 572
        width: 944
        height: 108
        color: "#0c1b33"
        radius: 10
        border.width: 1

        Rectangle {
            id: titleLine3
            x: 0
            y: 34
            width: 944
            height: 1
            color: "#1b3050"
            border.width: 0
        }

        Text {
            id: title3
            x: 46
            y: 0
            width: 400
            height: 34
            color: "#ffffff"
            text: qsTr("Log operazioni")
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Bold
        }

        Image {
            id: titleIcon3
            x: 14
            y: 6
            width: 22
            height: 22
            source: "images/ico_list-clock_white.svg"
            sourceSize.width: 22
            sourceSize.height: 22
            fillMode: Image.PreserveAspectFit
        }

        Rectangle {
            id: logArea
            x: 8
            y: 40
            width: 928
            height: 62
            color: "#00000000"
            border.width: 0
        }
    }
}
