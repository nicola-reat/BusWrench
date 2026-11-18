import QtQuick
import QtQuick.Studio.Components

Item {
    id: pageDevices
    width: 1000
    height: 700
    property alias maDetails: maDetails
    property alias detailIcon: detailIcon
    property alias detailPanel: detailPanel
    property alias maUpdateFw: maUpdateFw
    property alias valHw: valHw
    property alias valFw: valFw
    property alias valUid: valUid
    property alias badgeText: badgeText
    property alias badge: badge
    property alias valNode: valNode
    property alias dChip: dChip
    property alias dName: dName
    property alias cardsArea: cardsArea
    property alias countText: countText
    property alias maScan: maScan

    Text {
        id: pageTitle
        x: 28
        y: 26
        width: 500
        height: 36
        color: "#ffffff"
        text: qsTr("Dispositivi sulla rete CAN")
        font.pixelSize: 24
        verticalAlignment: Text.AlignVCenter
        font.weight: Font.Bold
    }

    Text {
        id: pageSub
        x: 28
        y: 66
        width: 500
        height: 36
        color: "#c9d6ea"
        text: qsTr("Scansiona la rete per trovare tutti i dispositivi disponibili")
        font.pixelSize: 14
        verticalAlignment: Text.AlignVCenter
        font.weight: Font.Normal
    }

    Rectangle {
        id: btnScan
        x: 812
        y: 30
        width: 160
        height: 44
        color: "#1e7bff"
        radius: 8
        border.width: 0
        Text {
            id: btnScanText
            x: 10
            y: 0
            width: 150
            height: 44
            color: "#ffffff"
            text: qsTr("Scansiona")
            font.pixelSize: 15
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.styleName: "Bold"
        }

        Image {
            id: ico_refreshCw
            x: 10
            y: 10
            source: "images/ico_refresh-cw.svg"
            sourceSize.width: 24
            sourceSize.height: 24
            fillMode: Image.PreserveAspectFit
        }

        MouseArea {
            id: maScan
            anchors.fill: parent
        }
    }

    Text {
        id: countText
        x: 36
        y: 556
        width: 300
        height: 22
        color: "#8fa3bf"
        text: qsTr("3 dispositivi trovati")
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        id: detailPanel
        x: 608
        y: 120
        width: 364
        height: 450
        color: "#0e1d36"
        radius: 12
        border.color: "#1b3050"
        Text {
            id: dName
            x: 152
            y: 28
            width: 190
            height: 28
            color: "#ffffff"
            text: qsTr("Dashboard")
            font.pixelSize: 18
            verticalAlignment: Text.AlignVCenter
            font.styleName: "Bold"
        }

        Text {
            id: dChip
            x: 152
            y: 58
            width: 190
            height: 28
            color: "#c9d6ea"
            text: qsTr("ESP32-S3")
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            font.styleName: "Regular"
        }

        Rectangle {
            id: badge
            x: 152
            y: 92
            width: 86
            height: 30
            color: "#11392f"
            radius: 15
            border.width: 0
            Text {
                id: badgeText
                x: 0
                y: 0
                width: 86
                height: 30
                color: "#22c55e"
                text: qsTr("Online")
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.weight: Font.Normal
            }
        }

        Rectangle {
            id: div1
            x: 20
            y: 152
            width: 324
            height: 1
            color: "#1b3050"
        }

        Text {
            id: lblNode
            x: 24
            y: 168
            width: 110
            height: 28
            color: "#c9d6ea"
            text: qsTr("Node ID")
            font.pixelSize: 14
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: valNode
            x: 148
            y: 168
            width: 190
            height: 28
            color: "#ffffff"
            text: qsTr("0x40")
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.styleName: "Bold"
        }

        Text {
            id: lblUid
            x: 24
            y: 202
            width: 110
            height: 28
            color: "#c9d6ea"
            text: qsTr("UID")
            font.pixelSize: 14
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: lblFw
            x: 24
            y: 236
            width: 110
            height: 28
            color: "#c9d6ea"
            text: qsTr("Firmware")
            font.pixelSize: 14
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: lblHw
            x: 24
            y: 270
            width: 110
            height: 28
            color: "#c9d6ea"
            text: qsTr("Hardware")
            font.pixelSize: 14
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: valUid
            x: 148
            y: 202
            width: 190
            height: 28
            color: "#ffffff"
            text: qsTr("7A12-3F6D-9C8E")
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.styleName: "Bold"
        }

        Text {
            id: valFw
            x: 148
            y: 236
            width: 190
            height: 28
            color: "#ffffff"
            text: qsTr("0.9.1")
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.styleName: "Bold"
        }

        Text {
            id: valHw
            x: 148
            y: 270
            width: 190
            height: 28
            color: "#ffffff"
            text: qsTr("REV_A")
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.styleName: "Bold"
        }

        Rectangle {
            id: div2
            x: 20
            y: 312
            width: 324
            height: 1
            color: "#1b3050"
        }

        Rectangle {
            id: btnUpdate
            x: 20
            y: 330
            width: 324
            height: 46
            color: "#1e7bff"
            radius: 8
            border.width: 0
            Text {
                id: btnUpdateText
                x: 0
                y: 0
                width: 324
                height: 46
                color: "#ffffff"
                text: qsTr("Aggiorna Firmware")
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.weight: Font.Bold
            }

            MouseArea {
                id: maUpdateFw
                anchors.fill: parent
            }
        }

        Rectangle {
            id: btnDetails
            x: 20
            y: 388
            width: 324
            height: 46
            color: "#0e1d36"
            radius: 8
            border.color: "#2a4570"
            border.width: 1
            Text {
                id: btnDetailsText
                x: 0
                y: 0
                width: 324
                height: 46
                color: "#ffffff"
                text: qsTr("Dettagli")
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.weight: Font.Normal
            }

            MouseArea {
                id: maDetails
                anchors.fill: parent
            }
        }

        ArcItem {
            id: ringBg
            x: 24
            y: 24
            width: 110
            height: 110
            strokeWidth: 5
            strokeColor: "#1b3050"
            fillColor: "#00000000"
            end: 360
            capStyle: 32
        }

        ArcItem {
            id: ringFg
            x: 24
            y: 24
            width: 110
            height: 110
            strokeWidth: 5
            strokeColor: "#22c55e"
            fillColor: "#00000000"
            end: 300
            capStyle: 32
        }

        Rectangle {
            id: ringInner
            x: 39
            y: 39
            width: 80
            height: 80
            color: "#0e1d36"
            radius: 40
            Image {
                id: detailIcon
                x: 8
                y: 8
                width: 64
                height: 64
                source: "images/ico_microchip.svg"
                sourceSize.width: 64
                sourceSize.height: 64
                fillMode: Image.PreserveAspectFit
            }
        }
    }

    Item {
        id: cardsArea
        x: 28
        y: 120
        width: 560
        height: 430
    }
}
