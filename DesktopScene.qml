import QtQuick
import qs.Commons

Item {
  id: root
  property string scene: "welcome"
  property string glyph: "◈"
  property string appLabel: ""
  property bool solved: false
  property color accent
  property color foreground
  property color background
  readonly property bool single: ["launch", "float", "fullscreen", "menu", "welcome"].indexOf(scene) >= 0
  Rectangle {
    id: desktop
    anchors.centerIn: parent
    width: Math.min(parent.width - 20, 700); height: Math.min(parent.height - 10, 300)
    radius: 12; color: root.background
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)
    Rectangle {
      x: 1; y: 1; width: parent.width - 2; height: 27; radius: 10
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
      Row {
        x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 12
        Repeater {
          model: 4
          Text {
            required property int index
            text: index + 1; textFormat: Text.PlainText; font.pixelSize: 11
            color: index === ((root.scene === "workspace" || root.scene === "move") && root.solved ? 1 : 0) ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
          }
        }
      }
      Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "SIMULATED DESKTOP"; textFormat: Text.PlainText; font.pixelSize: 8; font.letterSpacing: 1.5; color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.4) }
    }
    Repeater {
      model: root.single ? 1 : 2
      Rectangle {
        id: tile
        required property int index
        readonly property bool target: root.scene === "left" ? index === 0 : index === 1 || root.single
        readonly property bool full: root.scene === "fullscreen" && root.solved
        x: root.single ? (parent.width - width) / 2 : 16 + (parent.width - 24) / 2 * ((root.scene === "swap" && root.solved) ? 1 - index : index)
        y: full ? 32 : root.scene === "float" && root.solved ? 55 : 45
        width: full ? parent.width - 16 : root.single ? parent.width * 0.58 : parent.width / 2 - 24
        height: full ? parent.height - 40 : parent.height - 66
        radius: 8
        color: Qt.tint(root.background, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, target ? 0.12 : 0.03))
        border.width: target ? 2 : 1
        border.color: target ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)
        opacity: root.scene === "close" && root.solved && target ? 0 : 1
        Behavior on x { NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Style.duration(120) } }
        Row {
          x: 10; y: 9; spacing: 4
          Repeater { model: 3; Rectangle { width: 4; height: 4; radius: 2; color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3) } }
        }
        Column {
          anchors.centerIn: parent; spacing: 9
          Text { anchors.horizontalCenter: parent.horizontalCenter; text: tile.target ? root.glyph : "▤"; textFormat: Text.PlainText; color: tile.target ? root.accent : root.foreground; font.pixelSize: Math.min(38, tile.height / 3) }
          Text { anchors.horizontalCenter: parent.horizontalCenter; width: tile.width - 20; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tile.target ? root.appLabel : "Workspace"; textFormat: Text.PlainText; color: root.foreground; font.pixelSize: 12 }
        }
      }
    }
  }
}
