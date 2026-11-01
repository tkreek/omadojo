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
  // "learn": guided keys for new shortcuts, missed ones come back, goal preview.
  // "race": recall only, as fast as possible.
  property string mode: "learn"
  readonly property bool learning: mode === "learn"
  property string category: "All shortcuts"
  readonly property var categories: ["All shortcuts", "Applications", "Windows", "Navigation", "Resize", "Workspaces", "Groups", "Desktop", "More", "Plugins", "Mistakes"]
  property bool deckMenuOpen: false
  property var available: []
  property var bindMap: ({})
  property var round: []
  property int index: 0
  property int roundLength: 10
  property var score: Engine.initial(Date.now())
  property double now: Date.now()
  property string error: ""
  property var prompt: round.length ? round[Math.min(index, round.length - 1)] : null
  readonly property var metrics: Engine.stats(score, now)
  readonly property bool practicing: phase === "running"

  // Per-prompt state
  property bool hintShown: false
  property bool solved: false
  property bool missed: false
  property bool requeued: false
  property string wrongChord: ""
  property string wrongTitle: ""

  // Learning memory, persisted between sessions.
  property var progress: Engine.emptyProgress()
  property var roundMistakes: []
  readonly property string capturePath: decodeURIComponent(Qt.resolvedUrl("capture.py").toString().replace(/^file:\/\//, ""))
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omadojo"
  readonly property int masteredCount: { var p = progress; return available.filter(function(item) { return Engine.mastered(p, item.id) }).length }
  readonly property int mistakeCount: Engine.mistakes(available, progress).length
  readonly property int promptBox: prompt ? Engine.memory(progress, prompt.id).box : 0
  // In learn mode new and weak shortcuts show their keys; retests and known
  // shortcuts must come from memory.
  readonly property bool keysVisible: !!prompt && practicing && (hintShown || (learning && (missed || (!prompt.retest && Engine.guided(progress, prompt.id)))))

  readonly property color bg: Commons.Color.background
  readonly property color fg: Commons.Color.foreground
  readonly property color accent: Commons.Color.accent
  readonly property color danger: Commons.Color.urgent
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
    progressFile.reload()
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
  function pool(name) { return name === "Mistakes" ? Engine.mistakes(available, progress) : Engine.categoryItems(available, name) }
  function setMode(value) { if (!practicing && phase !== "arming") { mode = value; catcher.forceActiveFocus() } }
  function resetPrompt() { hintShown = false; solved = false; missed = false; requeued = false; wrongChord = ""; wrongTitle = "" }
  function start() {
    if (phase !== "ready" && phase !== "results") return
    var items = pool(category)
    if (!items.length) { error = t("noLessons"); return }
    advance.stop()
    round = learning ? Engine.learnDeck(items, progress, roundLength, Math.random) : Engine.deck(items, roundLength, Math.random)
    index = 0; resetPrompt(); error = ""; roundMistakes = []
    phase = "arming"
    capture.running = true
    catcher.forceActiveFocus()
  }
  function remember(outcome, pressed) {
    progress = Engine.record(progress, prompt.id, outcome, pressed, Date.now())
    saveTimer.restart()
  }
  function noteMistake(pressed, pressedTitle) {
    var list = roundMistakes.filter(function(item) { return item.id !== prompt.id })
    var previous = roundMistakes.filter(function(item) { return item.id === prompt.id })[0]
    list.push({ id: prompt.id, title: prompt.title, chord: prompt.chord, pressed: pressed, pressedTitle: pressedTitle,
      count: (previous ? previous.count : 0) + 1 })
    roundMistakes = list
  }
  function submit(chord) {
    if (!practicing || solved || !prompt) return
    var correct = Engine.matches(prompt, chord)
    score = Engine.answer(score, correct, Date.now())
    now = Date.now()
    if (!correct) {
      var lesson = Engine.findByChord(available, chord)
      var title = lesson ? lesson.title : bindMap[chord] ? bindMap[chord] : t("unbound")
      wrongChord = chord; wrongTitle = title
      missed = true
      remember("wrong", chord)
      noteMistake(chord, title)
      if (learning && !requeued) { round = Engine.requeue(round, index, prompt, 3); requeued = true }
      desktop.showMistake(chord, lesson ? lesson.scene : "", lesson ? lesson.arg : "", title)
      return
    }
    remember(missed || hintShown ? "recovered" : "correct", "")
    wrongChord = ""; solved = true
    advance.interval = learning ? 1300 : 450
    advance.restart()
  }
  function hint() {
    if (!practicing || keysVisible || solved) return
    score = Engine.hint(Engine.answer(score, false, Date.now()))
    hintShown = true
    remember("hint", "")
    if (learning && !requeued) { round = Engine.requeue(round, index, prompt, 3); requeued = true }
    catcher.forceActiveFocus()
  }
  function eventChord(event) {
    var key = event.key
    // Number row, minus and equal by XKB keycode, so Shift+2 stays "2" on any layout.
    var byCode = Engine.keycodeName(event.nativeScanCode)
    var names = {}
    names[Qt.Key_Return] = "ENTER"; names[Qt.Key_Enter] = "ENTER"
    names[Qt.Key_Space] = "SPACE"; names[Qt.Key_Tab] = "TAB"; names[Qt.Key_Backtab] = "TAB"
    names[Qt.Key_Left] = "LEFT"; names[Qt.Key_Right] = "RIGHT"
    names[Qt.Key_Up] = "UP"; names[Qt.Key_Down] = "DOWN"
    names[Qt.Key_Home] = "HOME"; names[Qt.Key_End] = "END"
    names[Qt.Key_Backspace] = "BACKSPACE"; names[Qt.Key_Delete] = "DELETE"; names[Qt.Key_Escape] = "ESCAPE"
    names[Qt.Key_Comma] = "COMMA"; names[Qt.Key_Less] = "COMMA"; names[Qt.Key_Period] = "PERIOD"; names[Qt.Key_Greater] = "PERIOD"
    names[Qt.Key_Slash] = "SLASH"; names[Qt.Key_Question] = "SLASH"; names[Qt.Key_QuoteLeft] = "GRAVE"; names[Qt.Key_AsciiTilde] = "GRAVE"
    names[Qt.Key_Minus] = "MINUS"; names[Qt.Key_Underscore] = "MINUS"; names[Qt.Key_Equal] = "EQUAL"; names[Qt.Key_Plus] = "EQUAL"
    names[Qt.Key_BracketLeft] = "BRACKETLEFT"; names[Qt.Key_BraceLeft] = "BRACKETLEFT"; names[Qt.Key_BracketRight] = "BRACKETRIGHT"; names[Qt.Key_BraceRight] = "BRACKETRIGHT"
    names[Qt.Key_Print] = "PRINT"
    var value = byCode || names[key] || ((key >= Qt.Key_A && key <= Qt.Key_Z) || (key >= Qt.Key_0 && key <= Qt.Key_9) ? String.fromCharCode(key) : String(event.text).toUpperCase())
    if (!value) value = "KEY " + key
    var mods = 0
    if (event.modifiers & Qt.MetaModifier) mods |= 64
    if (event.modifiers & Qt.ControlModifier) mods |= 4
    if (event.modifiers & Qt.AltModifier) mods |= 8
    if (event.modifiers & Qt.ShiftModifier) mods |= 1
    return Engine.chord(value, mods)
  }

  // ---- Persistence ----------------------------------------------------------
  Process { running: true; command: ["mkdir", "-p", root.stateDir] }
  FileView {
    id: progressFile
    path: root.stateDir + "/progress.json"
    printErrors: false
    atomicWrites: true
    onLoaded: {
      try { root.progress = Engine.sanitizeProgress(JSON.parse(text())) }
      catch (e) { console.warn("Omadojo progress:", String(e)) }
    }
  }
  Timer { id: saveTimer; interval: 400; onTriggered: progressFile.setText(JSON.stringify(root.progress)) }

  // ---- Shortcuts and capture -------------------------------------------------
  Process {
    id: bindings
    command: ["sh", "-c", "hyprctl binds -j && printf '\\n@@OMADOJO@@\\n' && hyprctl binds"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parts = text.split("@@OMADOJO@@")
          // Keycode binds have an empty key in JSON; recover it from the text output.
          var live = Engine.withTextKeys(JSON.parse(parts[0]), Engine.textKeys(parts[1] || ""))
          var lessons = Engine.resolve(Lessons.lessons, live)
          // Every described binding, so a wrong press can say what it really does.
          var map = {}
          live.forEach(function(binding) {
            if (Engine.usable(binding) && binding.description)
              map[Engine.chord(Engine.bindingKey(binding), Number(binding.modmask))] = binding.description
          })
          bindMap = map
          // Everything else you have bound still gets practised: plugin
          // shortcuts in their own deck, the rest under More.
          var extra = Engine.extraLessons(live, lessons, "More", "toast")
          extra.forEach(function(item) {
            if (/plugin|mission control|overview|omaland|switcher|dock/i.test(item.description)) { item.category = "Plugins"; item.scene = "panel" }
          })
          available = lessons.concat(extra)
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
    command: ["python3", root.capturePath, "--cursor"]
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
    command: ["python3", root.capturePath]
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
        index++; resetPrompt()
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
    if (saveTimer.running) { saveTimer.stop(); progressFile.setText(JSON.stringify(progress)) }
  }

  // ---- UI -------------------------------------------------------------------
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
        var held = event.modifiers & (Qt.MetaModifier | Qt.ControlModifier | Qt.AltModifier)
        if (event.key === Qt.Key_Escape && !held) { if (root.deckMenuOpen) root.deckMenuOpen = false; else root.dismiss(); return }
        if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_CapsLock, Qt.Key_AltGr].indexOf(event.key) >= 0) return
        if (root.practicing) {
          // Lessons always hold Super, Ctrl or Alt (or press Print), so stray
          // typing is ignored rather than graded.
          if (held || event.key === Qt.Key_Print) root.submit(root.eventChord(event))
          else if (event.key === Qt.Key_H) root.hint()
          return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.deckMenuOpen = false; root.start() }
        else if (root.phase === "ready" || root.phase === "results") {
          if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) root.setMode(root.learning ? "race" : "learn")
          else if (event.key === Qt.Key_D) root.deckMenuOpen = !root.deckMenuOpen
          else if (event.key === Qt.Key_M && root.mistakeCount) { root.category = "Mistakes"; root.start() }
          else if (!held && event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            var i = event.key === Qt.Key_0 ? 9 : event.key - Qt.Key_1
            var name = root.categories[i]
            if (name && root.pool(name).length) { root.category = name; root.deckMenuOpen = false }
          }
        }
      }
      Keys.onReleased: function(event) { event.accepted = true }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(16, Math.min(window.width, window.height) * 0.022)
        spacing: 12

        // Top bar: brand, mode, decks, live stats, round size, exit.
        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: false
          spacing: 8
          Text { text: "◈"; color: root.accent; font.pixelSize: 18; textFormat: Text.PlainText }
          Text { text: "OMADOJO"; color: root.fg; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 3; textFormat: Text.PlainText; Layout.rightMargin: 8 }

          // Learn / Race segmented switch
          Rectangle {
            implicitWidth: modeRow.implicitWidth + 6; implicitHeight: 32; radius: 9
            color: "transparent"; border.color: root.line
            opacity: root.practicing || root.phase === "arming" ? 0.45 : 1
            Row {
              id: modeRow; anchors.centerIn: parent; spacing: 2
              Repeater {
                model: [{ key: "learn", label: root.t("learn") }, { key: "race", label: root.t("race") }]
                Rectangle {
                  required property var modelData
                  readonly property bool on: root.mode === modelData.key
                  width: modeText.implicitWidth + 24; height: 26; radius: 7
                  color: on ? root.accent : modeMouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08) : "transparent"
                  Text { id: modeText; anchors.centerIn: parent; text: modelData.label; color: parent.on ? root.bg : root.fg; font.pixelSize: 12; font.weight: Font.DemiBold; textFormat: Text.PlainText }
                  MouseArea { id: modeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setMode(modelData.key) }
                }
              }
            }
          }
          Rectangle { implicitWidth: 1; implicitHeight: 20; color: root.line; Layout.leftMargin: 4; Layout.rightMargin: 4 }

          DojoButton {
            id: deckButton
            implicitHeight: 30
            label: "\u25a6  " + (root.category === "Mistakes" ? root.t("mistakes") : root.category) + "  \u00b7  " + root.pool(root.category).length + "   \u25be"
            selected: root.deckMenuOpen
            enabled: !root.practicing && root.phase !== "arming"
            onClicked: { root.deckMenuOpen = !root.deckMenuOpen; catcher.forceActiveFocus() }
          }
          Item { Layout.fillWidth: true }
          Repeater {
            model: root.learning
              ? [ {label: root.t("progress"), value: root.practicing ? (root.index + 1) + "/" + root.round.length : root.phase === "results" ? root.round.length + "/" + root.round.length : "0/" + root.roundLength},
                  {label: root.t("accuracy"), value: root.score.attempts ? root.metrics.accuracy + "%" : "—"},
                  {label: root.t("mastered"), value: root.masteredCount + "/" + root.available.length} ]
              : [ {label: root.t("time"), value: root.metrics.seconds.toFixed(1) + "s"},
                  {label: root.t("accuracy"), value: root.score.attempts ? root.metrics.accuracy + "%" : "—"},
                  {label: root.t("streak"), value: String(root.score.streak)},
                  {label: root.t("progress"), value: root.practicing ? (root.index + 1) + "/" + root.round.length : root.phase === "results" ? root.round.length + "/" + root.round.length : "0/" + root.roundLength} ]
            Row {
              required property var modelData
              spacing: 6; Layout.rightMargin: 10
              Text { anchors.baseline: value.baseline; text: modelData.label.toUpperCase(); color: root.muted; font.pixelSize: 9; font.letterSpacing: 1.5; textFormat: Text.PlainText }
              Text { id: value; text: modelData.value; color: root.fg; font.pixelSize: 15; font.family: "monospace"; textFormat: Text.PlainText }
            }
          }
          DojoButton { implicitHeight: 30; label: root.roundLength + " " + root.t("rounds"); enabled: !root.practicing && root.phase !== "arming"; onClicked: root.roundLength = root.roundLength >= 30 ? 10 : root.roundLength + 10 }
          DojoButton { implicitHeight: 30; label: root.t("exit"); onClicked: root.dismiss() }
        }

        // Prompt title with mastery dots.
        Row {
          Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4
          spacing: 14
          Text {
            id: titleText
            text: root.phase === "results"
              ? (root.roundMistakes.length ? root.t("reviewTitle") : root.t("cleanRound"))
              : root.practicing && root.prompt ? root.prompt.title : root.t("headline")
            color: root.fg; font.pixelSize: Math.min(28, window.width / 45); font.weight: Font.DemiBold; textFormat: Text.PlainText
          }
          Row {
            visible: root.practicing && !!root.prompt
            anchors.verticalCenter: titleText.verticalCenter
            spacing: 4
            Repeater {
              model: 4
              Rectangle {
                required property int index
                width: 8; height: 8; radius: 4
                color: index < root.promptBox ? root.accent : "transparent"
                border.color: index < root.promptBox ? root.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.3)
              }
            }
          }
        }

        // The answer line: key caps when guided, a recall cue otherwise.
        Item {
          Layout.fillWidth: true; Layout.preferredHeight: 38
          Row {
            anchors.centerIn: parent
            visible: root.keysVisible
            spacing: 14
            KeyCaps { anchors.verticalCenter: parent.verticalCenter; chord: root.prompt ? root.prompt.chord : ""; tint: root.accent; text: root.fg; size: 16 }
            Text { visible: !!root.prompt && !!root.prompt.chords && root.prompt.chords.length > 1; anchors.verticalCenter: parent.verticalCenter; text: root.t("or"); color: root.muted; font.pixelSize: 13; textFormat: Text.PlainText }
            KeyCaps { visible: !!root.prompt && !!root.prompt.chords && root.prompt.chords.length > 1; anchors.verticalCenter: parent.verticalCenter; chord: root.prompt && root.prompt.chords && root.prompt.chords.length > 1 ? root.prompt.chords[1] : ""; tint: root.accent; text: root.fg; size: 13 }
          }
          Text {
            anchors.centerIn: parent
            visible: !root.keysVisible
            text: root.phase === "results"
              ? root.metrics.accuracy + "% " + root.t("accuracy").toLowerCase() + "  ·  " + root.metrics.average.toFixed(2) + "s " + root.t("average") + "  ·  " + root.t("mastered").toLowerCase() + " " + root.masteredCount + "/" + root.available.length
              : root.practicing && root.prompt ? (root.learning ? (root.prompt.retest ? root.t("retest") : root.t("recall")) : "") : ""
            color: root.muted; font.pixelSize: 14; textFormat: Text.PlainText
          }
        }

        // The simulated desktop gets everything else.
        DesktopScene {
          id: desktop
          visible: root.phase !== "results"
          Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 200
          scene: root.practicing && root.prompt ? root.prompt.scene : "welcome"
          lessonToken: root.practicing && root.prompt ? root.prompt.id + "-" + root.index : "welcome"
          sceneArg: root.practicing && root.prompt ? root.prompt.arg : ""
          solved: root.solved
          previewEnabled: root.learning
          accent: root.accent; foreground: root.fg; background: root.bg; danger: root.danger
        }

        // End of round review: what went wrong, what was pressed, what is right.
        Rectangle {
          visible: root.phase === "results"
          Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 200
          radius: 12; color: root.surface; border.color: root.line
          Text {
            visible: !root.roundMistakes.length
            anchors.centerIn: parent
            text: "✓"; color: root.accent; font.pixelSize: 96; textFormat: Text.PlainText
          }
          Flickable {
            visible: root.roundMistakes.length > 0
            anchors.fill: parent; anchors.margins: 28
            contentHeight: reviewColumn.implicitHeight; clip: true
            Column {
              id: reviewColumn
              width: Math.min(parent.width, 1000)
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 10
              Repeater {
                model: root.roundMistakes
                Rectangle {
                  required property var modelData
                  width: reviewColumn.width; height: 64; radius: 10
                  color: Qt.tint(root.bg, Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.03)); border.color: root.line
                  Text {
                    anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.34; elide: Text.ElideRight
                    text: modelData.title; color: root.fg; font.pixelSize: 15; font.weight: Font.DemiBold; textFormat: Text.PlainText
                  }
                  Row {
                    x: parent.width * 0.38; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "✗"; color: root.danger; font.pixelSize: 14; textFormat: Text.PlainText }
                    KeyCaps { anchors.verticalCenter: parent.verticalCenter; chord: modelData.pressed; tint: root.danger; text: root.fg; size: 11 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.pressedTitle + (modelData.count > 1 ? "  ×" + modelData.count : ""); color: root.muted; font.pixelSize: 12; textFormat: Text.PlainText; elide: Text.ElideRight; width: 180 }
                  }
                  Row {
                    anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "✓"; color: root.accent; font.pixelSize: 14; textFormat: Text.PlainText }
                    KeyCaps { anchors.verticalCenter: parent.verticalCenter; chord: modelData.chord; tint: root.accent; text: root.fg; size: 13 }
                  }
                }
              }
            }
          }
        }

        Text { visible: root.error !== ""; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: root.error; color: root.danger; wrapMode: Text.Wrap; textFormat: Text.PlainText; font.pixelSize: 13 }

        // Feedback and actions in a single row.
        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          // Nested layouts fill height by default; keep this row fixed so the
          // desktop gets the spare space even when the row is empty.
          Layout.fillHeight: false
          Layout.preferredHeight: 40
          spacing: 14
          Text {
            visible: root.solved
            text: root.t("correct"); color: root.accent
            font.pixelSize: 16; font.weight: Font.DemiBold; textFormat: Text.PlainText
          }
          Row {
            visible: root.practicing && !root.solved && root.wrongChord !== ""
            spacing: 10
            Text { anchors.verticalCenter: parent.verticalCenter; text: "✗"; color: root.danger; font.pixelSize: 16; font.weight: Font.Bold; textFormat: Text.PlainText }
            KeyCaps { anchors.verticalCenter: parent.verticalCenter; chord: root.wrongChord; tint: root.danger; text: root.fg; size: 12 }
            Text { anchors.verticalCenter: parent.verticalCenter; text: root.wrongTitle + "  ·  " + root.t("tryAgain"); color: root.fg; font.pixelSize: 14; textFormat: Text.PlainText }
          }
          DojoButton { visible: root.practicing && !root.keysVisible && !root.solved; label: root.t("hint"); onClicked: root.hint() }
          DojoButton {
            visible: !root.practicing; selected: true
            label: root.phase === "loading" ? root.t("loading") : root.phase === "arming" ? root.t("arming") : root.phase === "results" ? root.t("again") : root.t("start")
            enabled: (root.phase === "ready" || root.phase === "results") && !capture.running
            onClicked: root.start()
          }
          DojoButton {
            visible: !root.practicing && root.phase !== "arming" && root.mistakeCount > 0 && root.category !== "Mistakes"
            label: root.t("practiceMistakes") + " · " + root.mistakeCount
            onClicked: { root.category = "Mistakes"; root.start() }
          }
        }
      }

      // Deck picker
      MouseArea {
        anchors.fill: parent
        visible: root.deckMenuOpen
        onClicked: { root.deckMenuOpen = false; catcher.forceActiveFocus() }
      }
      Rectangle {
        visible: root.deckMenuOpen
        // Placed under the deck button each time it opens.
        onVisibleChanged: if (visible) { var p = deckButton.mapToItem(catcher, 0, deckButton.height + 6); x = p.x; y = p.y }
        width: 330; height: deckList.implicitHeight + 16
        radius: 10; color: root.bg; border.color: root.line
        Column {
          id: deckList
          x: 8; y: 8; width: parent.width - 16; spacing: 2
          Repeater {
            model: root.categories
            Rectangle {
              required property string modelData
              required property int index
              readonly property var items: root.pool(modelData)
              readonly property int mastered: { var p = root.progress; return items.filter(function(item) { return Engine.mastered(p, item.id) }).length }
              visible: items.length > 0
              width: deckList.width; height: visible ? 34 : 0; radius: 6
              color: root.category === modelData ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16) : rowMouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06) : "transparent"
              Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: index < 10 ? String((index + 1) % 10) : ""; color: root.muted; font.pixelSize: 11; font.family: "monospace"; textFormat: Text.PlainText }
              Text { x: 32; anchors.verticalCenter: parent.verticalCenter; text: modelData === "Mistakes" ? root.t("mistakes") : modelData; color: root.category === modelData ? root.accent : root.fg; font.pixelSize: 13; textFormat: Text.PlainText }
              // Mastery bar for the deck
              Rectangle {
                x: parent.width - 120; anchors.verticalCenter: parent.verticalCenter
                width: 60; height: 4; radius: 2; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
                Rectangle { width: parent.width * (parent.parent.items.length ? parent.parent.mastered / parent.parent.items.length : 0); height: parent.height; radius: 2; color: root.accent }
              }
              Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: parent.mastered + "/" + parent.items.length; color: root.muted; font.pixelSize: 11; font.family: "monospace"; textFormat: Text.PlainText }
              MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { root.category = parent.modelData; root.deckMenuOpen = false; root.error = ""; catcher.forceActiveFocus() } }
            }
          }
        }
      }
    }
  }
}
