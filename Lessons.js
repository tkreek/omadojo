// Practice lessons. Each lesson is matched to a live Hyprland binding by its
// description, so customised chords are picked up automatically. Lessons in the
// same `family` are permutations of one idea (left/right/up/down, 1-10, ...).
// scene + arg pick the animation in Scenes.js.

function L(id, category, description, title, scene, arg, label, family) {
  return { id: id, category: category, description: description, title: title, scene: scene,
    arg: arg === undefined ? '' : arg, label: label || title, family: family || id }
}

var lessons = []
function add(item) { lessons.push(item) }

// ---- Applications ----------------------------------------------------------
;[
  ['terminal', 'Terminal', 'Open a terminal', 'terminal'],
  ['browser', 'Browser', 'Open the browser', 'browser'],
  ['private', 'Browser (private)', 'Open a private browser window', 'browser'],
  ['files', 'File manager', 'Open the file manager', 'files'],
  ['filescwd', 'File manager (cwd)', 'Open files in the current folder', 'files'],
  ['editor', 'Editor', 'Open your editor', 'editor'],
  ['obsidian', 'Obsidian', 'Open Obsidian', 'obsidian'],
  ['calculator', 'Calculator', 'Open the calculator', 'calculator'],
  ['music', 'Music', 'Open your music player', 'music'],
  ['activity', 'Activity', 'Open the activity monitor', 'terminal'],
  ['agent', 'Agent', 'Open the agent', 'terminal']
].forEach(function(a) { add(L(a[0], 'Applications', a[1], a[2], 'launch', a[3], a[1], 'launch')) })

// ---- Windows ---------------------------------------------------------------
add(L('close', 'Windows', 'Close window', 'Close the focused window', 'close'))
add(L('float', 'Windows', 'Toggle window floating/tiling', 'Float the focused window', 'float'))
add(L('pop', 'Windows', 'Pop window out (float & pin)', 'Pop the window out and pin it', 'pop'))
add(L('fullscreen', 'Windows', 'Full screen', 'Make the window full screen', 'fullscreen', '', 'Full screen', 'fullsize'))
add(L('tiledfull', 'Windows', 'Tiled full screen', 'Fill the workspace, keep the bar', 'tiledfull', '', 'Tiled full screen', 'fullsize'))
add(L('fullwidth', 'Windows', 'Full width', 'Make the window full width', 'fullwidth', '', 'Full width', 'fullsize'))
add(L('split', 'Windows', 'Toggle window split', 'Toggle the window split', 'split'))
add(L('pseudo', 'Windows', 'Pseudo window', 'Pseudo-tile the window', 'pseudo'))
add(L('transparency', 'Windows', 'Toggle transparency on a window', 'Make the window transparent', 'transparent'))
add(L('gaps', 'Windows', 'Toggle window gaps', 'Toggle the gaps between windows', 'gaps'))
add(L('layout', 'Windows', 'Cycle workspace layout', 'Cycle the workspace layout', 'layout', 1, 'Next layout', 'layout'))
add(L('layoutback', 'Windows', 'Cycle workspace layout back', 'Cycle the workspace layout back', 'layout', -1, 'Previous layout', 'layout'))
add(L('closeall', 'Windows', 'Close all windows', 'Close every window', 'closeall'))
add(L('minimize', 'Windows', 'Minimize window to the dock', 'Minimise the window', 'minimize'))

// ---- Navigation: focus and swap in every direction ---------------------------
;[['left', 'Focus on left window', 'Focus the window on the left'],
  ['right', 'Focus on right window', 'Focus the window on the right'],
  ['up', 'Focus on above window', 'Focus the window above'],
  ['down', 'Focus on below window', 'Focus the window below']
].forEach(function(d) { add(L('focus-' + d[0], 'Navigation', d[1], d[2], 'focus', d[0], 'Focus ' + d[0], 'focus')) })
;[['left', 'Swap window to the left', 'Swap the window to the left'],
  ['right', 'Swap window to the right', 'Swap the window to the right'],
  ['up', 'Swap window up', 'Swap the window up'],
  ['down', 'Swap window down', 'Swap the window down']
].forEach(function(d) { add(L('swap-' + d[0], 'Navigation', d[1], d[2], 'swap', d[0], 'Swap ' + d[0], 'swap')) })

add(L('cycle-next', 'Navigation', 'Focus on next window', 'Cycle to the next window', 'cycle', 'next', 'Next window', 'cycle'))
add(L('cycle-prev', 'Navigation', 'Focus on previous window', 'Cycle to the previous window', 'cycle', 'prev', 'Previous window', 'cycle'))

// ---- Resize: four directions x three step sizes -------------------------------
;[['expand-left', 'Expand window left', 'Widen the window to the left', 'left', 1],
  ['shrink-left', 'Shrink window left', 'Narrow the window from the left', 'left', -1],
  ['shrink-up', 'Shrink window up', 'Shorten the window from the bottom', 'bottom', -1],
  ['expand-down', 'Expand window down', 'Lengthen the window downward', 'bottom', 1]
].forEach(function(r) {
  ;[['', 'normal', ''], [' a little', 'little', ' · a little'], [' a lot', 'lot', ' · a lot']].forEach(function(size) {
    add(L(r[0] + (size[1] === 'normal' ? '' : '-' + size[1]), 'Resize', r[1] + size[0], r[2] + size[2], 'resize',
      { edge: r[3], grow: r[4], size: size[1] }, r[1] + size[0], 'resize'))
  })
})

// ---- Workspaces --------------------------------------------------------------
for (var n = 1; n <= 10; n++) {
  add(L('ws' + n, 'Workspaces', 'Switch to workspace ' + n, 'Go to workspace ' + n, 'workspace', n, 'Workspace ' + n, 'ws-switch'))
  add(L('move' + n, 'Workspaces', 'Move window to workspace ' + n, 'Take this window to workspace ' + n, 'move', n, 'Move to ' + n, 'ws-move'))
  add(L('silent' + n, 'Workspaces', 'Move window silently to workspace ' + n, 'Send this window to workspace ' + n + ' and stay', 'silent', n, 'Send to ' + n, 'ws-silent'))
}
add(L('wsnext', 'Workspaces', 'Next workspace', 'Go to the next workspace', 'wsnext', '', 'Next workspace', 'ws-step'))
add(L('wsprev', 'Workspaces', 'Previous workspace', 'Go to the previous workspace', 'wsprev', '', 'Previous workspace', 'ws-step'))
add(L('wsformer', 'Workspaces', 'Former workspace', 'Jump back to the workspace you were on', 'wsformer', '', 'Former workspace', 'ws-step'))
add(L('scratch', 'Workspaces', 'Toggle scratchpad', 'Show the scratchpad', 'scratch', '', 'Scratchpad', 'scratch'))
add(L('toscratch', 'Workspaces', 'Move window to scratchpad', 'Tuck this window into the scratchpad', 'toscratch', '', 'To scratchpad', 'scratch'))
add(L('quake', 'Workspaces', 'Toggle Quake console', 'Drop down the Quake console', 'quake', '', 'Quake console', 'quake'))
add(L('toquake', 'Workspaces', 'Move window to Quake console', 'Move this window into the Quake console', 'toquake', '', 'To Quake console', 'quake'))

// ---- Groups ------------------------------------------------------------------
add(L('group', 'Groups', 'Toggle window grouping', 'Group these windows into tabs', 'group', '', 'Group', 'group'))
add(L('ungroup', 'Groups', 'Move active window out of group', 'Pull this window out of its group', 'ungroup', '', 'Ungroup', 'group'))
add(L('groupnext', 'Groups', 'Next window in group', 'Go to the next tab in the group', 'grouptab', 'next', 'Next in group', 'group-step'))
add(L('groupprev', 'Groups', 'Previous window in group', 'Go to the previous tab in the group', 'grouptab', 'prev', 'Previous in group', 'group-step'))
add(L('groupfocus-left', 'Groups', 'Move grouped window focus left', 'Focus the tab to the left', 'grouptab', 'prev', 'Group focus left', 'group-step'))
add(L('groupfocus-right', 'Groups', 'Move grouped window focus right', 'Focus the tab to the right', 'grouptab', 'next', 'Group focus right', 'group-step'))
for (var g = 1; g <= 5; g++)
  add(L('grouptab' + g, 'Groups', 'Switch to group window ' + g, 'Jump to tab ' + g + ' in the group', 'grouptab', g, 'Group tab ' + g, 'group-tab'))
;[['left', 'Move window to group on left'], ['right', 'Move window to group on right'], ['up', 'Move window to group on top'], ['down', 'Move window to group on bottom']]
  .forEach(function(d) { add(L('groupjoin-' + d[0], 'Groups', d[1], 'Join the group ' + (d[0] === 'up' ? 'above' : d[0] === 'down' ? 'below' : 'on the ' + d[0]), 'groupjoin', d[0], 'Join ' + d[0], 'group-join')) })

// ---- Desktop: menus, panels and system -----------------------------------------
;[['menu', 'Omarchy menu', 'Open the Omarchy menu', 'root'],
  ['keys', 'Keybindings', 'Find your keyboard shortcuts', 'keys'],
  ['apps', 'Apps', 'Open the app launcher', 'apps'],
  ['system', 'System menu', 'Open the system menu', 'system'],
  ['theme', 'Theme menu', 'Change the theme', 'theme'],
  ['background', 'Background switcher', 'Switch the background', 'background'],
  ['clipboard', 'Clipboard manager', 'Open clipboard history', 'clipboard'],
  ['emojis', 'Emojis', 'Pick an emoji', 'emojis'],
  ['capture', 'Capture menu', 'Open the capture menu', 'capture'],
  ['share', 'Share', 'Share something', 'share']
].forEach(function(m) { add(L(m[0], 'Desktop', m[1], m[2], 'menu', m[3], m[1], 'menus')) })
;[['audio', 'Audio'], ['bluetooth', 'Bluetooth'], ['network', 'Network'], ['display', 'Display'], ['power', 'Power'],
  ['hardware', 'Hardware menu'], ['calendar', 'Calendar'], ['worldclock', 'World clock']
].forEach(function(p) { add(L(p[0], 'Desktop', p[1], 'Open ' + p[1].replace(' menu', ''), 'panel', p[1].replace(' menu', ''), p[1], 'panels')) })
add(L('lock', 'Desktop', 'Lock system', 'Lock the computer', 'lock'))
add(L('topbar', 'Desktop', 'Toggle top bar', 'Hide the top bar', 'topbar'))
add(L('zoom', 'Desktop', 'Zoom in', 'Zoom in', 'zoom', '', 'Zoom in', 'zoom'))
add(L('zoomreset', 'Desktop', 'Reset zoom', 'Reset the zoom', 'zoomreset', '', 'Reset zoom', 'zoom'))
add(L('notify', 'Desktop', 'Dismiss, invoke, or focus last notification', 'Dismiss the last notification', 'notify', 'one', 'Dismiss notification', 'notify'))
add(L('notifyall', 'Desktop', 'Dismiss all notifications', 'Dismiss all notifications', 'notify', 'all', 'Dismiss all', 'notify'))
add(L('notifyhistory', 'Desktop', 'Open notification history', 'Open notification history', 'notify', 'history', 'Notification history', 'notify'))
add(L('silence', 'Desktop', 'Toggle silencing notifications', 'Silence notifications', 'toast', 'Notifications silenced', 'Silence', 'notify'))

// ---- Clipboard and capture ----------------------------------------------------
;[['copy', 'Universal copy', 'Copy', 'Copied'], ['paste', 'Universal paste', 'Paste', 'Pasted'],
  ['cut', 'Universal cut', 'Cut', 'Cut to clipboard'], ['selectall', 'Select all', 'Select everything', 'Selected all']
].forEach(function(c) { add(L(c[0], 'Desktop', c[1], c[2], 'toast', c[3], c[1], 'clipboard-keys')) })
add(L('screenshot', 'Desktop', 'Screenshot', 'Take a screenshot', 'shot', 'Screenshot copied', 'Screenshot', 'capture'))
add(L('record', 'Desktop', 'Screenrecording', 'Record the screen', 'toast', 'Recording started', 'Screen recording', 'capture'))
add(L('colorpicker', 'Desktop', 'Color picker', 'Pick a colour from the screen', 'toast', 'Copied #7aa2f7', 'Color picker', 'capture'))
add(L('ocr', 'Desktop', 'Extract text (OCR) from screenshot', 'Copy text from the screen', 'shot', 'Text copied', 'Extract text', 'capture'))

if (typeof module !== 'undefined') module.exports = lessons
