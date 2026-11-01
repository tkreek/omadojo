import QtQuick
import qs.Commons
import qs.Commons as Commons
Rectangle {
  id: root
  property string label: ""
  property bool selected: false
  signal clicked()
  implicitWidth: labelText.implicitWidth + 26
  implicitHeight: 36
  radius: 8
  color: selected ? Commons.Color.accent : mouse.containsMouse ? Style.hoverFill : "transparent"
  border.color: selected ? "transparent" : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.18)
  opacity: enabled ? 1 : 0.45
  Text {
    id: labelText; anchors.centerIn: parent
    text: root.label; textFormat: Text.PlainText; font.pixelSize: 12
    color: root.selected ? Commons.Color.background : Commons.Color.foreground
  }
  MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
