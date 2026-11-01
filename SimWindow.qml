import QtQuick
import qs.Commons

Rectangle {
  id: root
  property string kind: "terminal"
  property string title: "Terminal"
  property bool active: false
  property color accent
  property color foreground
  property color background
  readonly property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.45)
  radius: 7; clip: true
  color: Qt.tint(background, Qt.rgba(foreground.r, foreground.g, foreground.b, 0.04))
  border.width: active ? 2 : 1
  border.color: active ? accent : Qt.rgba(foreground.r, foreground.g, foreground.b, 0.2)
  Behavior on border.color { ColorAnimation { duration: Style.duration(160) } }
  Rectangle {
    x: 2; y: 2; width: parent.width - 4; height: 23
    color: root.active ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.13) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
    Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.right: controls.left; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; text: root.title; elide: Text.ElideRight; color: root.foreground; font.pixelSize: 9; textFormat: Text.PlainText }
    Text { id: controls; anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter; text: "−  □  ×"; color: root.muted; font.pixelSize: 9; textFormat: Text.PlainText }
  }
  Item {
    x: 9; y: 34; width: parent.width - 18; height: parent.height - 43; clip: true
    Column {
      visible: root.kind === "terminal"
      width: parent.width; spacing: 7
      Repeater {
        model: ["~/Projects ❯", "$ ls", "omadojo/  notes/", "$ git status", "On branch main", "Working tree clean", "❯ ▌"]
        Text { required property int index; required property string modelData; width: parent.width; text: modelData; elide: Text.ElideRight; color: index === 0 || index === 6 ? root.accent : root.foreground; font.family: "monospace"; font.pixelSize: 9; textFormat: Text.PlainText }
      }
    }
    Column {
      visible: root.kind === "browser"; width: parent.width; spacing: 10
      Rectangle { width: parent.width; height: 18; radius: 4; color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
        Text { anchors.centerIn: parent; text: "⌕  omarchy.org"; color: root.muted; font.pixelSize: 8; textFormat: Text.PlainText }
      }
      Text { text: "Omarchy"; color: root.accent; font.pixelSize: 18; font.bold: true; textFormat: Text.PlainText }
      Text { width: parent.width; text: "Your keyboard.\nYour kind of desktop."; color: root.foreground; font.pixelSize: 10; textFormat: Text.PlainText }
      Repeater { model: 3; Rectangle { required property int index; width: parent.width * (0.9 - index * 0.12); height: 4; radius: 2; color: root.muted; opacity: 0.25 } }
    }
    Column {
      visible: root.kind === "editor"; width: parent.width; spacing: 8
      Repeater {
        model: ["1  # A little practice", "2", "3  Build muscle memory.", "4  One shortcut at a time.", "5", "6  ## Today's focus", "7  - Make it feel natural."]
        Text { required property int index; required property string modelData; text: modelData; width: parent.width; elide: Text.ElideRight; color: index === 0 || index === 5 ? root.accent : root.foreground; font.family: "monospace"; font.pixelSize: 9; textFormat: Text.PlainText }
      }
    }
    Column {
      visible: root.kind === "files"; width: parent.width; spacing: 10
      Text { text: "Home  /  Projects"; color: root.muted; font.pixelSize: 9; textFormat: Text.PlainText }
      Repeater {
        model: ["▰  omadojo", "▰  screenshots", "▰  notes", "▤  README.md", "▤  ideas.txt"]
        Text { required property string modelData; text: modelData; color: root.foreground; font.pixelSize: 10; textFormat: Text.PlainText }
      }
    }
    Column {
      visible: root.kind === "calculator"; width: parent.width; spacing: 10
      Text { text: "128 × 4"; color: root.muted; font.pixelSize: 12; textFormat: Text.PlainText }
      Text { text: "512"; color: root.accent; font.pixelSize: 30; textFormat: Text.PlainText }
      Text { text: "7   8   9   ÷\n4   5   6   ×\n1   2   3   −\n0   .   =   +"; color: root.foreground; font.family: "monospace"; font.pixelSize: 12; lineHeight: 1.5; textFormat: Text.PlainText }
    }
    Column {
      visible: root.kind === "music"; width: parent.width; spacing: 14
      Rectangle { width: Math.min(parent.width, 70); height: width; radius: 8; color: root.accent
        Text { anchors.centerIn: parent; text: "♫"; color: root.background; font.pixelSize: 36; textFormat: Text.PlainText }
      }
      Text { text: "Good music, good focus.\n\n◁    ▷    ▷|"; color: root.foreground; font.pixelSize: 10; textFormat: Text.PlainText }
    }
  }
}
