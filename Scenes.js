// Pure description of the simulated desktop for every lesson, shared by QML
// and the Node tests. state(scene, arg, after) returns where every window is
// (as fractions of the work area), which one is focused, and any overlay.
//
// Workspace 1 holds a dwindle layout: terminal on the left, browser top-right,
// editor bottom-right, so every direction (left/right/up/down) has a neighbour.

var IDS = ['a', 'b', 'c', 'd', 'e', 'f']
var OFF = 1.06 // one work area width plus a gap: fully off screen

function win(kind, r, extra) {
  return Object.assign({ kind: kind, r: r, visible: true, active: false, z: 1, full: false,
    tabs: null, pinned: false, alpha: 1, launch: false }, extra || {})
}

function base() {
  return {
    ws: 1, mode: 'tiling', bar: true, gaps: true, zoom: 1, dim: false, flash: false, barPulse: 0,
    overlay: null, ghost: null,
    windows: {
      a: win('terminal', [0, 0, 0.5, 1]),
      b: win('browser', [0.5, 0, 0.5, 0.5], { active: true }),
      c: win('editor', [0.5, 0.5, 0.5, 0.5]),
      // Workspace 2 content, parked off screen to the right.
      d: win('files', [OFF, 0, 0.5, 1]),
      e: win('music', [OFF + 0.5, 0, 0.5, 1]),
      // Spare window: launched apps, scratchpad, Quake console.
      f: win('terminal', [0.5, 0.5, 0.5, 0.5], { visible: false })
    }
  }
}

function focus(s, id) { IDS.forEach(function(k) { s.windows[k].active = k === id }); return s }
function shift(s, ids, dx) { ids.forEach(function(k) { var r = s.windows[k].r; s.windows[k].r = [r[0] + dx, r[1], r[2], r[3]] }); return s }

// Show workspace `n`. Workspace 1 is the dwindle layout, any other workspace
// shows the files + music pair. `from` decides which way the slide goes.
function showWorkspace(s, n, from) {
  var dir = n > from ? 1 : -1
  s.ws = n
  if (n === 1) {
    s.windows.d.r = [OFF, 0, 0.5, 1]; s.windows.e.r = [OFF + 0.5, 0, 0.5, 1]
    if (dir < 0) { s.windows.d.r = [OFF, 0, 0.5, 1]; s.windows.e.r = [OFF + 0.5, 0, 0.5, 1] }
    focus(s, 'b')
  } else {
    // Workspace 1 windows leave in the direction of travel.
    shift(s, ['a', 'b', 'c'], -dir * OFF)
    s.windows.d.r = [0, 0, 0.5, 1]; s.windows.e.r = [0.5, 0, 0.5, 1]
    focus(s, 'd')
  }
  return s
}
function startOn(s, n) {
  // Start on workspace n (2+ means the files/music workspace is in view and
  // workspace 1 waits off screen to the left).
  if (n === 1) return s
  s.ws = n
  shift(s, ['a', 'b', 'c'], -OFF)
  s.windows.d.r = [0, 0, 0.5, 1]; s.windows.e.r = [0.5, 0, 0.5, 1]
  return focus(s, 'd')
}
function grouped(s, kinds, active) {
  s.windows.b.r = [0.5, 0, 0.5, 1]
  s.windows.b.tabs = { kinds: kinds, active: active }
  s.windows.b.kind = kinds[active]
  s.windows.c.visible = false; s.windows.c.r = [0.5, 0, 0.5, 1]
  return focus(s, 'b')
}

var RESIZE_STEP = { normal: 0.1, little: 0.035, lot: 0.2 }

function state(scene, arg, after) {
  var s = base()
  var w = s.windows
  var dir = String(arg || '')
  switch (scene) {
  case 'focus': {
    var from = { left: 'b', right: 'a', up: 'c', down: 'b' }[dir] || 'b'
    var to = { left: 'a', right: 'b', up: 'b', down: 'c' }[dir] || 'a'
    return focus(s, after ? to : from)
  }
  case 'cycle':
    // Alt+Tab order: terminal -> browser -> editor.
    return focus(s, after ? (dir === 'prev' ? 'a' : 'c') : 'b')
  case 'closeall':
    if (after) ['a', 'b', 'c'].forEach(function(k) { w[k].visible = false })
    return s
  case 'swap': {
    var pair = { left: ['b', 'a'], right: ['a', 'b'], up: ['c', 'b'], down: ['b', 'c'] }[dir] || ['b', 'a']
    focus(s, pair[0])
    if (after) { var r = w[pair[0]].r; w[pair[0]].r = w[pair[1]].r; w[pair[1]].r = r }
    return s
  }
  case 'resize': {
    // arg: { edge: "left"|"bottom", grow: 1|-1, size: "normal"|"little"|"lot" }
    var o = typeof arg === 'object' && arg ? arg : { edge: 'left', grow: 1, size: 'normal' }
    if (!after) return s
    s.ghost = w.b.r.slice()
    var step = (RESIZE_STEP[o.size] || 0.1) * o.grow
    if (o.edge === 'left') {
      var x = 0.5 - step
      w.a.r = [0, 0, x, 1]; w.b.r = [x, 0, 1 - x, 0.5]; w.c.r = [x, 0.5, 1 - x, 0.5]
    } else {
      var y = 0.5 + step
      w.b.r = [0.5, 0, 0.5, y]; w.c.r = [0.5, y, 0.5, 1 - y]
    }
    return s
  }
  case 'workspace': {
    var n = Number(arg) || 2
    var start = n === 1 ? 2 : 1
    startOn(s, start)
    return after ? showWorkspace(base(), n, start) : s
  }
  case 'wsnext': return after ? showWorkspace(base(), 2, 1) : s
  case 'wsprev': { startOn(s, 2); return after ? showWorkspace(base(), 1, 2) : s }
  case 'wsformer': { startOn(s, 3); return after ? showWorkspace(base(), 1, 3) : s }
  case 'move': {
    var target = Number(arg) || 2
    if (!after) return target === 1 ? (s.ws = 2, s) : s
    s.ws = target
    shift(s, ['a', 'c'], target === 1 ? OFF : -OFF)
    w.b.r = [0, 0, 1, 1]
    return focus(s, 'b')
  }
  case 'silent': {
    var dest = Number(arg) || 2
    if (dest === 1) s.ws = 2
    if (!after) return s
    w.b.visible = false; w.b.toBar = dest
    w.a.r = [0, 0, 0.5, 1]; w.c.r = [0.5, 0, 0.5, 1]
    s.barPulse = dest
    return focus(s, 'c')
  }
  case 'scratch':
    w.f.kind = 'terminal'; w.f.r = [0.18, 0.1, 0.64, 0.8]; w.f.z = 6
    if (after) { w.f.visible = true; s.dim = true; focus(s, 'f') }
    return s
  case 'toscratch':
    if (!after) return s
    w.b.visible = false; w.b.r = [0.4, 0.4, 0.2, 0.2]
    w.c.r = [0.5, 0, 0.5, 1]
    s.overlay = { type: 'toast', icon: '\u{f0e1e}', label: 'Moved to scratchpad' }
    return focus(s, 'c')
  case 'quake':
    w.f.kind = 'terminal'; w.f.z = 6; w.f.r = [0, -0.5, 1, 0.45]; w.f.visible = true
    if (after) { w.f.r = [0, 0, 1, 0.45]; focus(s, 'f') }
    return s
  case 'toquake':
    if (!after) return s
    w.b.r = [0, -0.55, 1, 0.45]; w.b.z = 6
    w.c.r = [0.5, 0, 0.5, 1]
    return focus(s, 'c')
  case 'float':
    if (!after) return s
    w.b.r = [0.2, 0.12, 0.6, 0.76]; w.b.z = 4
    w.a.r = [0, 0, 0.5, 1]; w.c.r = [0.5, 0, 0.5, 1]
    return s
  case 'pop':
    if (!after) return s
    w.b.r = [0.6, 0.56, 0.38, 0.42]; w.b.z = 4; w.b.pinned = true
    w.a.r = [0, 0, 0.5, 1]; w.c.r = [0.5, 0, 0.5, 1]
    return s
  case 'fullscreen':
    if (after) { w.b.full = true; w.b.z = 8 }
    return s
  case 'tiledfull':
    if (after) { w.b.r = [0, 0, 1, 1]; w.b.z = 4 }
    return s
  case 'fullwidth':
    if (after) { w.b.r = [0, 0, 1, 0.5]; w.a.r = [0, 0.5, 0.5, 0.5]; w.c.r = [0.5, 0.5, 0.5, 0.5] }
    return s
  case 'split':
    if (after) { w.b.r = [0.5, 0, 0.25, 1]; w.c.r = [0.75, 0, 0.25, 1] }
    return s
  case 'pseudo':
    if (after) { s.ghost = w.b.r.slice(); w.b.r = [0.58, 0.07, 0.34, 0.36] }
    return s
  case 'transparent':
    if (after) w.b.alpha = 0.6
    return s
  case 'gaps':
    if (after) s.gaps = false
    return s
  case 'layout': {
    var scrolling = [[0, 0, 0.42, 1], [0.42, 0, 0.42, 1], [0.84, 0, 0.42, 1]]
    var back = Number(arg) < 0
    if (after !== back) { w.a.r = scrolling[0]; w.b.r = scrolling[1]; w.c.r = scrolling[2]; s.mode = 'scrolling' }
    return s
  }
  case 'minimize':
    if (!after) return s
    w.b.visible = false; w.b.r = [0.45, 1.02, 0.1, 0.06]
    w.c.r = [0.5, 0, 0.5, 1]
    return focus(s, 'c')
  case 'close':
    if (!after) return s
    w.b.visible = false
    w.c.r = [0.5, 0, 0.5, 1]
    return focus(s, 'c')
  case 'launch':
    // Two tiles before; the new app splits the focused browser (dwindle).
    w.b.r = [0.5, 0, 0.5, 1]; w.c.visible = false
    w.f.kind = String(arg || 'terminal'); w.f.r = [0.5, 0.5, 0.5, 0.5]
    if (after) { w.b.r = [0.5, 0, 0.5, 0.5]; w.f.visible = true; w.f.launch = true; focus(s, 'f') }
    return s
  case 'group':
    return after ? grouped(s, ['browser', 'editor'], 0) : s
  case 'ungroup':
    return after ? s : grouped(s, ['browser', 'editor'], 0)
  case 'grouptab': {
    var kinds = ['browser', 'editor', 'files', 'music', 'terminal']
    var index = dir === 'next' ? 1 : dir === 'prev' ? 0 : Math.max(0, Number(arg) - 1)
    var startTab = dir === 'next' ? 0 : dir === 'prev' ? 1 : index === 0 ? 1 : 0
    var count = Math.max(3, index + 1)
    return grouped(s, kinds.slice(0, count), after ? index : startTab)
  }
  case 'groupjoin': {
    // The focused window joins the group that lies in `arg` direction.
    if (dir === 'left') {
      focus(s, 'b')
      if (after) { w.a.tabs = { kinds: ['terminal', 'browser'], active: 1 }; w.a.kind = 'browser'; w.b.visible = false; w.c.r = [0.5, 0, 0.5, 1]; focus(s, 'a') }
    } else if (dir === 'right') {
      focus(s, 'a')
      if (after) { w.a.visible = false; w.b.r = [0, 0, 1, 0.5]; w.c.r = [0, 0.5, 1, 0.5]; w.b.tabs = { kinds: ['browser', 'terminal'], active: 1 }; w.b.kind = 'terminal'; focus(s, 'b') }
    } else if (dir === 'up') {
      focus(s, 'c')
      if (after) { w.c.visible = false; w.b.r = [0.5, 0, 0.5, 1]; w.b.tabs = { kinds: ['browser', 'editor'], active: 1 }; w.b.kind = 'editor'; focus(s, 'b') }
    } else {
      focus(s, 'b')
      if (after) { w.b.visible = false; w.c.r = [0.5, 0, 0.5, 1]; w.c.tabs = { kinds: ['editor', 'browser'], active: 1 }; w.c.kind = 'browser'; focus(s, 'c') }
    }
    return s
  }
  case 'menu':
    if (after) { s.overlay = { type: 'menu', variant: dir || 'root' }; s.dim = true }
    return s
  case 'panel':
    if (after) s.overlay = { type: 'panel', label: dir }
    return s
  case 'toast':
    if (after) s.overlay = { type: 'toast', label: dir }
    return s
  case 'shot':
    if (after) { s.flash = true; s.overlay = { type: 'toast', icon: '\u{f0100}', label: dir || 'Screenshot copied' } }
    return s
  case 'lock':
    if (after) s.overlay = { type: 'lock' }
    return s
  case 'topbar':
    if (after) s.bar = false
    return s
  case 'zoom':
    if (after) s.zoom = 1.6
    return s
  case 'zoomreset':
    if (!after) s.zoom = 1.6
    return s
  case 'notify': {
    var count = dir === 'all' ? 3 : 1
    if (!after) s.overlay = { type: 'notify', count: count }
    else if (dir === 'history') s.overlay = { type: 'panel', label: 'Notifications' }
    return s
  }
  }
  return s
}

// Menus that the "menu" scene can show.
var MENUS = {
  root: { title: 'Go…', rows: [['\u{f003b}', 'Apps'], ['\u{f09d1}', 'Learn'], ['\u{f03d8}', 'Appearance'], ['\u{f14de}', 'Trigger'], ['', 'Setup'], ['\u{f0249}', 'Install'], ['\u{f0b4c}', 'Remove'], ['\u{f0453}', 'Update'], ['\u{f02fd}', 'About'], ['\u{f0425}', 'System']] },
  keys: { title: 'Keybindings', keys: true, rows: [['Super + Return', 'Terminal'], ['Super + Shift + B', 'Browser'], ['Super + W', 'Close window'], ['Super + T', 'Toggle floating'], ['Super + F', 'Full screen'], ['Super + 1-9', 'Switch workspace'], ['Super + Space', 'Omarchy menu']] },
  apps: { title: 'Apps', rows: [['', 'Terminal'], ['\u{f059f}', 'Browser'], ['\u{f024b}', 'Files'], ['', 'Neovim'], ['\u{f082e}', 'Obsidian'], ['\u{f075a}', 'Music']] },
  system: { title: 'System', rows: [['\u{f033e}', 'Lock'], ['\u{f04b2}', 'Suspend'], ['\u{f0709}', 'Restart'], ['\u{f0425}', 'Shutdown']] },
  theme: { title: 'Theme', rows: [['\u{f03d8}', 'Tokyo Night'], ['\u{f03d8}', 'Catppuccin'], ['\u{f03d8}', 'Gruvbox'], ['\u{f03d8}', 'Nord'], ['\u{f03d8}', 'Rose Pine']] },
  background: { title: 'Background', rows: [['\u{f02e9}', 'Mountains'], ['\u{f02e9}', 'City at night'], ['\u{f02e9}', 'Gradient']] },
  clipboard: { title: 'Clipboard', rows: [['\u{f0219}', 'git status --short'], ['\u{f0219}', 'https://omarchy.org'], ['\u{f0219}', 'SUPER + SHIFT + B']] },
  emojis: { title: 'Emojis', rows: [['\u{f0785}', '\u{1f600}  grinning'], ['\u{f0785}', '\u{1f680}  rocket'], ['\u{f0785}', '\u{1f44d}  thumbs up']] },
  capture: { title: 'Capture', rows: [['\u{f0100}', 'Screenshot'], ['\u{f044a}', 'Screen recording'], ['\u{f0266}', 'Color picker'], ['\u{f0a1f}', 'Extract text']] },
  share: { title: 'Share', rows: [['\u{f0219}', 'File'], ['\u{f024b}', 'Folder'], ['\u{f014c}', 'Clipboard']] }
}

if (typeof module !== 'undefined') module.exports = { IDS: IDS, state: state, MENUS: MENUS }
