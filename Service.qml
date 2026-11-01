import QtQuick
import Quickshell
import Quickshell.Io

// Keeps Omadojo in the Omarchy app launcher. The launcher lists desktop
// entries, overlays only load when first opened, and Omarchy has no install
// hook, so this small service (mounted at shell startup) writes the entry.
// A file without the X-Omadojo-Managed marker is the user's own and is never
// overwritten.
QtObject {
  id: root
  property var shell: null
  property var manifest: null

  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, "")
  readonly property string marker: "X-Omadojo-Managed=true"
  readonly property string entry: [
    "[Desktop Entry]",
    "Type=Application",
    "Name=Omadojo",
    "GenericName=Shortcut Trainer",
    "Comment=Practise your Omarchy keyboard shortcuts",
    "Exec=omarchy-shell shell toggle io.github.tkreek.omadojo",
    "TryExec=omarchy-shell",
    "Icon=" + pluginDir + "/icon.svg",
    "Terminal=false",
    "StartupNotify=false",
    "Categories=Education;",
    "Keywords=keyboard;shortcuts;keybindings;practice;hyprland;omarchy;",
    marker,
    ""
  ].join("\n")

  property FileView file: FileView {
    path: Quickshell.env("HOME") + "/.local/share/applications/omadojo.desktop"
    printErrors: false
    onLoaded: {
      var current = text()
      if (current.indexOf(root.marker) >= 0 && current !== root.entry) setText(root.entry)
    }
    onLoadFailed: setText(root.entry)
  }
}
