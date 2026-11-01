import QtQuick
import qs.Commons
import "Scenes.js" as Scenes

// Renders Scenes.state(scene, arg, after): an Omarchy desktop with the shell
// bar, Hyprland tiling (default gaps and borders), and any menu, panel, toast
// or lock screen the lesson calls for. Changes animate when animateChanges.
Rectangle {
  id: root
  property string scene: "welcome"
  property var arg: ""
  property bool after: false
  property bool animateChanges: true
  property color accent
  property color foreground
  property color background
  readonly property var st: Scenes.state(scene, arg, after)
  readonly property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.5)
  readonly property string iconFont: "JetBrainsMono Nerd Font"
  readonly property int barHeight: 26
  readonly property int gapOut: st.gaps ? 10 : 0
  readonly property int gapIn: st.gaps ? 10 : 0
  readonly property real workTop: (st.bar ? barHeight : 0) + gapOut
  readonly property int duration: Style.duration(220)
  radius: 10
  clip: true
  color: background
  border.width: 1; border.color: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)

  function iconFor(label) {
    var table = [["Audio", "\u{f057e}"], ["Bluetooth", "\u{f00af}"], ["Network", "\u{f05a9}"], ["Display", "\u{f0379}"],
      ["Power", "\u{f06a5}"], ["Hardware", "\u{f0ee0}"], ["Calendar", "\u{f00ed}"], ["clock", "\u{f0954}"], ["Notification", "\u{f009a}"],
      ["Copied #", "\u{f0266}"], ["Copied", "\u{f018f}"], ["Pasted", "\u{f0192}"], ["Cut", "\u{f0190}"], ["Selected", "\u{f0486}"], ["Recording", "\u{f044a}"],
      ["Screenshot", "\u{f0100}"], ["Text", "\u{f0a1f}"], ["silenced", "\u{f009b}"], ["scratchpad", "\u{f0e1e}"], ["monitor", "\u{f0379}"],
      ["weather", "\u{f0599}"], ["battery", "\u{f0079}"], ["time", "\u{f0954}"], ["reminder", "\u{f009a}"], ["language", "\u{f030c}"]]
    var text = String(label || "")
    for (var i = 0; i < table.length; i++) if (text.toLowerCase().indexOf(table[i][0].toLowerCase()) >= 0) return table[i][1]
    return "\u{f02fd}"
  }
  // Pixel rectangle for a window description.
  function rectFor(w) {
    if (w.full) return Qt.rect(0, 0, width, height)
    if (w.toBar) return Qt.rect(barX(w.toBar), 4, 14, 10)
    var waX = gapOut - gapIn / 2, waW = width - 2 * gapOut + gapIn
    var waY = workTop - gapIn / 2, waH = height - workTop - gapOut + gapIn
    return Qt.rect(waX + w.r[0] * waW + gapIn / 2, waY + w.r[1] * waH + gapIn / 2,
      Math.max(8, w.r[2] * waW - gapIn), Math.max(8, w.r[3] * waH - gapIn))
  }
  // Omarchy's workspace widget: 1-5 always, plus any other workspace in use.
  readonly property var barIds: {
    var ids = [1, 2, 3, 4, 5]
    ;[st.ws, st.barPulse].forEach(function(n) { if (n > 5 && ids.indexOf(n) < 0) ids.push(n) })
    return ids
  }
  function barX(n) { return 34 + Math.max(0, barIds.indexOf(n)) * 20 }

  Item {
    id: stage
    anchors.fill: parent
    scale: root.st.zoom
    transformOrigin: Item.Center
    Behavior on scale { enabled: root.animateChanges; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }

    // Wallpaper
    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Qt.tint(root.background, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)) }
        GradientStop { position: 1; color: Qt.tint(root.background, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)) }
      }
    }

    // Shell bar
    Rectangle {
      id: bar
      width: parent.width; height: root.barHeight
      y: root.st.bar ? 0 : -height
      Behavior on y { enabled: root.animateChanges; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
      color: root.background
      // Left: Omarchy menu logo, then workspaces.
      Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: "\ue900"; color: root.foreground; font.family: "omarchy"; font.pixelSize: 12; textFormat: Text.PlainText }
      Repeater {
        model: root.barIds
        Item {
          required property int modelData
          readonly property bool selected: modelData === root.st.ws
          readonly property bool pulse: modelData === root.st.barPulse
          // Workspace 1 holds the lesson windows, 2 the files/music pair.
          readonly property bool occupied: modelData <= 2 || pulse
          x: root.barX(modelData); width: 18; height: parent.height
          Text {
            anchors.centerIn: parent
            text: parent.selected ? (root.st.mode === "scrolling" ? "\u{f0765}" : "\u{f14fb}") : String(parent.modelData % 10)
            color: parent.pulse ? root.accent : root.foreground
            opacity: parent.selected || parent.occupied ? 1 : 0.5
            font.family: root.iconFont; font.pixelSize: 11; textFormat: Text.PlainText
          }
          Rectangle {
            visible: parent.pulse
            anchors.centerIn: parent; width: 18; height: 18; radius: 9
            color: "transparent"; border.color: root.accent; border.width: 1.5
          }
        }
      }
      // Centre: clock (dddd HH:mm) and weather, as in the default layout.
      Row {
        anchors.centerIn: parent; spacing: 10
        Text { anchors.verticalCenter: parent.verticalCenter; text: "Sunday 10:24"; color: root.foreground; font.pixelSize: 11; font.weight: Font.DemiBold; textFormat: Text.PlainText }
        Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f0599} 18\u00b0"; color: root.foreground; opacity: 0.75; font.family: root.iconFont; font.pixelSize: 10; textFormat: Text.PlainText }
      }
      // Right: bluetooth, network, audio, power.
      Row {
        anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 12
        Repeater {
          model: ["\u{f00af}", "\u{f05a9}", "\u{f057e}", "\u{f0079}"]
          Text { required property string modelData; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: root.foreground; opacity: 0.8; font.family: root.iconFont; font.pixelSize: 11; textFormat: Text.PlainText }
        }
      }
    }

    // Dim behind menus and the scratchpad
    Rectangle {
      anchors.fill: parent; z: 5
      color: Qt.rgba(0, 0, 0, 0.45)
      opacity: root.st.dim ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { enabled: root.animateChanges; NumberAnimation { duration: 160 } }
    }

    // Where the window was, for resize and pseudo-tiling.
    Rectangle {
      readonly property rect g: root.st.ghost ? root.rectFor({ r: root.st.ghost }) : Qt.rect(0, 0, 0, 0)
      x: g.x; y: g.y; width: g.width; height: g.height; z: 3
      visible: !!root.st.ghost
      color: "transparent"
      border.width: 2; border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
      Rectangle { anchors.fill: parent; anchors.margins: 4; color: "transparent"; border.width: 1; border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15) }
    }

    // Windows
    Repeater {
      model: Scenes.IDS
      SimWindow {
        required property string modelData
        readonly property var w: root.st.windows[modelData]
        readonly property rect g: root.rectFor(w)
        x: g.x; y: g.y; width: g.width; height: g.height
        z: w.z
        opacity: (w.visible ? 1 : 0) * w.alpha
        visible: opacity > 0.01
        scale: w.visible ? 1 : 0.94
        kind: w.kind
        active: w.active
        tabs: w.tabs
        pinned: w.pinned
        launchPlay: w.launch && root.animateChanges
        accent: root.accent; foreground: root.foreground; background: root.background
        Behavior on x { enabled: root.animateChanges; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: root.animateChanges; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
        Behavior on width { enabled: root.animateChanges; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
        Behavior on height { enabled: root.animateChanges; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: root.animateChanges; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { enabled: root.animateChanges; NumberAnimation { duration: root.duration; easing.type: Easing.OutBack } }
      }
    }

    // ---- Menu (Omarchy menu, launcher, pickers) --------------------------------
    Rectangle {
      id: menu
      readonly property bool shown: !!root.st.overlay && root.st.overlay.type === "menu"
      property var menuData: Scenes.MENUS.root
      readonly property string variant: shown ? root.st.overlay.variant : ""
      onVariantChanged: if (variant) menuData = Scenes.MENUS[variant] || Scenes.MENUS.root
      Component.onCompleted: if (variant) menuData = Scenes.MENUS[variant] || Scenes.MENUS.root
      z: 10
      opacity: shown ? 1 : 0
      visible: opacity > 0
      scale: shown ? 1 : 0.96
      Behavior on opacity { enabled: root.animateChanges; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      Behavior on scale { enabled: root.animateChanges; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      anchors.centerIn: parent
      width: Math.min(parent.width * 0.5, 460)
      height: Math.min(parent.height - 70, menuColumn.implicitHeight + 24)
      color: root.background; border.width: 2; border.color: root.accent
      clip: true
      Column {
        id: menuColumn
        x: 12; y: 12; width: parent.width - 24; spacing: 3
        Rectangle {
          width: parent.width; height: 30; color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
          Row { x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 8
            Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f0349}"; color: root.muted; font.family: root.iconFont; font.pixelSize: 12; textFormat: Text.PlainText }
            Text { anchors.verticalCenter: parent.verticalCenter; text: menu.menuData.title; color: root.foreground; font.pixelSize: 11; textFormat: Text.PlainText }
          }
        }
        Item { width: 1; height: 4 }
        Repeater {
          model: menu.menuData.rows
          Rectangle {
            required property var modelData
            required property int index
            width: menuColumn.width; height: 24
            color: index === 0 ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08) : "transparent"
            Text {
              x: 10; anchors.verticalCenter: parent.verticalCenter
              text: modelData[0]; color: index === 0 ? root.accent : root.foreground
              font.family: root.iconFont; font.pixelSize: menu.menuData.keys ? 10 : 12; textFormat: Text.PlainText
            }
            Text {
              x: menu.menuData.keys ? parent.width - implicitWidth - 10 : 38
              anchors.verticalCenter: parent.verticalCenter
              text: modelData[1]; color: menu.menuData.keys ? root.muted : index === 0 ? root.accent : root.foreground
              font.pixelSize: menu.menuData.keys ? 10 : 11; textFormat: Text.PlainText
            }
          }
        }
      }
    }

    // ---- Bar panel (audio, network, calendar, ...) -------------------------------
    Rectangle {
      id: panel
      readonly property bool shown: !!root.st.overlay && root.st.overlay.type === "panel"
      property string label: ""
      readonly property string current: shown ? root.st.overlay.label : ""
      onCurrentChanged: if (current) label = current
      Component.onCompleted: if (current) label = current
      z: 10
      x: parent.width - width - 10
      y: root.barHeight + (shown ? 6 : -6)
      Behavior on y { enabled: root.animateChanges; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      opacity: shown ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { enabled: root.animateChanges; NumberAnimation { duration: 160 } }
      width: 250; height: 168
      color: root.background; border.width: 2; border.color: root.accent
      Row {
        x: 14; y: 14; spacing: 10
        Text { text: root.iconFor(panel.label); color: root.accent; font.family: root.iconFont; font.pixelSize: 18; textFormat: Text.PlainText }
        Text { anchors.verticalCenter: parent.verticalCenter; text: panel.label; color: root.foreground; font.pixelSize: 13; font.weight: Font.DemiBold; textFormat: Text.PlainText }
      }
      Column {
        x: 14; y: 52; width: parent.width - 28; spacing: 14
        Repeater {
          model: 3
          Item {
            required property int index
            width: parent.width; height: 14
            Rectangle { width: parent.width * (0.55 - index * 0.1); height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: root.foreground; opacity: 0.18 }
            Rectangle {
              x: parent.width - width; anchors.verticalCenter: parent.verticalCenter
              width: 26; height: 14; radius: 7
              color: index === 0 ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)
              Rectangle { width: 10; height: 10; radius: 5; y: 2; x: index === 0 ? 14 : 2; color: root.background }
            }
          }
        }
      }
    }

    // ---- Notifications -------------------------------------------------------
    Column {
      id: notes
      readonly property int count: root.st.overlay && root.st.overlay.type === "notify" ? root.st.overlay.count : 0
      property int shownCount: 0
      onCountChanged: if (count > 0) shownCount = count
      Component.onCompleted: if (count > 0) shownCount = count
      z: 10
      x: parent.width - width - 10 + (count > 0 ? 0 : 60)
      Behavior on x { enabled: root.animateChanges; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      y: root.barHeight + 8
      spacing: 8
      opacity: count > 0 ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { enabled: root.animateChanges; NumberAnimation { duration: 200 } }
      Repeater {
        model: notes.shownCount
        Rectangle {
          required property int index
          width: 240; height: 56
          color: root.background; border.width: 2; border.color: index === 0 ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.25)
          Row { x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{f009a}"; color: root.accent; font.family: root.iconFont; font.pixelSize: 16; textFormat: Text.PlainText }
            Column { spacing: 3
              Text { text: ["Reminder", "Update ready", "Battery low"][index % 3]; color: root.foreground; font.pixelSize: 11; font.weight: Font.DemiBold; textFormat: Text.PlainText }
              Text { text: ["Stand up and stretch", "Omarchy 4.5 is available", "20% remaining"][index % 3]; color: root.muted; font.pixelSize: 10; textFormat: Text.PlainText }
            }
          }
        }
      }
    }

    // ---- Toast / OSD ----------------------------------------------------------
    Rectangle {
      id: toast
      readonly property bool shown: !!root.st.overlay && root.st.overlay.type === "toast"
      property string label: ""
      property string icon: ""
      readonly property string current: shown ? root.st.overlay.label : ""
      function sync() { if (current) { label = current; icon = root.st.overlay.icon || root.iconFor(current) } }
      onCurrentChanged: sync()
      Component.onCompleted: sync()
      z: 10
      x: (parent.width - width) / 2
      y: parent.height - height - (shown ? 30 : 10)
      Behavior on y { enabled: root.animateChanges; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      opacity: shown ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { enabled: root.animateChanges; NumberAnimation { duration: 160 } }
      width: toastRow.implicitWidth + 36; height: 44; radius: 22
      color: root.background; border.width: 2; border.color: root.accent
      Row {
        id: toastRow; anchors.centerIn: parent; spacing: 10
        Text { anchors.verticalCenter: parent.verticalCenter; text: toast.icon; color: root.accent; font.family: root.iconFont; font.pixelSize: 16; textFormat: Text.PlainText }
        Text { anchors.verticalCenter: parent.verticalCenter; text: toast.label; color: root.foreground; font.pixelSize: 13; textFormat: Text.PlainText }
      }
    }

    // Screenshot flash
    Rectangle {
      id: shot
      anchors.fill: parent; z: 12; color: "white"
      opacity: 0
      readonly property bool on: root.st.flash
      onOnChanged: if (on && root.animateChanges) shotFlash.restart()
      NumberAnimation { id: shotFlash; target: shot; property: "opacity"; from: 0.7; to: 0; duration: 450; easing.type: Easing.OutCubic }
    }
  }

  // ---- Lock screen (outside the zoom stage) ---------------------------------
  Rectangle {
    anchors.fill: parent; z: 20
    color: root.background
    opacity: root.st.overlay && root.st.overlay.type === "lock" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { enabled: root.animateChanges; NumberAnimation { duration: 260 } }
    Column {
      anchors.centerIn: parent; spacing: 16
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{f033e}"; color: root.accent; font.family: root.iconFont; font.pixelSize: 34; textFormat: Text.PlainText }
      Text { anchors.horizontalCenter: parent.horizontalCenter; text: "10:24"; color: root.foreground; font.pixelSize: 54; font.weight: Font.Light; textFormat: Text.PlainText }
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 220; height: 34; color: "transparent"; border.width: 2; border.color: root.accent
        Text { anchors.centerIn: parent; text: "• • • •"; color: root.foreground; font.pixelSize: 12; textFormat: Text.PlainText }
      }
    }
  }
}
