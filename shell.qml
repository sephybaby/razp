import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "components"

PanelWindow {
    id: root
    implicitWidth: 1080
    implicitHeight: 520
    anchors { top: true; left: true; right: true }
    margins { top: 18; left: 0; right: 0 }
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.namespace: "razp-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property color panel: "#f20b080d"
    property color surface: "#24171f"
    property color surfaceLight: "#30202a"
    property color borderColor: "#50303e"
    property color cherry: "#ff173f"
    property color pink: "#f0a0b8"
    property color muted: "#a47d8c"
    property color textColor: "#f4dfe6"
    property color hoverColor: "#54303f"

    property string currentTime: Qt.formatDateTime(new Date(), "hh:mm AP")
    property string currentDate: Qt.formatDateTime(new Date(), "dddd, d MMMM yyyy")
    property string songTitle: "Checking Spotify…"
    property string songArtist: ""
	property string wifiState: "Checking…"
	property string wifiNetwork: "Finding network…"
	property string wifiSignal: "-- dBm"
	property string wifiDownload: "-- Mbps"
	property string wifiUpload: "-- Mbps"
    property string batteryState: "Battery"
    property string volumeState: "Volume"
    property string brightnessState: "Brightness"
    property string profileState: "balanced"
    property string bluetoothState: "Bluetooth"
    property string musicStatus: ""

    function runProcess(proc) {
        // Quickshell Process is controlled through its running property.
        proc.running = false
        proc.running = true
    }

    function refreshSystem() {
		runProcess(wifiProcess)
		runProcess(wifiDetailsProcess)
		runProcess(wifiSpeedProcess)
        runProcess(bluetoothProcess)
        runProcess(batteryProcess)
        runProcess(volumeProcess)
        runProcess(brightnessProcess)
        runProcess(profileProcess)
        runProcess(spotifyMetadata)
        runProcess(spotifyStatus)
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.currentTime = Qt.formatDateTime(new Date(), "hh:mm AP")
            root.currentDate = Qt.formatDateTime(new Date(), "dddd, d MMMM yyyy")
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refreshSystem()
    }

	Process {
    id: wifiProcess
    command: ["sh", "-lc", "nmcli -t -f GENERAL.STATE device show wlan0 2>/dev/null | head -n1"]
    stdout: StdioCollector {
        onStreamFinished: {
            var result = text.trim()
            root.wifiState = result.indexOf("100") >= 0
                ? "Connected"
                : result.indexOf("connecting") >= 0
                    ? "Connecting"
                    : "Disconnected"
        }
    }
}

Process {
    id: wifiDetailsProcess

    command: [
        "sh", "-lc",
        "printf '%s|' \"$(nmcli -g GENERAL.CONNECTION device show wlan0 2>/dev/null)\"; iw dev wlan0 link 2>/dev/null | awk '/signal:/ {print $2; exit}'"
    ]

    stdout: StdioCollector {
        onStreamFinished: {
            var result = text.trim().split("|")

            var network = result.length > 0 ? result[0].trim() : ""
            var signal = result.length > 1 ? result[1].trim() : ""

            root.wifiNetwork =
                network !== "" && network !== "--"
                ? network
                : "Not connected"

            root.wifiSignal =
                signal !== "" && !isNaN(Number(signal))
                ? signal + " dBm"
                : "-- dBm"
        }
    }
}


	Process {
		id: wifiSpeedProcess
		command: ["sh", "-lc",
			"rx1=$(cat /sys/class/net/wlan0/statistics/rx_bytes); tx1=$(cat /sys/class/net/wlan0/statistics/tx_bytes); sleep 1; rx2=$(cat /sys/class/net/wlan0/statistics/rx_bytes); tx2=$(cat /sys/class/net/wlan0/statistics/tx_bytes); awk -v a=\"$rx1\" -v b=\"$rx2\" -v c=\"$tx1\" -v d=\"$tx2\" 'BEGIN {printf \"%.1f|%.1f\", (b-a)*8/1000000, (d-c)*8/1000000}'"
		]
		stdout: StdioCollector {
			onStreamFinished: {
				var parts = text.trim().split("|")
				if (parts.length >= 2) {
					root.wifiDownload = parts[0] + " Mbps"
					root.wifiUpload = parts[1] + " Mbps"
				}
			}
		}
	}
    Process {
        id: bluetoothProcess
        command: ["sh", "-lc", "bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print $2; exit}'"]
        stdout: StdioCollector { onStreamFinished: root.bluetoothState = text.trim() === "yes" ? "On" : "Off" }
    }
    Process {
        id: batteryProcess
        command: ["sh", "-lc", "if [ -r /sys/class/power_supply/BAT0/capacity ]; then cat /sys/class/power_supply/BAT0/capacity; else echo '--'; fi"]
        stdout: StdioCollector { onStreamFinished: root.batteryState = text.trim() + (text.trim() === "--" ? "" : "%") }
    }
    Process {
        id: volumeProcess
        command: ["sh", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf \"%d%%\", $2*100}'"]
        stdout: StdioCollector { onStreamFinished: root.volumeState = text.trim() === "" ? "N/A" : text.trim() }
    }
    Process {
        id: brightnessProcess
        command: ["sh", "-lc", "b=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'); [ -n \"$b\" ] && echo \"$b%\" || echo N/A"]
        stdout: StdioCollector { onStreamFinished: root.brightnessState = text.trim() }
    }
    Process {
        id: profileProcess
        command: ["sh", "-lc", "powerprofilesctl get 2>/dev/null || echo balanced"]
        stdout: StdioCollector { onStreamFinished: root.profileState = text.trim() }
    }
    Process {
        id: spotifyMetadata
        command: ["sh", "-lc", "playerctl metadata --format '{{title}}|{{artist}}' 2>/dev/null || echo 'Nothing playing|' "]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("|")
                root.songTitle = parts.length > 0 && parts[0] !== "" ? parts[0] : "Nothing playing"
                root.songArtist = parts.length > 1 ? parts[1] : ""
            }
        }
    }
    Process {
        id: spotifyStatus
        command: ["sh", "-lc", "playerctl status 2>/dev/null || echo Stopped"]
        stdout: StdioCollector { onStreamFinished: root.musicStatus = text.trim() }
    }

    Item {
        anchors.fill: parent
        Rectangle {
            id: board
            width: 1040
            height: 492
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 18
            color: root.panel
            border.width: 1
            border.color: root.borderColor
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

				// LEFT: music component
				
               ColumnLayout {
                   Layout.preferredWidth: 340
                   Layout.fillHeight: true
                   spacing: 10

                   MusicCard {
                       Layout.fillWidth: true
                       Layout.preferredHeight: 180
                       Layout.alignment: Qt.AlignHCenter

                       cherry: root.cherry
                       pink: root.pink
                       muted: root.muted
                       textColor: root.textColor
                       surface: root.surface
                       surfaceLight: root.surfaceLight
                       borderColor: root.borderColor
                       hoverColor: root.hoverColor
                   }

                   CalendarCard {
                       Layout.fillWidth: true
                       Layout.fillHeight: true
                       Layout.minimumHeight: 0

                       cherry: root.cherry
                       pink: root.pink
                       muted: root.muted
                       textColor: root.textColor
                       surface: root.surface
                       borderColor: root.borderColor
                   }
               }


                // MIDDLE: clock and app shortcuts
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 172
                        radius: 14
                        color: "#30131e"
                        border.color: "#6b2038"
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text { text: "GOOD DAY, CHERRY ♡"; color: root.muted; font.pixelSize: 10; font.letterSpacing: 1.5 }
                                Text { text: root.currentTime; color: root.cherry; font.pixelSize: 43; font.bold: true }
                                Text { text: root.currentDate; color: root.textColor; font.pixelSize: 12 }
                                Text { text: "take it one little step at a time"; color: root.muted; font.pixelSize: 10 }
                            }
                            Text { text: "✿"; color: root.pink; font.pixelSize: 50 }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "FAVOURITES"; color: root.cherry; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.5 }
                            Item { Layout.fillWidth: true }
                            Text { text: "04 APPS"; color: root.muted; font.pixelSize: 9 }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 2
                            rows: 2
                            columnSpacing: 9
                            rowSpacing: 9
                            Repeater {
                                model: [
                                    { label: "Terminal", icon: ">_", command: "kitty" },
                                    { label: "Zen Browser", icon: "♡", command: "flatpak run app.zen_browser.zen" },
                                    { label: "Obsidian", icon: "✧", command: "obsidian" },
                                    { label: "Files", icon: "▤", command: "thunar || dolphin || xdg-open \"$HOME\"" }
                                ]
                                delegate: Rectangle {
                                    id: appTile
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 11
                                    color: tileMouse.containsMouse ? root.hoverColor : root.surface
                                    border.width: 1
                                    border.color: tileMouse.containsMouse ? root.cherry : root.borderColor
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: appTile.modelData.icon; color: root.cherry; font.pixelSize: 24; font.bold: true }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: appTile.modelData.label; color: root.textColor; font.pixelSize: 11 }
                                    }
                                    Process { id: launchApp; command: ["sh", "-lc", appTile.modelData.command] }
                                    MouseArea { id: tileMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runProcess(launchApp) }
                                }
                            }
                        }
                    }
                }

                // RIGHT: compact system dashboard
                ColumnLayout {
                    Layout.preferredWidth: 270
                    Layout.fillHeight: true
                    spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "SYSTEM / STATUS"; color: root.cherry; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
                        Item { Layout.fillWidth: true }
                        Text { text: "●"; color: root.cherry; font.pixelSize: 10 }
                    }
					
                   Rectangle {
                       Layout.fillWidth: true
                       Layout.preferredHeight: 132
                       radius: 11
                       color: root.surface
                       border.color: root.borderColor

                       ColumnLayout {
                           anchors.fill: parent
                           anchors.margins: 11
                           spacing: 7

                           RowLayout {
                               Layout.fillWidth: true
                               spacing: 8

                               Text {
                                   text: "⌁"
                                   color: root.cherry
                                   font.pixelSize: 23
                               }

                               ColumnLayout {
                                   Layout.fillWidth: true
                                   spacing: 2

                                   Text {
                                       text: "WI-FI"
                                       color: root.muted
                                       font.pixelSize: 9
                                       font.letterSpacing: 1
                                   }

                                   Text {
                                       text: root.wifiNetwork
                                       color: root.textColor
                                       font.pixelSize: 12
                                       font.bold: true
                                       elide: Text.ElideRight
                                       Layout.fillWidth: true
                                   }
                               }

                               Rectangle {
                                   width: 54
                                   height: 30
                                   radius: 8
                                   color: wifiButtonMouse.containsMouse
                                       ? root.hoverColor : root.surfaceLight

                                   Text {
                                       anchors.centerIn: parent
                                       text: "MANAGE"
                                       color: root.pink
                                       font.pixelSize: 8
                                       font.bold: true
                                   }

                                   MouseArea {
                                       id: wifiButtonMouse
                                       anchors.fill: parent
                                       hoverEnabled: true
                                       onClicked: root.runProcess(wifiTerminal)
                                   }
                               }
                           }

                           Rectangle {
                               Layout.fillWidth: true
                               height: 1
                               color: root.borderColor
                           }

                           RowLayout {
                               Layout.fillWidth: true
                               spacing: 4

                               Text {
                                   text: "SIGNAL"
                                   color: root.muted
                                   font.pixelSize: 8
                               }

                               Text {
                                   text: root.wifiSignal
                                   color: root.pink
                                   font.pixelSize: 10
                                   font.bold: true
                               }

                               Item { Layout.fillWidth: true }

                               Text {
                                   text: root.wifiState
                                   color: root.cherry
                                   font.pixelSize: 9
                               }
                           }

                           RowLayout {
                               Layout.fillWidth: true
                               spacing: 8

                               Text {
                                   text: "↓ " + root.wifiDownload
                                   color: root.textColor
                                   font.pixelSize: 10
                                   Layout.fillWidth: true
                               }

                               Text {
                                   text: "↑ " + root.wifiUpload
                                   color: root.textColor
                                   font.pixelSize: 10
                                   Layout.fillWidth: true
                                   horizontalAlignment: Text.AlignRight
                               }
                           }
                       }
                   }


					Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68
                        radius: 11; color: root.surface; border.color: root.borderColor
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 10
                            Text { text: "ϟ"; color: root.cherry; font.pixelSize: 23 }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 3
                                Text { text: "BATTERY"; color: root.muted; font.pixelSize: 9; font.letterSpacing: 1 }
                                Text { text: root.batteryState; color: root.textColor; font.pixelSize: 13; font.bold: true }
                            }
                            Text { text: "▰"; color: root.pink; font.pixelSize: 18 }
                        }
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 76; radius: 11; color: root.surface; border.color: root.borderColor
                            Column {
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "◖"
                                    color: root.cherry
                                    font.pixelSize: 20
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "VOLUME"
                                    color: root.muted
                                    font.pixelSize: 9
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.volumeState
                                    color: root.textColor
                                    font.pixelSize: 12
                                }
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.runProcess(volumeToggle) }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 76; radius: 11; color: root.surface; border.color: root.borderColor
                            Column {
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "☼"
                                    color: root.cherry
                                    font.pixelSize: 20
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "BRIGHTNESS"
                                    color: root.muted
                                    font.pixelSize: 9
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.brightnessState
                                    color: root.textColor
                                    font.pixelSize: 12
                                }
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.runProcess(brightnessUp) }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 11; color: root.surface; border.color: root.borderColor
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 11; spacing: 8
                            Text { text: "QUICK CONTROLS"; color: root.muted; font.pixelSize: 9; font.letterSpacing: 1 }
                            RowLayout {
                                Layout.fillWidth: true
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 8
                                    color: btMouse.containsMouse ? root.hoverColor : root.surfaceLight
                                    Text {
                                        anchors.centerIn: parent
                                        text: "BT  " + root.bluetoothState
                                        color: root.textColor
                                        font.pixelSize: 10
                                    }
                                    MouseArea {
                                        id: btMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.runProcess(bluetoothToggle)
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 8
                                    color: refreshMouse.containsMouse ? root.hoverColor : root.surfaceLight
                                    Text {
                                        anchors.centerIn: parent
                                        text: "↻  REFRESH"
                                        color: root.pink
                                        font.pixelSize: 10
                                    }
                                    MouseArea {
                                        id: refreshMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.refreshSystem()
                                    }
                                }
                            }
                            Text { text: "POWER PROFILE"; color: root.muted; font.pixelSize: 9; font.letterSpacing: 1 }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 5
                                Repeater {
                                    model: ["power-saver", "balanced", "performance"]
                                    delegate: Rectangle {
                                        required property string modelData
                                        Layout.fillWidth: true; height: 31; radius: 7
                                        color: root.profileState === modelData ? "#552033" : root.surfaceLight
                                        border.color: root.profileState === modelData ? root.cherry : root.borderColor
                                        Text { anchors.centerIn: parent; text: modelData === "power-saver" ? "SAVE" : modelData === "performance" ? "PERF" : "BAL"; color: root.textColor; font.pixelSize: 9 }
                                        Process { id: setProfile; command: ["powerprofilesctl", "set", modelData] }
                                        MouseArea { anchors.fill: parent; onClicked: { root.runProcess(setProfile); root.profileState = modelData } }
                                    }
                                }
                            }
                            Item { Layout.fillHeight: true }
                            Text { text: "CHERRY GLASS  ·  RAZP"; color: root.muted; font.pixelSize: 8; font.letterSpacing: 1; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                }
            }
        }
    }

    // Media actions
    Process { id: previousTrack; command: ["playerctl", "previous"] }
    Process { id: toggleTrack; command: ["playerctl", "play-pause"] }
    Process { id: nextTrack; command: ["playerctl", "next"] }
    Process { id: wifiTerminal; command: ["kitty", "-e", "iwctl"] }
    Process { id: bluetoothToggle; command: ["sh", "-lc", "if bluetoothctl show | grep -q 'Powered: yes'; then bluetoothctl power off; else bluetoothctl power on; fi"] }
    Process { id: volumeToggle; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }
    Process { id: brightnessUp; command: ["brightnessctl", "set", "+5%"] }
    Process { id: refreshAfterAction; command: ["true"] }

    Component.onCompleted: root.refreshSystem()
}
