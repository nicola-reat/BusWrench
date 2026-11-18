import QtQuick


/*
 * OVERVIEW
 * --------
 * DeviceCard is the card shown on the Devices page for each device
 * found on the CAN bus. It is created by a Repeater in App.qml, which
 * fills the properties below with the data of one DeviceModel row.
 *
 * The card only displays data: it does not contain any CAN logic.
 */
Rectangle {
    id: root
    width: 560
    height: 130
    radius: 12

    // Data shown by the card (filled by the Repeater in App.qml).
    property string deviceName: ""
    property string chip: ""
    property string nodeId: ""
    property string firmware: ""
    property string hardware: ""
    property string uid: ""

    // Icon file name inside the "images" folder (e.g. "ico_gauge.svg").
    // It is chosen by the C++ model for each node ID.
    property string iconFile: ""

    // true = the node answered recently, false = it has been silent.
    property bool online: false

    // true = this is the device selected by the user.
    property bool selected: false

    // Lets App.qml react to a click on the card.
    property alias cardMouse: cardMouse

    // The selected card has a brighter fill and a blue border.
    color: root.selected ? "#10264A" : "#0E1D36"
    border.color: root.selected ? "#1E7BFF" : "#1B3050"
    border.width: root.selected ? 2 : 1

    // Square box on the left with the device icon.
    Rectangle {
        id: iconBox
        x: 18
        y: 29
        width: 72
        height: 72
        color: "#16305a"
        radius: 14
        border.width: 0

        // Device icon: the file name comes from the C++ model (iconFile).
        Image {
            id: deviceIcon
            x: 12
            y: 12
            width: 48
            height: 48
            source: root.iconFile !== "" ? "images/" + root.iconFile : ""
            sourceSize.width: 192
            sourceSize.height: 192
            fillMode: Image.PreserveAspectFit
            clip: true
        }
    }

    // Device name (the width follows the text, so the status dot moves with it).
    Text {
        id: name
        x: 112
        y: 14
        height: 28
        color: "#ffffff"
        text: root.deviceName
        font.pixelSize: 17
        verticalAlignment: Text.AlignVCenter
        font.weight: Font.Bold
    }

    // Status dot: green when online, red when offline.
    Rectangle {
        id: dot
        x: name.x + name.width + 12
        y: 24
        width: 8
        height: 8
        color: root.online ? "#22c55e" : "#F87171"
        radius: 4
    }

    // Status text: "Online" or "Offline".
    Text {
        id: statusText
        x: dot.x + 14
        y: 14
        width: 60
        height: 28
        color: root.online ? "#22c55e" : "#F87171"
        text: root.online ? qsTr("Online") : qsTr("Offline")
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
        font.weight: Font.Bold
    }

    // Chip type and node ID, e.g. "ESP32-S3 | Node ID 0x45".
    Text {
        id: line2
        x: 112
        y: 46
        width: 380
        height: 22
        color: "#8fa3bf"
        text: root.chip + " | Node ID " + root.nodeId
        font.pixelSize: 14
    }

    // Firmware version and hardware revision.
    Text {
        id: line3
        x: 112
        y: 70
        width: 380
        height: 22
        color: "#8fa3bf"
        text: "Firmware: " + root.firmware + " | Hardware: " + root.hardware
        font.pixelSize: 14
    }

    // Unique ID of the board.
    Text {
        id: line4
        x: 112
        y: 94
        width: 380
        height: 22
        color: "#8fa3bf"
        text: "UID: " + root.uid
        font.pixelSize: 14
    }

    // Arrow on the right side of the card.
    Image {
        id: ico_chevronRight
        x: 516
        y: 53
        width: 24
        height: 24
        source: "images/ico_chevron-right.svg"
        sourceSize.width: 96
        sourceSize.height: 96
        fillMode: Image.PreserveAspectFit
    }

    // Clickable area covering the whole card (used to select the device).
    // It is the last child, so it stays in front of everything else.
    MouseArea {
        id: cardMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
    }
}
