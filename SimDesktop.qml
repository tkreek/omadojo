import QtQuick
import qs.Commons

Rectangle {
  id: root
  property string scene: "welcome"
  property bool after: false
  property bool animateChanges: true
  property string applicationId: "terminal"
  property string appLabel: "Terminal"
  property color accent
  property color foreground
  property color background
  readonly property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.45)
  readonly property bool otherWorkspace: after && (scene === "workspace" || scene === "move")
  readonly property bool focusLeft: (scene === "left" && after) || (scene === "right" && !after)
  readonly property bool floating: scene === "float" && after
  readonly property bool full: scene === "fullscreen" && after
  readonly property bool menuOpen: scene === "menu" && after
  readonly property bool launched: scene === "launch" && after
  readonly property bool closed: scene === "close" && after
  readonly property bool overlapping: (scene === "layout" && after) || floating
  readonly property string appKind: applicationId === "browser" ? "browser" : applicationId === "files" ? "files" : applicationId === "editor" || applicationId === "obsidian" ? "editor" : applicationId === "calculator" ? "calculator" : applicationId === "music" ? "music" : "terminal"
  radius: 12
  clip: true
  color: background
  border.width: 1; border.color: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)

  // A quiet desktop backdrop with a small horizon, rather than an empty box.
  Rectangle {
    anchors.fill: parent; anchors.margins: 1; radius: 11
    gradient: Gradient {
      GradientStop { position: 0; color: Qt.tint(root.background, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)) }
      GradientStop { position: 1; color: root.background }
    }
  }
  Rectangle {
    width: parent.width * 0.9; height: parent.height * 0.7; radius: height / 2
    x: parent.width * 0.25; y: parent.height * 0.58
    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.035)
    rotation: -25
  }
  Rectangle {
    id: bar
    x: 1; y: 1; width: parent.width - 2; height: 28
    color: Qt.tint(root.background, Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06))
    Row {
      x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 6
      Text { text: "◈"; color: root.accent; font.pixelSize: 12; textFormat: Text.PlainText }
      Repeater {
        model: 4
        Rectangle {
          required property int index
          readonly property bool selected: index === (root.otherWorkspace ? 1 : 0)
          width: 19; height: 17; radius: 4
          color: selected ? root.accent : "transparent"
          Text {
            anchors.centerIn: parent; text: parent.index + 1
            color: parent.selected ? root.background : root.muted
            font.pixelSize: 9; textFormat: Text.PlainText
          }
        }
      }
    }
    Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: "◉   ϟ   10:24"; font.pixelSize: 9; color: root.foreground; textFormat: Text.PlainText }
  }

  Repeater {
    model: 2
    SimWindow {
      id: tile
      required property int index
      readonly property bool subject: index === 1
      readonly property bool swap: root.scene === "swap" && root.after
      readonly property bool oneWindow: root.full || root.closed || (root.scene === "launch" && !root.after)
      readonly property int position: swap ? 1 - index : index
      readonly property real usableHeight: root.height - 80
      opacity: (subject && root.closed) || (index === 0 && root.full) || (subject && root.scene === "launch" && !root.after) ? 0 : 1
      visible: opacity > 0
      scale: subject && root.scene === "launch" && !root.after ? 0.95 : 1
      x: root.full && subject ? 8 : root.overlapping && subject ? root.width * 0.21 : oneWindow ? 12 : 12 + position * (root.width - 16) / 2
      y: root.overlapping && subject ? 62 : 42
      width: root.full && subject ? root.width - 16 : root.overlapping && subject ? root.width * 0.72 : oneWindow ? root.width - 24 : (root.width - 34) / 2
      height: root.full && subject ? root.height - 51 : root.overlapping && subject ? usableHeight * 0.85 : usableHeight
      z: subject ? 2 : 1
      active: root.scene === "left" || root.scene === "right" ? index === (root.focusLeft ? 0 : 1) : subject || oneWindow
      kind: root.otherWorkspace ? (root.scene === "move" && subject ? "terminal" : index === 0 ? "files" : "editor") : subject && root.scene === "launch" ? root.appKind : index === 0 ? "terminal" : "browser"
      title: root.otherWorkspace ? (root.scene === "move" && subject ? "Terminal · moved to workspace 2" : index === 0 ? "Files — Projects" : "Editor — notes.md") : subject && root.scene === "launch" ? root.appLabel : index === 0 ? "Terminal — ~/Projects" : "Browser — Omarchy"
      accent: root.accent; foreground: root.foreground; background: root.background
      Behavior on x { enabled: root.animateChanges; NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }
      Behavior on y { enabled: root.animateChanges; NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }
      Behavior on width { enabled: root.animateChanges; NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }
      Behavior on height { enabled: root.animateChanges; NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }
      Behavior on opacity { enabled: root.animateChanges; NumberAnimation { duration: Style.duration(160); easing.type: Easing.OutCubic } }
      Behavior on scale { enabled: root.animateChanges; NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }
    }
  }

  Rectangle {
    opacity: root.menuOpen ? 1 : 0
    visible: opacity > 0
    scale: root.menuOpen ? 1 : 0.95
    Behavior on opacity { enabled: root.animateChanges; NumberAnimation { duration: Style.duration(160); easing.type: Easing.OutCubic } }
    Behavior on scale { enabled: root.animateChanges; NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }
    anchors.centerIn: parent
    width: parent.width * 0.7; height: Math.min(parent.height - 65, 235)
    z: 5; radius: 10; color: Qt.tint(root.background, Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)); border.color: root.accent
    Column {
      anchors.fill: parent; anchors.margins: 14; spacing: 9
      Text { text: "⌕  " + root.appLabel; width: parent.width; elide: Text.ElideRight; color: root.foreground; font.pixelSize: 12; textFormat: Text.PlainText }
      Rectangle { width: parent.width; height: 1; color: root.muted; opacity: 0.3 }
      Repeater {
        model: ["Applications", "Appearance", "Workspaces", "Settings"]
        Rectangle {
          required property int index
          required property string modelData
          width: parent.width; height: 25; radius: 4
          color: index === 0 ? root.accent : "transparent"
          Text { anchors.fill: parent; anchors.leftMargin: 7; verticalAlignment: Text.AlignVCenter; text: modelData + "  ›"; color: parent.index === 0 ? root.background : root.foreground; font.pixelSize: 10; textFormat: Text.PlainText }
        }
      }
    }
  }

  Rectangle {
    anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter
    width: dockIcons.width + 18; height: 24; radius: 7
    color: Qt.tint(root.background, Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08))
    Row { id: dockIcons; anchors.centerIn: parent; spacing: 12
      Repeater {
        model: [">_", "◎", "▰", "◇", "♫"]
        Text { required property string modelData; text: modelData; color: root.foreground; font.pixelSize: 12; textFormat: Text.PlainText }
      }
    }
  }
}
