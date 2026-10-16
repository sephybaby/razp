
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    implicitWidth: 1040
    implicitHeight: 480

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 24
        left: 0
        right: 0
    }

    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.namespace: "razp-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property string panel: "#f21b1118"
    property string surface: "#30202b"
    property string borderColor: "#704052"
    property string pink: "#ffc0d2"
    property string muted: "#bd91a4"
    property string textColor: "#ffe5ed"

    property string currentTime: Qt.formatDateTime(new Date(), "hh:mm AP")
    property string currentDate: Qt.formatDateTime(new Date(), "dddd, d MMMM yyyy")

    property string songTitle: "Waiting for music..."
    property string songArtist: "Spotify"
    property string albumArt: ""

    property string wifiNetwork: "Checking Wi-Fi..."
    property string wifiSignal: ""
    property string bluetoothStatus: "Checking..."
    property string batteryLevel: "--"
    property string volumeLevel: "--"
    property bool audioMuted: false

    function refreshSystem() {
        wifiProcess.start()
        bluetoothProcess.start()
        batteryProcess.start()
        volumeProcess.start()
    }

    // CLOCK
    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            root.currentTime = Qt.formatDateTime(new Date(), "hh:mm AP")
            root.currentDate = Qt.formatDateTime(new Date(), "dddd, d MMMM yyyy")
        }
    }

    // SPOTIFY METADATA
    Process {
        id: spotifyMetadata
        command: ["playerctl", "metadata", "--format", "{{title}}|{{artist}}"]

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("|")

                if (parts.length >= 2 && parts[0] !== "") {
                    root.songTitle = parts[0]
                    root.songArtist = parts.slice(1).join("|")
                } else {
                    root.songTitle = "Nothing playing"
                    root.songArtist = "Start something lovely ♡"
                }
            }
        }
    }

    Process {
        id: spotifyArtwork
        command: ["playerctl", "metadata", "mpris:artUrl"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.albumArt = text.trim()
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true

        onTriggered: {
            spotifyMetadata.start()
            spotifyArtwork.start()
        }
    }

    // WI-FI STATUS: IWD
    Process {
        id: wifiProcess
        command: ["iwctl", "station", "wlan0", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                var output = text
                var state = output.match(/State\s+(.+)/)
                var network = output.match(/Connected network\s+(.+)/)
                var signal = output.match(/RSSI\s+(-?\d+)\s*dBm/i)

                if (network) {
                    root.wifiNetwork = network[1].trim()
                } else if (state && state[1].trim() === "connected") {
                    root.wifiNetwork = "Connected"
                } else {
                    root.wifiNetwork = "Not connected"
                }

                root.wifiSignal = signal
                    ? signal[1].trim() + " dBm"
                    : ""
            }
        }
    }

    // BLUETOOTH STATUS
    Process {
        id: bluetoothProcess
        command: ["bluetoothctl", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/Powered:\s*(yes|no)/i)

                if (match) {
                    root.bluetoothStatus =
                        match[1].toLowerCase() === "yes" ? "On" : "Off"
                } else {
                    root.bluetoothStatus = "Unavailable"
                }
            }
        }
    }

    // BATTERY STATUS
    Process {
        id: batteryProcess
        command: [
            "sh", "-c",
            "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var value = text.trim()
                root.batteryLevel = value !== "" ? value + "%" : "Unavailable"
            }
        }
    }

    // AUDIO STATUS
    Process {
        id: volumeProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/Volume:\s*([\d.]+)/)

                root.volumeLevel = match
                    ? Math.round(Number(match[1]) * 100) + "%"
                    : "Unavailable"

                root.audioMuted = text.indexOf("[MUTED]") !== -1
            }
        }
    }

    // REFRESH LIVE SYSTEM INFORMATION
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refreshSystem()
    }

    Component.onCompleted: {
        spotifyMetadata.start()
        spotifyArtwork.start()
        root.refreshSystem()
    }

    // ACTIONS
    Process {
        id: wifiTerminal
        command: ["kitty", "-e", "iwctl"]
    }

    Process {
        id: bluetoothToggle
        command: [
            "sh", "-c",
            "if bluetoothctl show | grep -q 'Powered: yes'; then bluetoothctl power off; else bluetoothctl power on; fi"
        ]
    }

    Process {
        id: volumeDown
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
    }

    Process {
        id: volumeUp
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]
    }

    Process {
        id: volumeMute
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: dashboard
            width: 1000
            height: 450

            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }

            radius: 24
            color: root.panel
            border.width: 1
            border.color: root.borderColor
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // HEADER
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "RAZP  ♡"
                            color: root.pink
                            font.pixelSize: 25
                            font.bold: true
                        }

                        Text {
                            text: "YOUR LITTLE CORNER OF THE DESKTOP"
                            color: root.muted
                            font.pixelSize: 9
                            font.letterSpacing: 1.4
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 88
                        Layout.preferredHeight: 34
                        radius: 12
                        color: root.surface
                        border.color: root.borderColor

                        Text {
                            anchors.centerIn: parent
                            text: "✿  online"
                            color: root.pink
                            font.pixelSize: 11
                        }
                    }
                }

                // THREE-COLUMN LAYOUT
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    // LEFT: MUSIC
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1.15
                        radius: 18
                        color: "#38202d"
                        border.color: root.borderColor

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text {
                                text: "NOW PLAYING  ♫"
                                color: root.pink
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1
                            }

                            Item { Layout.fillHeight: true }

                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 112
                                Layout.preferredHeight: 112
                                source: root.albumArt
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.songTitle
                                color: root.textColor
                                font.pixelSize: 15
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.songArtist
                                color: root.muted
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Repeater {
                                    model: [
                                        { symbol: "⤨", action: "playerctl shuffle Toggle" },
                                        { symbol: "◂", action: "playerctl previous" },
                                        { symbol: "▶", action: "playerctl play-pause" },
                                        { symbol: "▸", action: "playerctl next" },
                                        { symbol: "↻", action: "playerctl loop Track" }
                                    ]

                                    delegate: Rectangle {
                                        id: musicButton
                                        required property var modelData

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        radius: 16
                                        color: musicMouse.containsMouse
                                            ? "#91465e" : "#702333"

                                        Text {
                                            anchors.centerIn: parent
                                            text: musicButton.modelData.symbol
                                            color: root.textColor
                                            font.pixelSize: 15
                                        }

                                        Process {
                                            id: musicProcess
                                            command: [
                                                "sh", "-lc",
                                                musicButton.modelData.action
                                            ]
                                        }

                                        MouseArea {
                                            id: musicMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: musicProcess.start()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // MIDDLE: CLOCK AND FAVOURITES
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1.35
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 142
                            radius: 18
                            color: "#38202d"
                            border.color: root.borderColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 5

                                Text {
                                    text: root.currentTime
                                    color: root.pink
                                    font.pixelSize: 34
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.currentDate
                                    color: root.textColor
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                Item { Layout.fillHeight: true }

                                Text {
                                    text: "take it one little step at a time ♡"
                                    color: root.muted
                                    font.pixelSize: 10
                                }
                            }
                        }

                        Text {
                            text: "YOUR FAVOURITES  ✿"
                            color: root.pink
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8

                            Repeater {
                                model: [
                                    { label: "Terminal", icon: ">_", command: "kitty" },
                                    { label: "Zen", icon: "♡", command: "flatpak run app.zen_browser.zen" },
                                    { label: "Obsidian", icon: "✧", command: "obsidian" },
                                    { label: "Files", icon: "▤", command: "Dolphin" }
                                ]

                                delegate: Rectangle {
                                    id: appButton
                                    required property var modelData

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumHeight: 54
                                    radius: 14
                                    color: appMouse.containsMouse
                                        ? "#603047" : root.surface
                                    border.color: appMouse.containsMouse
                                        ? root.pink : root.borderColor

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: appButton.modelData.icon
                                            color: root.pink
                                            font.pixelSize: 20
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: appButton.modelData.label
                                            color: root.textColor
                                            font.pixelSize: 10
                                        }
                                    }

                                    Process {
                                        id: appProcess
                                        command: [
                                            "sh", "-lc",
                                            appButton.modelData.command
                                        ]
                                    }

                                    MouseArea {
                                        id: appMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: appProcess.start()
                                    }
                                }
                            }
                        }
                    }

                    // RIGHT: SYSTEM CONTROLS
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 0.8
                        spacing: 8

                        Text {
                            text: "YOUR DESKTOP  ✿"
                            color: root.pink
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                        }

                        // WI-FI
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 66
                            radius: 15
                            color: root.surface
                            border.color: root.borderColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "⌁"
                                    color: root.pink
                                    font.pixelSize: 23
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        text: "WI-FI"
                                        color: root.muted
                                        font.pixelSize: 9
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.wifiNetwork
                                        color: root.textColor
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: root.wifiSignal
                                        color: root.muted
                                        font.pixelSize: 9
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 32
                                    radius: 10
                                    color: wifiMouse.containsMouse
                                        ? "#91465e" : "#603047"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↗"
                                        color: root.textColor
                                        font.pixelSize: 17
                                    }

                                    MouseArea {
                                        id: wifiMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: wifiTerminal.start()
                                    }
                                }
                            }
                        }

                        // BLUETOOTH
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 58
                            radius: 15
                            color: root.surface
                            border.color: root.borderColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "ᛒ"
                                    color: root.pink
                                    font.pixelSize: 22
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        text: "BLUETOOTH"
                                        color: root.muted
                                        font.pixelSize: 9
                                    }

                                    Text {
                                        text: root.bluetoothStatus
                                        color: root.textColor
                                        font.pixelSize: 12
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: root.bluetoothStatus === "On"
                                        ? "#91465e" : "#49303c"

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.bluetoothStatus === "On"
                                            ? "ON" : "OFF"
                                        color: root.textColor
                                        font.pixelSize: 9
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: bluetoothToggle.start()
                                    }
                                }
                            }
                        }

                        // VOLUME
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 78
                            radius: 15
                            color: root.surface
                            border.color: root.borderColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 7

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: root.audioMuted
                                            ? "MUTED" : "♫  VOLUME"
                                        color: root.pink
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: root.volumeLevel
                                        color: root.textColor
                                        font.pixelSize: 11
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: [
                                            { label: "−", action: "down" },
                                            { label: "M", action: "mute" },
                                            { label: "+", action: "up" }
                                        ]

                                        delegate: Rectangle {
                                            id: volumeButton
                                            required property var modelData

                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 29
                                            radius: 10
                                            color: volumeMouse.containsMouse
                                                ? "#91465e" : "#603047"

                                            Text {
                                                anchors.centerIn: parent
                                                text: volumeButton.modelData.label
                                                color: root.textColor
                                                font.pixelSize: 11
                                            }

                                            MouseArea {
                                                id: volumeMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor

                                                onClicked: {
                                                    if (volumeButton.modelData.action === "down")
                                                        volumeDown.start()
                                                    else if (volumeButton.modelData.action === "up")
                                                        volumeUp.start()
                                                    else
                                                        volumeMute.start()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // BATTERY
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 54
                            radius: 15
                            color: root.surface
                            border.color: root.borderColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Text {
                                    text: "ϟ"
                                    color: root.pink
                                    font.pixelSize: 23
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "BATTERY"
                                            color: root.muted
                                            font.pixelSize: 9
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            text: root.batteryLevel
                                            color: root.textColor
                                            font.pixelSize: 12
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 5
                                        radius: 3
                                        color: "#503443"

                                        Rectangle {
                                            width: parent.width
                                                * Math.max(0, Math.min(
                                                    100,
                                                    parseInt(root.batteryLevel) || 0
                                                )) / 100
                                            height: parent.height
                                            radius: 3
                                            color: root.pink
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "made with love  ♡"
                            color: root.muted
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}

