import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Rectangle {
    id: root

    implicitWidth: 410
    implicitHeight: 190

    property color cherry: "#ff173f"
    property color pink: "#f0a0b8"
    property color muted: "#a47d8c"
    property color textColor: "#f4dfe6"
    property color surface: "#24171f"
    property color surfaceLight: "#30202a"
    property color borderColor: "#50303e"
    property color hoverColor: "#54303f"

    property string songTitle: "Checking Spotify..."
    property string songArtist: ""
    property string artUrl: ""
    property string musicStatus: ""

    color: surface
    radius: 14
    border.width: 1
    border.color: borderColor

    function runProcess(proc) {
        proc.running = false
        proc.running = true
    }

    function refreshMusic() {
        runProcess(metadataProcess)
        runProcess(statusProcess)
    }

    Process {
        id: metadataProcess
        command: [
            "sh", "-lc",
            "playerctl metadata --format '{{title}}|{{artist}}|{{mpris:artUrl}}' 2>/dev/null || echo 'Nothing playing||'"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("|")
                root.songTitle = parts.length > 0 && parts[0] !== ""
                    ? parts[0] : "Nothing playing"
                root.songArtist = parts.length > 1 ? parts[1] : ""
				var newArtUrl = parts.length > 2 ? parts[2] : ""
					if (root.artUrl !== newArtUrl)
					root.artUrl = newArtUrl
            }
        }
    }

    Process {
        id: statusProcess
        command: ["sh", "-lc", "playerctl status 2>/dev/null || echo Stopped"]
        stdout: StdioCollector {
            onStreamFinished: root.musicStatus = text.trim()
        }
    }

    Process { id: previousTrack; command: ["playerctl", "previous"] }
    Process { id: toggleTrack; command: ["playerctl", "play-pause"] }
    Process { id: nextTrack; command: ["playerctl", "next"] }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refreshMusic()
    }

    Component.onCompleted: root.refreshMusic()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 142
            Layout.preferredHeight: 142
            radius: 11
            color: "#351923"
            border.color: "#633044"
            clip: true

            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            Column {
                anchors.centerIn: parent
                spacing: 5
                visible: root.artUrl === "" || artwork.status !== Image.Ready

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "♫"
                    color: root.cherry
                    font.pixelSize: 43
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "CHERRY MUSIC"
                    color: root.muted
                    font.pixelSize: 8
                    font.letterSpacing: 1
                }
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "NOW PLAYING"
                    color: root.cherry
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.4
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "✿"
                    color: root.pink
                    font.pixelSize: 17
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.songTitle
                color: root.textColor
                font.pixelSize: 16
                font.bold: true
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: root.songArtist || "Spotify · waiting for artist"
                color: root.muted
                font.pixelSize: 12
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 9

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 34
                    radius: 9
                    color: prevMouse.containsMouse ? root.hoverColor : root.surfaceLight

                    Text {
                        anchors.centerIn: parent
                        text: "◂"
                        color: root.textColor
                        font.pixelSize: 20
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runProcess(previousTrack)
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 36
                    radius: 10
                    color: playMouse.containsMouse ? "#ff3557" : root.cherry

                    Text {
                        anchors.centerIn: parent
                        text: root.musicStatus === "Playing" ? "Ⅱ" : "▶"
                        color: "white"
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runProcess(toggleTrack)
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 34
                    radius: 9
                    color: nextMouse.containsMouse ? root.hoverColor : root.surfaceLight

                    Text {
                        anchors.centerIn: parent
                        text: "▸"
                        color: root.textColor
                        font.pixelSize: 20
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runProcess(nextTrack)
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Text {
                text: root.musicStatus === "" ? "SPOTIFY" : root.musicStatus.toUpperCase()
                color: root.muted
                font.pixelSize: 9
                font.letterSpacing: 1
            }
        }
    }
}

