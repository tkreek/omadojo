import QtQuick
import qs.Commons

// The practice desktop. The large desktop holds the starting state and only
// performs an action when the user presses a shortcut: the right one plays the
// lesson, a wrong one plays whatever that shortcut really does and flashes red.
// A small preview window demonstrates the correct action twice, then rests on
// the result with a replay control.
Item {
  id: root
  property string scene: "welcome"
  property var sceneArg: ""
  property string lessonToken: ""
  property bool solved: false
  property bool previewEnabled: true
  property color accent
  property color foreground
  property color background
  property color danger: "#e06c75"
  readonly property bool demonstrating: scene !== "welcome" && !solved

  // Preview state
  property int previewPlays: 3
  property int previewPass: 0
  property bool previewAfter: false
  property bool previewDone: false

  // Wrong-press playback state
  property bool mistaking: false
  property string mistakeScene: ""
  property var mistakeArg: ""
  property string mistakeChord: ""
  property string mistakeText: ""
  property bool mistakeAfter: false

  function replay() {
    previewAfter = false
    previewPass = 0
    previewDone = false
    demonstration.stop()
    viewport.opacity = 1
    if (!demonstrating || !previewEnabled) return
    if (Style.reduceMotion) { previewAfter = true; previewDone = true; return }
    demonstration.start()
  }
  function clearMistake() {
    mistakeAnimation.stop()
    mistaking = false; mistakeAfter = false; mistakeScene = ""
  }
  // Act out what a wrong shortcut does, flash red, then return to the lesson.
  function showMistake(chord, scene, arg, description) {
    clearMistake()
    demonstration.stop()
    mistakeChord = chord
    mistakeScene = scene || ""
    mistakeArg = arg === undefined ? "" : arg
    mistakeText = description
    mistakeAnimation.start()
    dangerFlash.restart()
  }
  onLessonTokenChanged: { clearMistake(); replay() }
  onSceneChanged: { clearMistake(); replay() }
  onSceneArgChanged: { clearMistake(); replay() }
  onSolvedChanged: { clearMistake(); replay(); if (solved) successFlash.restart() }
  onPreviewEnabledChanged: replay()
  Component.onCompleted: replay()

  SequentialAnimation {
    id: demonstration
    loops: root.previewPlays
    // Fade back to the starting state between passes so each repeat reads
    // as a fresh replay rather than a jump.
    NumberAnimation { target: viewport; property: "opacity"; to: 0.15; duration: 160 }
    ScriptAction { script: { root.previewAfter = false; root.previewPass++ } }
    NumberAnimation { target: viewport; property: "opacity"; to: 1; duration: 160 }
    PauseAnimation { duration: 1000 }
    ScriptAction { script: root.previewAfter = true }
    PauseAnimation { duration: 1600 }
    onFinished: root.previewDone = true
  }

  SequentialAnimation {
    id: mistakeAnimation
    ScriptAction { script: { root.mistaking = true; root.mistakeAfter = false } }
    PauseAnimation { duration: 60 }
    ScriptAction { script: root.mistakeAfter = root.mistakeScene !== "" }
    PauseAnimation { duration: Style.reduceMotion ? 900 : 1500 }
    ScriptAction { script: root.mistakeAfter = false }
    PauseAnimation { duration: 320 }
    ScriptAction { script: { root.mistaking = false; root.mistakeScene = ""; root.replay() } }
  }

  readonly property bool playingMistake: mistaking && mistakeScene !== ""

  SimDesktop {
    id: main
    anchors.fill: parent
    scene: root.playingMistake ? root.mistakeScene : root.scene
    after: root.solved || (root.playingMistake && root.mistakeAfter)
    animateChanges: root.solved || root.mistaking
    arg: root.playingMistake ? root.mistakeArg : root.sceneArg
    accent: root.mistaking ? root.danger : root.accent
    foreground: root.foreground; background: root.background
    border.width: root.solved || root.mistaking ? 2 : 1
    border.color: root.mistaking ? root.danger : root.solved ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)
  }

  // Full-desktop colour flashes for right and wrong answers.
  Rectangle {
    id: flash
    anchors.fill: parent; radius: main.radius
    color: root.danger; opacity: 0
    SequentialAnimation {
      id: dangerFlash
      PropertyAction { target: flash; property: "color"; value: root.danger }
      NumberAnimation { target: flash; property: "opacity"; from: 0; to: 0.28; duration: 90 }
      NumberAnimation { target: flash; property: "opacity"; to: 0.08; duration: 450; easing.type: Easing.OutCubic }
      PauseAnimation { duration: 900 }
      NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 400 }
    }
    SequentialAnimation {
      id: successFlash
      PropertyAction { target: flash; property: "color"; value: root.accent }
      NumberAnimation { target: flash; property: "opacity"; from: 0; to: 0.18; duration: 90 }
      NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 700; easing.type: Easing.OutCubic }
    }
  }

  // What the wrong shortcut was, pinned to the top of the desktop while it plays.
  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.mistaking ? 44 : 30
    opacity: root.mistaking ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Style.duration(160) } }
    Behavior on y { NumberAnimation { duration: Style.duration(200); easing.type: Easing.OutCubic } }
    z: 20
    width: mistakeRow.implicitWidth + 32; height: mistakeRow.implicitHeight + 20
    radius: height / 2
    color: Qt.tint(root.background, Qt.rgba(root.danger.r, root.danger.g, root.danger.b, 0.2))
    border.color: root.danger; border.width: 1.5
    Row {
      id: mistakeRow
      anchors.centerIn: parent
      spacing: 12
      Text { anchors.verticalCenter: parent.verticalCenter; text: "✗"; color: root.danger; font.pixelSize: 18; font.weight: Font.Bold; textFormat: Text.PlainText }
      KeyCaps { anchors.verticalCenter: parent.verticalCenter; chord: root.mistakeChord; tint: root.danger; text: root.foreground; size: 13 }
      Text { anchors.verticalCenter: parent.verticalCenter; text: root.mistakeText; color: root.foreground; font.pixelSize: 15; textFormat: Text.PlainText }
    }
  }

  // Soft shadow behind the preview so it reads as floating above the desktop.
  Rectangle {
    x: pip.x + 4; y: pip.y + 6; width: pip.width; height: pip.height
    radius: pip.radius; color: Qt.rgba(0, 0, 0, 0.35)
    opacity: pip.opacity; visible: pip.visible
  }

  Rectangle {
    id: pip
    readonly property int headerHeight: 28
    anchors.left: parent.left; anchors.bottom: parent.bottom
    anchors.leftMargin: 22; anchors.bottomMargin: 22
    width: Math.round(Math.max(260, root.width * 0.3))
    height: headerHeight + Math.round(width * root.height / Math.max(1, root.width))
    radius: 12
    clip: true
    color: Qt.tint(root.background, Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06))
    border.width: 1.5
    border.color: root.accent
    readonly property bool shown: root.demonstrating && root.previewEnabled && !root.mistaking
    opacity: shown ? (root.previewDone ? 0.8 : 1) : 0
    visible: opacity > 0
    scale: shown ? 1 : 0.94
    transformOrigin: Item.BottomLeft
    Behavior on opacity { NumberAnimation { duration: Style.duration(200); easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Style.duration(220); easing.type: Easing.OutCubic } }

    Item {
      id: header
      x: 12; width: parent.width - 24; height: pip.headerHeight
      Rectangle {
        id: dot
        anchors.verticalCenter: parent.verticalCenter
        width: 6; height: 6; radius: 3; color: root.accent
        SequentialAnimation on opacity {
          running: pip.visible && !root.previewDone && !Style.reduceMotion
          loops: Animation.Infinite
          NumberAnimation { to: 0.25; duration: 500 }
          NumberAnimation { to: 1; duration: 500 }
        }
      }
      Text {
        anchors.left: dot.right; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
        text: "GOAL"
        color: root.accent; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 2; textFormat: Text.PlainText
      }
      Text {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        text: root.previewDone ? "↻  Replay" : Math.max(1, root.previewPass) + " / " + root.previewPlays
        color: root.previewDone && replayMouse.containsMouse ? root.accent : root.foreground
        opacity: root.previewDone ? 0.9 : 0.55
        font.pixelSize: 10; font.family: root.previewDone ? Qt.application.font.family : "monospace"; textFormat: Text.PlainText
      }
    }

    // The same desktop, laid out at a compact virtual size and scaled to fit,
    // so windows and text stay legible at thumbnail size.
    Item {
      id: viewport
      readonly property real virtualWidth: 920
      x: 6; y: pip.headerHeight
      width: pip.width - 12; height: pip.height - pip.headerHeight - 6
      clip: true
      SimDesktop {
        width: viewport.virtualWidth
        height: viewport.virtualWidth * viewport.height / Math.max(1, viewport.width)
        scale: viewport.width / viewport.virtualWidth
        transformOrigin: Item.TopLeft
        smooth: true
        scene: root.scene
        after: root.previewAfter
        animateChanges: root.previewAfter
        arg: root.sceneArg
        accent: root.accent; foreground: root.foreground; background: root.background
      }
    }

    MouseArea {
      id: replayMouse
      anchors.fill: parent
      enabled: root.previewDone && !Style.reduceMotion
      hoverEnabled: true
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: root.replay()
    }
  }
}
