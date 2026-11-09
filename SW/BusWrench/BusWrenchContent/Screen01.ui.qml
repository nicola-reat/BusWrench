

/*
This is a UI file (.ui.qml) that is intended to be edited in Qt Design Studio only.
It is supposed to be strictly declarative and only uses a subset of QML. If you edit
this file manually, you might introduce QML code that is not supported by Qt Design Studio.
Check out https://doc.qt.io/qtcreator/creator-quick-ui-forms.html for details on .ui.qml files.
*/
import QtQuick
import QtQuick.Controls
import BusWrench
import QtQuick.Studio.Components

Rectangle {
    id: rectangle
    width: 1280
    height: Constants.height
    color: "#0b1626"
    property alias pageDetails: pageDetails

    property alias canStatusError: canStatusError
    property alias canStatusCheck: canStatusCheck
    property alias statusSub: statusSub
    property alias statusTitle: statusTitle
    property alias pageDevices: pageDevices
    property alias pageUpdate: pageUpdate
    property alias pageSettings: pageSettings

    Rectangle {
        id: sidebar
        x: 0
        y: 0
        width: 280
        height: 700
        color: "#0c1930"
        border.width: 0

        Rectangle {
            id: sidebarLine
            x: 279
            y: 0
            width: 1
            height: 700
            color: "#16294a"
        }

        Rectangle {
            id: menuSel
            x: 12
            y: 110
            width: 256
            height: 52
            color: "#123a73"
            radius: 10
            border.width: 0
        }

        Image {
            id: ico_buswrench
            x: 20
            y: 28
            width: 64
            height: 64
            source: "images/buswrench-icon.svg"
            sourceSize.height: 64
            sourceSize.width: 64
            fillMode: Image.PreserveAspectFit
        }

        Text {
            id: title
            x: 90
            y: 28
            width: 180
            height: 27
            color: "#ffffff"
            text: qsTr("BusWrench")
            font.pixelSize: 20
            horizontalAlignment: Text.AlignLeft
            font.weight: Font.Bold
        }

        Text {
            id: subtitle
            x: 90
            y: 61
            color: "#8fa3bf"
            text: qsTr("Can Bus toolkit")
            font.pixelSize: 13
            horizontalAlignment: Text.AlignLeft
            font.weight: Font.Normal
        }

        Text {
            id: menuDevices
            x: 68
            y: 110
            width: 190
            height: 52
            color: "#ffffff"
            text: qsTr("Dispositivi")
            font.pixelSize: 16
            verticalAlignment: Text.AlignVCenter
            font.styleName: "Regular"
        }

        Image {
            id: ico_device
            x: 32
            y: 126
            source: "images/ico_device.svg"
            sourceSize.height: 24
            sourceSize.width: 24
            fillMode: Image.PreserveAspectFit
        }

        Image {
            id: ico_update
            x: 32
            y: 186
            source: "images/ico_update.svg"
            sourceSize.height: 24
            sourceSize.width: 24
            fillMode: Image.PreserveAspectFit
        }

        Text {
            id: txtUpdate
            x: 68
            y: 170
            width: 190
            height: 52
            color: "#c9d6ea"
            text: qsTr("Aggiornamento")
            font.pixelSize: 16
            verticalAlignment: Text.AlignVCenter
        }

        Image {
            id: ico_log
            x: 32
            y: 246
            source: "images/ico_log.svg"
            sourceSize.height: 24
            sourceSize.width: 24
            fillMode: Image.PreserveAspectFit
        }

        Text {
            id: txtLog
            x: 68
            y: 230
            width: 190
            height: 52
            color: "#c9d6ea"
            text: qsTr("Log")
            font.pixelSize: 16
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: txtSettings
            x: 68
            y: 290
            width: 190
            height: 52
            color: "#c9d6ea"
            text: qsTr("Impostazioni")
            font.pixelSize: 16
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            id: statusBox
            x: 16
            y: 614
            width: 248
            height: 68
            color: "#0f2b2a"
            radius: 10
            border.color: "#174a3a"
            border.width: 1

            Text {
                id: statusTitle
                x: 38
                y: 12
                width: 200
                height: 22
                color: "#22c55e"
                text: qsTr("USB-CAN connesso")
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
                font.weight: Font.Bold
            }

            Text {
                id: statusSub
                x: 38
                y: 36
                width: 200
                height: 20
                color: "#8fa3bf"
                text: qsTr("PCAN-USB | 125 kbit/s")
                font.pixelSize: 12
            }

            Image {
                id: canStatusCheck
                x: 8
                y: 22
                source: "images/ico_circle-check.svg"
                sourceSize.height: 24
                sourceSize.width: 24
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: canStatusError
                x: 8
                y: 22
                source: "images/ico_error.svg"
                sourceSize.width: 24
                sourceSize.height: 24
                fillMode: Image.PreserveAspectFit
            }
        }

        Image {
            id: ico_settings
            x: 32
            y: 306
            source: "images/ico_settings.svg"
            sourceSize.height: 24
            sourceSize.width: 24
            fillMode: Image.PreserveAspectFit
        }

        MouseArea {
            id: maDevices
            x: 12
            y: 110
            width: 256
            height: 52

            Connections {
                target: maDevices
                function onClicked() {
                    rectangle.state = "devices"
                }
            }
        }

        MouseArea {
            id: maUpdate
            x: 12
            y: 170
            width: 256
            height: 52

            Connections {
                target: maUpdate
                function onClicked() {
                    rectangle.state = "update"
                }
            }
        }

        MouseArea {
            id: maLog
            x: 12
            y: 230
            width: 256
            height: 52
        }

        MouseArea {
            id: maSettings
            x: 12
            y: 290
            width: 256
            height: 52

            Connections {
                target: maSettings
                function onClicked() { rectangle.state = "settings" }
            }
        }
    }

    PageDevices {
        id: pageDevices
        x: 280
        y: 0
    }

    PageUpdate {
        id: pageUpdate
        x: 280
        visible: false
    }

    PageSettings {
        id: pageSettings
        visible: false
    }

    PageDetails {
        id: pageDetails
        visible: false
    }
    states: [
        State {
            name: "update"

            PropertyChanges {
                target: pageDevices
                visible: false
            }

            PropertyChanges {
                target: menuSel
                y: 170
            }

            PropertyChanges {
                target: menuDevices
                color: "#c9d6ea"
            }

            PropertyChanges {
                target: txtLog
                color: "#c9d6ea"
            }

            PropertyChanges {
                target: txtSettings
                color: "#c9d6ea"
            }

            PropertyChanges {
                target: pageUpdate
                visible: true
            }
        },
        State {
            name: "devices"

            PropertyChanges {
                target: pageUpdate
                visible: false
            }
        },
        State {
            name: "settings"

            PropertyChanges {
                target: menuSel
                y: 290
            }

            PropertyChanges {
                target: pageSettings
                x: 280
                y: 0
                visible: true
            }

            PropertyChanges {
                target: pageDevices
                visible: false
            }

            PropertyChanges {
                id: propertyChanges
                target: sidebar
                color: "#0c1930"
            }
        },
        State {
            name: "details"

            PropertyChanges {
                target: pageDetails
                x: 280
                y: 0
                visible: true
            }
        }
    ]
}
