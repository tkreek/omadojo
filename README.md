# Omadojo ◈

**Build Omarchy muscle memory.** A typing-test-style shortcut trainer for the Omarchy desktop and its plugins.

![Omadojo practice screen](preview.png)

See a visual task, press the right shortcut, and watch the simulated desktop respond. Train your speed and accuracy without closing, moving, or launching your real applications.

## Install

Requires Omarchy's Quickshell plugin system, **Hyprland with Lua configuration** (tested with Omarchy 4.5.0rc2), and Python 3. No extra Python or Node packages are needed to run the plugin.

```sh
omarchy plugin add https://github.com/tkreek/omadojo.git --enable
```

Open **Omadojo** from the Omarchy menu, or run:

```sh
omarchy-shell shell toggle io.github.tkreek.omadojo
```

If you want a dedicated shortcut, add an unused combination to `~/.config/hypr/bindings.lua`:

```lua
-- Check that this combination is free in your configuration first.
o.bind("SUPER + CTRL + ALT + D", "Omadojo", { panel = "io.github.tkreek.omadojo" })
```

Then run `hyprctl reload` and `hyprctl configerrors`. Installing Omadojo itself does not edit your Hyprland config or add a global shortcut.

## Practice

1. Choose **All shortcuts**, **Essentials**, **Launch**, **Windows**, **Navigation**, **Workspaces**, or **Plugins**.
2. Pick a 15- or 30-prompt round and press **Enter**.
3. Perform the action shown using its Omarchy keyboard shortcut. The action happens in the simulated desktop.
4. See completion time, accuracy, average response time, shortcuts per minute, best streak, and points at the end.

**Escape** exits at any time. **Ctrl + Alt + Escape** is an independent compositor-level escape hatch while practice is active. The mouse Exit button also works.

Wrong chords count as misses and leave the current prompt in place. Revealing a shortcut costs one miss and breaks the streak. Modifier-only presses and held-key repeats do not count. Scores are per round and stay in memory; no input or score history is recorded to disk.

### Your actual shortcuts

Omadojo reads `hyprctl binds -j` when you open it. Lessons match action descriptions, so a customized chord is used when its description matches. Actions that are not bound are left out.

The **Plugins** deck discovers described, keyboard-bound shell/plugin actions from your live bindings. It can teach a plugin's launch/toggle shortcut; it does **not** automatically understand arbitrary controls inside each plugin. Bindings without suitable descriptions or unsupported key symbols are omitted. This release supports Super-based, single-key chords; described bindings in other submaps, mouse binds, release-only binds, and media keys are excluded.

## Keyboard takeover and recovery

During a round, Omadojo opens a fullscreen layer with exclusive keyboard focus and enters a temporary `omadojo-practice` Hyprland submap. Normal desktop shortcuts are suspended, and key events are graded inside the trainer. Lesson actions are never executed on the real desktop.

A Python watchdog owns capture and receives heartbeats from the UI. Normal exit, EOF, missed heartbeats (about five seconds), a ten-minute session limit, or termination signals restore the default submap and unbind the emergency shortcut. The watchdog runs in a separate process session so it can recover even if the shell kills its immediate child. If the compositor config reloads, practice ends.

Capture refuses to start from an existing non-default submap. Omadojo also refuses practice when any `submap_universal` binding exists, because those shortcuts would bypass the temporary submap. System-reserved keys and compositor input policies remain outside the plugin's control.

Manual recovery from another terminal or TTY:

```sh
hyprctl dispatch 'hl.dsp.submap("reset")'
# Or restore and remove the temporary emergency binding:
python3 ~/.config/omarchy/plugins/io.github.tkreek.omadojo/capture.py --restore
```

Only the active practice session captures keys. Closing the overlay returns keyboard focus to your desktop. The plugin has no network access of its own and does not log typed input.

## Update / remove

```sh
omarchy plugin update io.github.tkreek.omadojo
omarchy restart shell

# Remove (close practice first):
omarchy plugin remove io.github.tkreek.omadojo
```

## Development

Zero dependency test suite:

```sh
npm test
omarchy plugin validate "$PWD"
```

An optional GitHub Actions workflow is in `contrib/github-actions-test.yml`; move it
to `.github/workflows/test.yml` using credentials with the `workflow` permission
to enable CI.

The tests cover customized binding discovery, chord normalization, scoring, hints, deck generation, watchdog timeouts, and process-death recovery using a fake `hyprctl`. They do not capture your real keyboard.

For a local checkout, link it into your plugin directory, rescan, then enable it once discovery finishes:

```sh
ln -s "$PWD" ~/.config/omarchy/plugins/io.github.tkreek.omadojo
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.tkreek.omadojo
```

After QML changes, restart the shell if a rescan keeps an older component instance. Do not restart during active practice unless you are deliberately testing crash recovery.

### Structure

- `Dojo.qml`: overlay, input grading, round lifecycle, and live shortcut discovery.
- `DesktopScene.qml`: animated mock desktop; no real window actions.
- `Engine.js`: pure scoring, chord matching, and shuffled rounds.
- `Lessons.js`: curated action descriptions and visual tasks.
- `capture.py`: temporary submap owner and independent input recovery watchdog.
- `i18n/en.json`: UI strings, using Omarchy's translation fallback.

Uses `Commons.Color` to avoid Qt 6.12's `Color` naming collision. Theme colors and reduced-motion settings follow Omarchy. No changes are made to packaged Omarchy files.

MIT licensed. Contributions for more visual lessons, plugin-specific decks, and translations are welcome.
