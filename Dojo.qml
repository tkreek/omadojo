import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Commons as Commons
import "Engine.js" as Engine
import "Lessons.js" as Lessons

Item {
  id: root
  property var shell: null
  property var manifest: null
  property bool opened: false
  property string phase: "ready"
  property string category: "All shortcuts"
  property var categories: ["All shortcuts", "Applications", "Windows", "Workspaces", "Navigation", "Desktop", "Plugins"]
  property var available: []
  property var round: []
  property int index: 0
  property int roundLength: 15
  property var score: Engine.initial(Date.now())
  property double now: Date.now()
  property string feedback: ""
  property bool hintShown: false
  property bool solved: false
  property string error: ""
  property var prompt: round.length ? round[Math.min(index, round.length - 1)] : null
  readonly property var metrics: Engine.stats(score, now)
  readonly property bool practicing: phase === "running"
  readonly property color bg: Commons.Color.background
  readonly property color fg: Commons.Color.foreground
  readonly property color accent: Commons.Color.accent
  readonly property color muted: Qt.rgba(fg.r, fg.g, fg.b, 0.55)
  readonly property color surface: Qt.tint(bg, Qt.rgba(fg.r, fg.g, fg.b, 0.04))
  readonly property color line: Qt.rgba(fg.r, fg.g, fg.b, 0.13)
  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
  function t(key) { return strings.t(key) }
  function open(payload) {
    opened = true
    error = ""
    phase = "loading"
    bindings.running = true
    if (!cursorGuard.running) cursorGuard.running = true
    Qt.callLater(function() { catcher.forceActiveFocus() })
  }
  function close() {
    advance.stop()
    opened = false
    if (cursorGuard.running) cursorGuard.write("stop\n")
    releaseCapture()
    phase = "ready"
  }
  function dismiss() {
    close()
    if (shell && typeof shell.hide === "function") shell.hide("io.github.tkreek.omadojo")
  }
  function toggle() { if (opened) dismiss(); else open("{}") }
  function releaseCapture() { if (capture.running) capture.write("stop\n") }
  function start() {
    if (phase !== "ready" && phase !== "results") return
    var pool = Engine.categoryItems(available, category)
    if (!pool.length) { error = t("noLessons"); return }
    advance.stop()
    round = Engine.deck(pool, roundLength, Math.random)
    index = 0; solved = false; hintShown = false; feedback = ""; error = ""
    phase = "arming"
    capture.running = true
    catcher.forceActiveFocus()
  }
  function submit(chord) {
    if (!practicing || solved || !prompt) return
    var correct = chord === prompt.chord
    score = Engine.answer(score, correct, Date.now())
    now = Date.now()
    if (!correct) { feedback = chord.split("+").join(" + "); return }
    feedback = ""; solved = true
    advance.restart()
  }
  function hint() {
    if (!practicing || hintShown || solved) return
    score = Engine.hint(Engine.answer(score, false, Date.now()))
    hintShown = true
    catcher.forceActiveFocus()
  }
  function eventChord(event) {
    var key = event.key
    var names = {}
    names[Qt.Key_Return] = "ENTER"; names[Qt.Key_Enter] = "ENTER"
    names[Qt.Key_Space] = "SPACE"; names[Qt.Key_Tab] = "TAB"; names[Qt.Key_Backtab] = "TAB"
    names[Qt.Key_Left] = "LEFT"; names[Qt.Key_Right] = "RIGHT"
    names[Qt.Key_Up] = "UP"; names[Qt.Key_Down] = "DOWN"
    names[Qt.Key_Home] = "HOME"; names[Qt.Key_End] = "END"
    names[Qt.Key_Backspace] = "BACKSPACE"; names[Qt.Key_Delete] = "DELETE"
    var value = names[key] || ((key >= Qt.Key_A && key <= Qt.Key_Z) || (key >= Qt.Key_0 && key <= Qt.Key_9) ? String.fromCharCode(key) : event.text)
    if (!value) value = "KEY " + key
    var mods = 0
    if (event.modifiers & Qt.MetaModifier) mods |= 64
    if (event.modifiers & Qt.ControlModifier) mods |= 4
    if (event.modifiers & Qt.AltModifier) mods |= 8
    if (event.modifiers & Qt.ShiftModifier) mods |= 1
    return Engine.chord(value, mods)
  }

  Process {
    id: bindings
    command: ["hyprctl", "binds", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var live = JSON.parse(text)
          available = Engine.resolve(Lessons.lessons, live)
          // Third-party described shortcuts become an additional practice deck.
          var seen = {}
          available.forEach(function(item) { seen[item.chord] = true })
          var plugins = []
          live.forEach(function(binding) {
            if (!Engine.usable(binding) || !binding.description) return
            if (!/omarchy-shell|global/.test(String(binding.dispatcher) + " " + String(binding.arg)) && !/plugin|mission control|overview|omaland|switcher/i.test(binding.description)) return
            var chord = Engine.chord(Engine.bindingKey(binding), Number(binding.modmask))
            if (seen[chord]) return
            seen[chord] = true
            plugins.push({ id: "plugin-" + chord, category: "Plugins", description: binding.description,
              title: binding.description, detail: t("pluginLesson"), scene: "menu", glyph: "◇", label: binding.description, chord: chord })
          })
          available = available.concat(plugins)
          // Universal shortcuts ignore submaps. Do not begin an unsafe drill.
          var universal = live.some(function(binding) { return binding.submap_universal === true || binding.submap_universal === "true" })
          if (universal) { error = t("universalBinds"); phase = "blocked" }
          else phase = "ready"
        } catch (e) { error = t("readFailed") + " " + String(e); phase = "blocked" }
      }
    }
    onExited: function(code) { if (code !== 0) { phase = "blocked"; error = t("readFailed") } }
  }
  Process {
    id: cursorGuard
    command: ["python3", Qt.resolvedUrl("capture.py").toString().replace(/^file:\/\//, ""), "--cursor"]
    stdinEnabled: true
    stdout: SplitParser {
      onRead: function(data) {
        try { var result = JSON.parse(data); if (result.error) root.error = result.error }
        catch (e) { console.warn("Omadojo cursor guard:", String(e)) }
      }
    }
  }
  Timer { interval: 1000; repeat: true; running: cursorGuard.running && opened; onTriggered: cursorGuard.write("heartbeat\n") }

  Process {
    id: capture
    command: ["python3", Qt.resolvedUrl("capture.py").toString().replace(/^file:\/\//, "")]
    stdinEnabled: true
    stdout: SplitParser {
      onRead: function(data) {
        try {
          var result = JSON.parse(data)
          if (result.ready && phase === "arming" && opened) {
            phase = "running"; score = Engine.initial(Date.now()); now = Date.now()
          } else if (result.error) { error = result.error; phase = "ready" }
        } catch (e) { error = t("captureFailed"); phase = "ready" }
      }
    }
    onExited: function(code) {
      if (phase === "running" || phase === "arming") {
        error = t("captureEnded")
        phase = "ready"
      }
    }
  }
  Timer { interval: 1000; repeat: true; running: capture.running && opened && (phase === "running" || phase === "arming"); onTriggered: capture.write("heartbeat\n") }
  Timer { interval: 50; repeat: true; running: practicing && !solved; onTriggered: now = Date.now() }
  Timer {
    id: advance; interval: 500
    onTriggered: {
      if (!practicing) return
      if (index + 1 >= round.length) {
        phase = "results"; releaseCapture()
      } else {
        index++; hintShown = false; solved = false
        score = Object.assign({}, score, { promptAt: Date.now() })
      }
    }
  }
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!opened) return
      if (event.name === "configreloaded" || (event.name === "submap" && practicing && event.data !== "omadojo-practice")) {
        releaseCapture(); phase = "ready"; error = t("captureEnded")
      }
    }
  }
  Component.onDestruction: {
    releaseCapture()
    if (cursorGuard.running) cursorGuard.write("stop\n")
  }

  PanelWindow {
    id: window
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: root.bg
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omadojo"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Item {
      id: catcher
      anchors.fill: parent
      focus: true
      HoverHandler { cursorShape: Qt.ArrowCursor }
      Keys.onPressed: function(event) {
        event.accepted = true
        if (event.isAutoRepeat) return
        if (event.key === Qt.Key_Escape) { root.dismiss(); return }
        if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_CapsLock].indexOf(event.key) >= 0) return
        if (root.practicing) root.submit(root.eventChord(event))
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.start()
        else if (root.phase === "ready" || root.phase === "results") {
          if (event.modifiers === Qt.NoModifier && event.key >= Qt.Key_1 && event.key <= Qt.Key_7)
            root.category = root.categories[event.key - Qt.Key_1]
        }
      }
      Keys.onReleased: function(event) { event.accepted = true }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(24, Math.min(window.width, window.height) * 0.045)
        spacing: 22
        RowLayout {
          Layout.fillWidth: true
          Text { text: "◈"; color: root.accent; font.pixelSize: 33; textFormat: Text.PlainText }
          ColumnLayout {
            spacing: 2
            Text { text: "OMADOJO"; color: root.fg; font.pixelSize: 20; font.weight: Font.Bold; font.letterSpacing: 5; textFormat: Text.PlainText }
            Text { text: root.t("tagline"); color: root.muted; font.pixelSize: 12; textFormat: Text.PlainText }
          }
          Item { Layout.fillWidth: true }
          Rectangle {
            implicitWidth: status.implicitWidth + 28; implicitHeight: 34; radius: 17
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.1)
            Text { id: status; anchors.centerIn: parent; text: root.practicing ? root.t("captureActive") : root.t("practiceSpace"); color: root.accent; font.pixelSize: 12; textFormat: Text.PlainText }
          }
          DojoButton { label: root.t("exit"); onClicked: root.dismiss() }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 16
          Repeater {
            model: [ {label: root.t("time"), value: root.metrics.seconds.toFixed(1) + "s"},
              {label: root.t("accuracy"), value: root.score.attempts ? root.metrics.accuracy + "%" : "—"},
              {label: root.t("streak"), value: String(root.score.streak)},
              {label: root.t("progress"), value: root.practicing ? (root.index + 1) + " / " + root.round.length : root.phase === "results" ? root.round.length + " / " + root.round.length : "0 / " + root.roundLength} ]
            Rectangle {
              required property var modelData
              Layout.fillWidth: true; implicitHeight: 74; radius: 12; color: root.surface; border.color: root.line
              Column { anchors.centerIn: parent; spacing: 5
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label.toUpperCase(); color: root.muted; font.pixelSize: 10; font.letterSpacing: 2; textFormat: Text.PlainText }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: root.fg; font.pixelSize: 24; font.family: "monospace"; textFormat: Text.PlainText }
              }
            }
          }
        }

        Text {
          Layout.fillWidth: true
          text: root.practicing ? root.t("practicingCategory") + " " + root.category : root.t("chooseCategory")
          color: root.fg; font.pixelSize: 14; font.weight: Font.DemiBold; textFormat: Text.PlainText
        }
        RowLayout {
          Layout.fillWidth: true
          spacing: 7
          Repeater {
            model: root.categories
            DojoButton {
              required property string modelData
              label: (root.categories.indexOf(modelData) + 1) + "  " + modelData + " · " + Engine.categoryItems(root.available, modelData).length
              selected: root.category === modelData
              opacity: 1
              enabled: !root.practicing && root.phase !== "arming"
              onClicked: { root.category = modelData; root.error = ""; catcher.forceActiveFocus() }
            }
          }
          Item { Layout.fillWidth: true }
          DojoButton { label: root.roundLength + " " + root.t("rounds"); enabled: !root.practicing && root.phase !== "arming"; onClicked: root.roundLength = root.roundLength === 15 ? 30 : 15 }
        }

        Text {
          Layout.fillWidth: true; wrapMode: Text.Wrap
          text: root.t("category" + root.category.replace(/ /g, ""))
          color: root.muted; font.pixelSize: 12; textFormat: Text.PlainText
        }

        Rectangle {
          Layout.fillWidth: true; Layout.fillHeight: true
          Layout.minimumHeight: 250
          radius: 20; color: root.surface; border.color: root.solved ? root.accent : root.line
          ColumnLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 14
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: root.phase === "results" ? root.t("roundComplete") : root.practicing && root.prompt ? root.prompt.category.toUpperCase() + "  /  " + root.t("challenge") + " " + (root.index + 1) : root.t("welcome")
              color: root.accent; font.pixelSize: 11; font.letterSpacing: 2; textFormat: Text.PlainText
            }
            Text {
              Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
              text: root.phase === "results" ? root.metrics.score + " " + root.t("points") : root.practicing && root.prompt ? root.prompt.title : root.t("headline")
              color: root.fg; font.pixelSize: Math.min(34, window.width / 35); font.weight: Font.DemiBold; textFormat: Text.PlainText
            }
            Text {
              Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
              text: root.phase === "results" ? root.metrics.average.toFixed(2) + "s " + root.t("average") + "   ·   " + root.metrics.perMinute.toFixed(1) + " " + root.t("perMinute") + "   ·   " + root.t("bestStreak") + " " + root.score.bestStreak : root.practicing && root.prompt ? root.prompt.detail : root.t("intro")
              color: root.muted; font.pixelSize: 14; textFormat: Text.PlainText
            }
            DesktopScene {
              Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 130
              scene: root.practicing && root.prompt ? root.prompt.scene : "welcome"
              glyph: root.practicing && root.prompt ? root.prompt.glyph : root.phase === "results" ? "✓" : "◈"
              lessonToken: root.practicing && root.prompt ? root.prompt.id + "-" + root.index : "welcome"
              applicationId: root.practicing && root.prompt ? root.prompt.id : "terminal"
              appLabel: root.practicing && root.prompt ? root.prompt.label : "Omadojo"
              solved: root.solved || root.phase === "results"
              accent: root.accent; foreground: root.fg; background: root.bg
            }
            Text {
              Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
              text: root.solved ? root.t("correct") : root.hintShown && root.prompt ? root.prompt.chord.split("+").join("  +  ") : root.feedback ? root.t("tryAgain") + "  " + root.feedback : root.practicing ? root.t("yourMove") : root.t("startNote")
              color: root.solved || root.hintShown ? root.accent : root.feedback ? Commons.Color.urgent : root.muted
              font.family: "monospace"; font.pixelSize: 16; textFormat: Text.PlainText
            }
            RowLayout {
              Layout.alignment: Qt.AlignHCenter
              DojoButton { visible: root.practicing; label: root.t("hint"); onClicked: root.hint() }
              DojoButton {
                visible: !root.practicing; selected: true
                label: root.phase === "loading" ? root.t("loading") : root.phase === "arming" ? root.t("arming") : root.phase === "results" ? root.t("again") : root.t("start")
                enabled: (root.phase === "ready" || root.phase === "results") && !capture.running
                onClicked: root.start()
              }
            }
          }
        }
        Text { visible: root.error !== ""; Layout.fillWidth: true; text: root.error; color: Commons.Color.urgent; wrapMode: Text.Wrap; textFormat: Text.PlainText; font.pixelSize: 13 }
        RowLayout {
          Layout.fillWidth: true
          Text { text: root.t("footer"); color: root.muted; font.pixelSize: 12; textFormat: Text.PlainText }
          Item { Layout.fillWidth: true }
          Text { text: root.available.length + " " + root.t("available"); color: root.muted; font.pixelSize: 12; textFormat: Text.PlainText }
        }
      }
    }
  }
}
