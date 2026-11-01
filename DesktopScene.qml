import QtQuick
import QtQuick.Layouts
import qs.Commons

Item {
  id: root
  property string scene: "welcome"
  property string glyph: "◈"
  property string appLabel: "Omadojo"
  property string applicationId: "terminal"
  property string lessonToken: ""
  property bool solved: false
  property color accent
  property color foreground
  property color background
  property bool demoAfter: false
  readonly property bool demonstrating: scene !== "welcome" && !solved

  function resetDemo() {
    demoAfter = false
    if (demonstrating && !Style.reduceMotion) demonstration.restart()
    else demonstration.stop()
  }
  onLessonTokenChanged: resetDemo()
  onSceneChanged: resetDemo()
  onSolvedChanged: resetDemo()

  SequentialAnimation {
    id: demonstration
    running: root.demonstrating && !Style.reduceMotion
    loops: Animation.Infinite
    ScriptAction { script: root.demoAfter = false }
    PauseAnimation { duration: 1100 }
    ScriptAction { script: root.demoAfter = true }
    PauseAnimation { duration: 1900 }
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 10
    RowLayout {
      Layout.fillWidth: true; Layout.preferredHeight: 24
      Rectangle { width: 6; height: 6; radius: 3; color: root.accent }
      Text {
        text: root.solved ? "✓  COMPLETED" : root.demonstrating ? (Style.reduceMotion ? "GOAL" : "WATCH THE ACTION  ·  LOOPING PREVIEW") : "YOUR PRACTICE DESKTOP"
        color: root.accent; font.pixelSize: 10; font.letterSpacing: 2; textFormat: Text.PlainText
      }
      Item { Layout.fillWidth: true }
      Text {
        visible: root.demonstrating && !Style.reduceMotion
        text: root.demoAfter ? "ACTION" : "START"
        color: root.foreground; opacity: 0.6; font.pixelSize: 10; font.letterSpacing: 1.5; textFormat: Text.PlainText
      }
    }
    SimDesktop {
      Layout.fillWidth: true; Layout.fillHeight: true
      scene: root.scene
      after: root.solved || root.demoAfter || (root.demonstrating && Style.reduceMotion)
      animateChanges: root.solved || root.demoAfter
      applicationId: root.applicationId; appLabel: root.appLabel
      accent: root.accent; foreground: root.foreground; background: root.background
    }
  }
}
