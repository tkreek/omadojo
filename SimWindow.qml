import QtQuick
import qs.Commons

// A simulated Hyprland window: no title bar, square corners, a 2px border that
// takes the accent colour when focused. Each app draws enough of its own
// interface to be recognisable, plus a small icon tag. Launching plays an icon
// splash before the content appears.
Rectangle {
  id: root
  property string kind: "terminal"
  readonly property string view: kind === "obsidian" ? "notes" : kind
  property bool active: false
  // Hyprland group: { kinds: [...], active: index } shows a tab strip on top.
  property var tabs: null
  property bool pinned: false
  property bool launchPlay: false
  property color accent
  property color foreground
  property color background
  readonly property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.5)
  readonly property color faint: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.08)
  readonly property color panel: Qt.tint(background, Qt.rgba(foreground.r, foreground.g, foreground.b, 0.05))
  readonly property string iconFont: "JetBrainsMono Nerd Font"
  // Theme-derived secondary hues for syntax colouring and album art.
  readonly property color hueA: Qt.hsla((accent.hslHue + 0.33) % 1, Math.max(0.35, accent.hslSaturation), 0.65, 1)
  readonly property color hueB: Qt.hsla((accent.hslHue + 0.62) % 1, Math.max(0.35, accent.hslSaturation), 0.68, 1)

  readonly property var apps: ({
    terminal: { icon: "", name: "Terminal" },
    browser: { icon: "\u{f059f}", name: "Browser" },
    files: { icon: "\u{f024b}", name: "Files" },
    editor: { icon: "", name: "Neovim" },
    notes: { icon: "\u{f082e}", name: "Obsidian" },
    calculator: { icon: "\u{f00ec}", name: "Calculator" },
    music: { icon: "\u{f075a}", name: "Music" }
  })
  readonly property var app: apps[view] || apps.terminal

  color: view === "terminal" ? background : panel
  border.width: 2
  border.color: active ? accent : Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)
  clip: true
  Behavior on border.color { ColorAnimation { duration: Style.duration(160) } }

  onLaunchPlayChanged: if (launchPlay && !Style.reduceMotion) splashAnimation.restart()

  // Group tab strip (Hyprland groupbar)
  Row {
    id: groupBar
    visible: !!root.tabs
    x: 2; y: 2; width: parent.width - 4; height: visible ? 20 : 0
    spacing: 2
    Repeater {
      model: root.tabs ? root.tabs.kinds : []
      Rectangle {
        required property string modelData
        required property int index
        readonly property bool current: root.tabs && index === root.tabs.active
        readonly property int n: root.tabs ? root.tabs.kinds.length : 1
        width: (groupBar.width - (n - 1) * 2) / n; height: 20
        color: current ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.85) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
        Row { anchors.centerIn: parent; spacing: 6
          Text { anchors.verticalCenter: parent.verticalCenter; text: (root.apps[modelData === "obsidian" ? "notes" : modelData] || root.apps.terminal).icon; color: parent.parent.current ? root.background : root.foreground; font.family: root.iconFont; font.pixelSize: 10; textFormat: Text.PlainText }
          Text { anchors.verticalCenter: parent.verticalCenter; text: (index + 1) + "  " + (root.apps[modelData === "obsidian" ? "notes" : modelData] || root.apps.terminal).name; color: parent.parent.current ? root.background : root.foreground; font.pixelSize: 9; textFormat: Text.PlainText }
        }
      }
    }
  }

  Item {
    id: content
    anchors.fill: parent; anchors.margins: 2
    anchors.topMargin: root.tabs ? 24 : 2
    clip: true

    // ---- Terminal --------------------------------------------------------------
    Column {
      visible: root.view === "terminal"
      x: 12; y: 12; width: parent.width - 24; spacing: 6
      Repeater {
        model: [
          [["~/Projects", "a"], [" on ", "m"], [" main", "b"], [" ❯", "a"]],
          [["ls", "f"]],
          [["omadojo/  notes/  dotfiles/  README.md", "m"]],
          [["~/Projects", "a"], [" on ", "m"], [" main", "b"], [" ❯", "a"]],
          [["git status --short", "f"]],
          [[" M Dojo.qml", "b"]],
          [["~/Projects", "a"], [" on ", "m"], [" main", "b"], [" ❯ ", "a"], ["█", "a"]]
        ]
        Row {
          required property var modelData
          Repeater {
            model: modelData
            Text {
              required property var modelData
              text: modelData[0]
              color: modelData[1] === "a" ? root.accent : modelData[1] === "b" ? root.hueA : modelData[1] === "m" ? root.muted : root.foreground
              font.family: root.iconFont; font.pixelSize: 11; textFormat: Text.PlainText
            }
          }
        }
      }
    }

    // ---- Browser ---------------------------------------------------------------
    Item {
      visible: root.view === "browser"
      anchors.fill: parent
      Rectangle {
        id: tabs
        width: parent.width; height: 30; color: Qt.tint(root.background, root.faint)
        Row {
          x: 8; anchors.bottom: parent.bottom; spacing: 4
          Rectangle {
            width: 150; height: 24; color: root.panel
            Row { x: 9; anchors.verticalCenter: parent.verticalCenter; spacing: 7
              Text { text: "\u{f059f}"; color: root.accent; font.family: root.iconFont; font.pixelSize: 11; textFormat: Text.PlainText }
              Text { text: "Omarchy"; color: root.foreground; font.pixelSize: 10; textFormat: Text.PlainText }
            }
            Text { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "×"; color: root.muted; font.pixelSize: 11; textFormat: Text.PlainText }
          }
          Rectangle {
            width: 130; height: 24; color: "transparent"
            Row { x: 9; anchors.verticalCenter: parent.verticalCenter; spacing: 7
              Text { text: ""; color: root.muted; font.family: root.iconFont; font.pixelSize: 11; textFormat: Text.PlainText }
              Text { text: "GitHub"; color: root.muted; font.pixelSize: 10; textFormat: Text.PlainText }
            }
          }
          Text { anchors.verticalCenter: parent.verticalCenter; text: "+"; color: root.muted; font.pixelSize: 13; textFormat: Text.PlainText }
        }
      }
      Rectangle {
        id: urlBar
        anchors.top: tabs.bottom; width: parent.width; height: 32; color: root.panel
        Row { x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 12
          Text { text: "←   →   ↻"; color: root.muted; font.pixelSize: 11; textFormat: Text.PlainText }
        }
        Rectangle {
          x: 80; anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 100; height: 20; radius: 10; color: root.faint
          Row { x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            Text { text: "\u{f033e}"; color: root.muted; font.family: root.iconFont; font.pixelSize: 10; textFormat: Text.PlainText }
            Text { text: "omarchy.org"; color: root.foreground; font.pixelSize: 10; textFormat: Text.PlainText }
          }
        }
      }
      Column {
        anchors.top: urlBar.bottom; anchors.topMargin: 26
        x: 28; width: parent.width - 56; spacing: 10
        Text { text: "Omarchy"; color: root.accent; font.pixelSize: 26; font.bold: true; textFormat: Text.PlainText }
        Text { width: parent.width; text: "Your keyboard. Your kind of desktop."; color: root.foreground; font.pixelSize: 12; elide: Text.ElideRight; textFormat: Text.PlainText }
        Item { width: 1; height: 6 }
        Repeater { model: 4; Rectangle { required property int index; width: parent.width * (0.92 - index * 0.13); height: 5; radius: 2; color: root.foreground; opacity: 0.12 } }
        Item { width: 1; height: 8 }
        Row { spacing: 12
          Repeater { model: 3; Rectangle { width: 110; height: 70; radius: 4; color: root.faint; border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.1) } }
        }
      }
    }

    // ---- Files -----------------------------------------------------------------
    Item {
      visible: root.view === "files"
      anchors.fill: parent
      Rectangle {
        id: sidebar
        width: Math.min(150, parent.width * 0.3); height: parent.height; color: Qt.tint(root.background, root.faint)
        Column { x: 10; y: 14; width: parent.width - 20; spacing: 4
          Repeater {
            model: [["\u{f02dc}", "Home"], ["\u{f0219}", "Documents"], ["\u{f01da}", "Downloads"], ["\u{f02e9}", "Pictures"], ["\u{f0a1e}", "Trash"]]
            Rectangle {
              required property var modelData
              required property int index
              width: parent.width; height: 22; radius: 4
              color: index === 0 ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18) : "transparent"
              Row { x: 7; anchors.verticalCenter: parent.verticalCenter; spacing: 7
                Text { text: modelData[0]; color: index === 0 ? root.accent : root.muted; font.family: root.iconFont; font.pixelSize: 11; textFormat: Text.PlainText }
                Text { text: modelData[1]; color: root.foreground; font.pixelSize: 10; textFormat: Text.PlainText }
              }
            }
          }
        }
      }
      Text { x: sidebar.width + 16; y: 14; text: "Home  ›  Projects"; color: root.muted; font.pixelSize: 10; textFormat: Text.PlainText }
      Flow {
        x: sidebar.width + 16; y: 42; width: parent.width - sidebar.width - 32; spacing: 14
        Repeater {
          model: [["\u{f024b}", "omadojo"], ["\u{f024b}", "notes"], ["\u{f024b}", "dotfiles"], ["\u{f024b}", "screenshots"], ["\u{f0219}", "README.md"], ["\u{f0219}", "ideas.txt"]]
          Column {
            required property var modelData
            width: 72; spacing: 4
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: modelData[1].indexOf(".") > 0 ? root.muted : root.accent; font.family: root.iconFont; font.pixelSize: 36; textFormat: Text.PlainText }
            Text { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData[1]; color: root.foreground; font.pixelSize: 10; textFormat: Text.PlainText }
          }
        }
      }
    }

    // ---- Neovim ----------------------------------------------------------------
    Item {
      visible: root.view === "editor"
      anchors.fill: parent
      Rectangle { anchors.fill: parent; color: root.background }
      Column {
        x: 8; y: 10; width: parent.width - 16; spacing: 4
        Repeater {
          model: [
            [["import", "k"], [" QtQuick", "f"]],
            [],
            [["Item", "t"], [" {", "f"]],
            [["  id", "a"], [": root", "f"]],
            [["  property", "k"], [" string", "t"], [" mode", "f"], [": ", "f"], ["\"learn\"", "s"]],
            [["  // Keep the keyboard close", "c"]],
            [["  function", "k"], [" start", "a"], ["() {", "f"]],
            [["    round", "f"], [" = ", "f"], ["deck", "a"], ["(items)", "f"]],
            [["  }", "f"]],
            [["}", "f"]]
          ]
          Row {
            required property var modelData
            required property int index
            spacing: 10
            Text { width: 18; horizontalAlignment: Text.AlignRight; text: String(index + 1); color: index === 6 ? root.accent : root.muted; font.family: root.iconFont; font.pixelSize: 10; textFormat: Text.PlainText }
            Row {
              Repeater {
                model: modelData
                Text {
                  required property var modelData
                  text: modelData[0]
                  color: modelData[1] === "k" ? root.accent : modelData[1] === "t" ? root.hueB : modelData[1] === "s" ? root.hueA : modelData[1] === "a" ? Qt.lighter(root.accent, 1.25) : modelData[1] === "c" ? root.muted : root.foreground
                  font.family: root.iconFont; font.pixelSize: 10; font.italic: modelData[1] === "c"; textFormat: Text.PlainText
                }
              }
            }
          }
        }
      }
      // lualine-style status line
      Row {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 4; x: 0; height: 18
        Rectangle { width: normal.implicitWidth + 18; height: 18; color: root.accent
          Text { id: normal; anchors.centerIn: parent; text: "NORMAL"; color: root.background; font.family: root.iconFont; font.pixelSize: 9; font.bold: true; textFormat: Text.PlainText }
        }
        Rectangle { width: branch.implicitWidth + 18; height: 18; color: Qt.tint(root.background, root.faint)
          Text { id: branch; anchors.centerIn: parent; text: " main   Dojo.qml"; color: root.foreground; font.family: root.iconFont; font.pixelSize: 9; textFormat: Text.PlainText }
        }
      }
    }

    // ---- Obsidian --------------------------------------------------------------
    Item {
      visible: root.view === "notes"
      anchors.fill: parent
      Rectangle {
        id: vault
        width: Math.min(150, parent.width * 0.3); height: parent.height; color: Qt.tint(root.background, root.faint)
        Column { x: 10; y: 14; width: parent.width - 20; spacing: 6
          Text { text: "\u{f082e}  Vault"; color: root.foreground; font.family: root.iconFont; font.pixelSize: 10; font.bold: true; textFormat: Text.PlainText }
          Repeater {
            model: ["Daily", "Shortcuts", "Ideas", "Reading"]
            Text { required property string modelData; required property int index; text: "  " + modelData; color: index === 1 ? root.accent : root.muted; font.pixelSize: 10; textFormat: Text.PlainText }
          }
        }
      }
      Column {
        x: vault.width + 24; y: 22; width: parent.width - vault.width - 48; spacing: 10
        Text { text: "Shortcuts"; color: root.foreground; font.pixelSize: 20; font.bold: true; textFormat: Text.PlainText }
        Text { width: parent.width; wrapMode: Text.Wrap; text: "The fastest window is the one you never reach for."; color: root.foreground; font.pixelSize: 11; textFormat: Text.PlainText }
        Repeater {
          model: ["Learn one chord a day", "Practise the misses", "Link to [[Workspaces]]"]
          Text { required property string modelData; text: "•  " + modelData; color: modelData.indexOf("[[") >= 0 ? root.hueB : root.foreground; font.pixelSize: 11; textFormat: Text.PlainText }
        }
      }
    }

    // ---- Calculator ------------------------------------------------------------
    Column {
      visible: root.view === "calculator"
      anchors.centerIn: parent
      width: Math.min(parent.width - 40, 260); spacing: 10
      Text { width: parent.width; horizontalAlignment: Text.AlignRight; text: "128 × 4"; color: root.muted; font.pixelSize: 13; textFormat: Text.PlainText }
      Text { width: parent.width; horizontalAlignment: Text.AlignRight; text: "512"; color: root.foreground; font.pixelSize: 38; textFormat: Text.PlainText }
      Grid {
        columns: 4; spacing: 6
        Repeater {
          model: ["7", "8", "9", "÷", "4", "5", "6", "×", "1", "2", "3", "−", "0", ".", "=", "+"]
          Rectangle {
            required property string modelData
            readonly property bool op: "÷×−+=".indexOf(modelData) >= 0
            width: (parent.parent.width - 18) / 4; height: 30; radius: 6
            color: modelData === "=" ? root.accent : op ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18) : root.faint
            Text { anchors.centerIn: parent; text: parent.modelData; color: parent.modelData === "=" ? root.background : root.foreground; font.pixelSize: 13; textFormat: Text.PlainText }
          }
        }
      }
    }

    // ---- Music -----------------------------------------------------------------
    Item {
      visible: root.view === "music"
      anchors.fill: parent
      Rectangle {
        id: playlists
        width: Math.min(150, parent.width * 0.28); height: parent.height - player.height; color: Qt.tint(root.background, root.faint)
        Column { x: 10; y: 14; width: parent.width - 20; spacing: 7
          Repeater {
            model: [["\u{f02dc}", "Home"], ["\u{f0349}", "Search"], ["\u{f0cb8}", "Library"], ["", ""], ["\u{f0cb9}", "Focus"], ["\u{f0cb9}", "Deep work"], ["\u{f0cb9}", "Late night"]]
            Row { required property var modelData; spacing: 7
              Text { text: modelData[0]; color: root.muted; font.family: root.iconFont; font.pixelSize: 11; textFormat: Text.PlainText }
              Text { text: modelData[1]; color: root.foreground; font.pixelSize: 10; textFormat: Text.PlainText }
            }
          }
        }
      }
      Row {
        x: playlists.width + 20; y: 20; spacing: 16
        Rectangle {
          width: 96; height: 96; radius: 4
          gradient: Gradient { GradientStop { position: 0; color: root.accent } GradientStop { position: 1; color: root.hueB } }
          Text { anchors.centerIn: parent; text: "\u{f075a}"; color: root.background; font.family: root.iconFont; font.pixelSize: 40; textFormat: Text.PlainText }
        }
        Column { anchors.bottom: parent.bottom; spacing: 4
          Text { text: "PLAYLIST"; color: root.muted; font.pixelSize: 8; font.letterSpacing: 1.5; textFormat: Text.PlainText }
          Text { text: "Focus"; color: root.foreground; font.pixelSize: 24; font.bold: true; textFormat: Text.PlainText }
          Text { text: "24 songs"; color: root.muted; font.pixelSize: 10; textFormat: Text.PlainText }
        }
      }
      Column {
        x: playlists.width + 20; y: 136; width: parent.width - playlists.width - 40; spacing: 8
        Repeater {
          model: [["Night Drive", "3:42"], ["Low Light", "4:05"], ["Signal", "2:58"], ["Long Way Home", "5:11"]]
          Item { required property var modelData; required property int index; width: parent.width; height: 14
            Text { text: (index + 1) + "   " + modelData[0]; color: index === 0 ? root.accent : root.foreground; font.pixelSize: 10; textFormat: Text.PlainText }
            Text { anchors.right: parent.right; text: modelData[1]; color: root.muted; font.pixelSize: 10; textFormat: Text.PlainText }
          }
        }
      }
      Rectangle {
        id: player
        anchors.bottom: parent.bottom; width: parent.width; height: 44; color: Qt.tint(root.background, root.faint)
        Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -7; text: "\u{f04ae}    \u{f040a}    \u{f04ad}"; color: root.foreground; font.family: root.iconFont; font.pixelSize: 13; textFormat: Text.PlainText }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 32; width: parent.width * 0.45; height: 3; radius: 2; color: root.faint
          Rectangle { width: parent.width * 0.38; height: parent.height; radius: 2; color: root.accent }
        }
      }
    }
  }

  // Small app tag, so the app is identifiable even in the preview thumbnail.
  Rectangle {
    anchors.right: parent.right; anchors.top: parent.top
    anchors.rightMargin: 8; anchors.topMargin: (root.tabs ? 22 : 0) + (root.view === "browser" ? 40 : 8)
    width: tagRow.implicitWidth + 14; height: 20; radius: 10
    color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.85)
    border.color: root.active ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)
    Row {
      id: tagRow; anchors.centerIn: parent; spacing: 5
      Text { anchors.verticalCenter: parent.verticalCenter; text: root.app.icon; color: root.active ? root.accent : root.muted; font.family: root.iconFont; font.pixelSize: 11; textFormat: Text.PlainText }
      Text { anchors.verticalCenter: parent.verticalCenter; text: root.app.name; color: root.foreground; opacity: 0.8; font.pixelSize: 9; textFormat: Text.PlainText }
      Text { visible: root.pinned; anchors.verticalCenter: parent.verticalCenter; text: "\u{f0403}"; color: root.accent; font.family: root.iconFont; font.pixelSize: 11; textFormat: Text.PlainText }
    }
  }

  // Launch splash: the app icon fills the new window, then the app appears.
  Rectangle {
    id: splash
    anchors.fill: parent; anchors.margins: 2
    color: root.panel
    opacity: 0
    visible: opacity > 0
    Column {
      anchors.centerIn: parent; spacing: 12
      Text { id: splashIcon; anchors.horizontalCenter: parent.horizontalCenter; text: root.app.icon; color: root.accent; font.family: root.iconFont; font.pixelSize: Math.min(110, root.height * 0.3); textFormat: Text.PlainText }
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.app.name; color: root.foreground; font.pixelSize: 16; font.weight: Font.DemiBold; textFormat: Text.PlainText }
    }
  }
  SequentialAnimation {
    id: splashAnimation
    PropertyAction { target: splash; property: "opacity"; value: 1 }
    PropertyAction { target: splashIcon; property: "scale"; value: 0.6 }
    NumberAnimation { target: splashIcon; property: "scale"; to: 1; duration: 280; easing.type: Easing.OutBack }
    PauseAnimation { duration: 380 }
    NumberAnimation { target: splash; property: "opacity"; to: 0; duration: 260; easing.type: Easing.OutCubic }
  }
}
