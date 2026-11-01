import QtQuick
import QtQuick.Layouts
import qs.Commons

Item {
  id: root
  property string scene: "welcome"
  property string glyph: "◈"
  property string appLabel: "Omadojo"
  property string applicationId: "terminal"
  property bool solved: false
  property color accent
  property color foreground
  property color background
  readonly property bool compact: width < 640
  RowLayout {
    anchors.fill: parent
    spacing: root.compact ? 10 : 24
    Repeater {
      model: 2
      ColumnLayout {
        id: stage
        required property int index
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.minimumWidth: 0
        spacing: 10
        RowLayout {
          Layout.fillWidth: true; Layout.preferredHeight: 24
          Rectangle { width: 6; height: 6; radius: 3; color: stage.index === 1 ? root.accent : root.foreground; opacity: stage.index === 1 ? 1 : 0.4 }
          Text {
            text: stage.index === 0 ? (root.solved ? "COMPLETED" : "CURRENT") : "TARGET"
            color: stage.index === 1 ? root.accent : root.foreground
            opacity: stage.index === 1 ? 1 : 0.6
            font.pixelSize: 10; font.letterSpacing: 2; textFormat: Text.PlainText
          }
          Item { Layout.fillWidth: true }
          Text { visible: stage.index === 1; text: root.solved ? "✓" : "→"; color: root.accent; font.pixelSize: 18; textFormat: Text.PlainText }
        }
        SimDesktop {
          Layout.fillWidth: true; Layout.fillHeight: true
          scene: root.scene; after: stage.index === 1 || root.solved
          applicationId: root.applicationId; appLabel: root.appLabel
          accent: root.accent; foreground: root.foreground; background: root.background
        }
      }
    }
  }
}
