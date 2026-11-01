import QtQuick

// Renders a chord such as "SUPER+SHIFT+ENTER" as a row of key caps.
Row {
  id: root
  property string chord: ""
  property color tint: "white"
  property color text: tint
  property int size: 16
  spacing: Math.round(size * 0.4)

  function pretty(part) {
    var names = { SUPER: "Super", CTRL: "Ctrl", ALT: "Alt", SHIFT: "Shift", ENTER: "Enter", SPACE: "Space",
      TAB: "Tab", LEFT: "←", RIGHT: "→", UP: "↑", DOWN: "↓", BACKSPACE: "⌫", DELETE: "Del", ESCAPE: "Esc", HOME: "Home", END: "End",
      MINUS: "−", EQUAL: "=", COMMA: ",", PERIOD: ".", SLASH: "/", GRAVE: "`", BRACKETLEFT: "[", BRACKETRIGHT: "]", PRINT: "Print" }
    return names[part] || part
  }

  Repeater {
    model: root.chord ? root.chord.split("+") : []
    Rectangle {
      required property string modelData
      implicitWidth: Math.max(implicitHeight, cap.implicitWidth + root.size)
      implicitHeight: Math.round(root.size * 2)
      width: implicitWidth; height: implicitHeight
      radius: Math.round(root.size * 0.4)
      color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.12)
      border.width: 1
      border.color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.55)
      // A thicker bottom edge so it reads as a physical key.
      Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.leftMargin: parent.radius / 2; anchors.rightMargin: parent.radius / 2
        height: 2; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.55)
      }
      Text {
        id: cap
        anchors.centerIn: parent
        text: root.pretty(parent.modelData)
        color: root.text
        font.pixelSize: root.size; font.weight: Font.DemiBold; font.family: "monospace"
        textFormat: Text.PlainText
      }
    }
  }
}
