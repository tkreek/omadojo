import QtQuick
import Quickshell
import Quickshell.Io

// Keeps Omadojo in the Omarchy app launcher. The launcher lists desktop
// entries, overlays only load when first opened, and Omarchy has no install
// hook, so this small service (mounted at shell startup) writes the entry and
// removes it again when the plugin is disabled or removed.
//
// Only a file carrying the X-Omadojo-Managed marker is ever rewritten or
// deleted; anything else at that path belongs to the user and is left alone.
QtObject {
  id: root
  property var shell: null
  property var manifest: null

  readonly property string dest: Quickshell.env("HOME") + "/.local/share/applications/omadojo.desktop"
  readonly property string marker: "X-Omadojo-Managed=true"
  readonly property string pluginDir: decodeURIComponent(Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, ""))
  // A path with control characters could inject extra keys into the entry.
  readonly property bool safePath: pluginDir.indexOf("/") === 0 && !/[\x00-\x1f\x7f]/.test(pluginDir)
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
  property bool installed: false

  property FileView file: FileView {
    path: root.safePath && Quickshell.env("HOME") ? root.dest : ""
    printErrors: false
    // Write to a temporary file and rename it into place, so a symlink at the
    // destination is replaced rather than written through.
    atomicWrites: true
    onLoaded: {
      var current = text()
      if (current.indexOf(root.marker) < 0) return
      root.installed = true
      if (current !== root.entry) setText(root.entry)
    }
    onLoadFailed: { root.installed = true; setText(root.entry) }
  }

  // Reached when the plugin is disabled or removed (removal disables first).
  // Paths are passed as arguments, never interpolated into the script.
  Component.onDestruction: {
    if (!installed) return
    Quickshell.execDetached(["sh", "-c", 'grep -qx "$2" "$1" 2>/dev/null && rm -f "$1"', "sh", dest, marker])
  }
}
