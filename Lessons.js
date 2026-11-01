// Descriptions match Omarchy 4.5 defaults. Actual chords come from hyprctl binds.
var lessons = [
  {id:'terminal', category:'Applications', description:'Terminal', title:'Open a terminal', detail:'Bring a new terminal into your workspace.', scene:'launch', glyph:'>_', label:'Terminal'},
  {id:'browser', category:'Applications', description:'Browser', title:'Open the browser', detail:'Start your browser without reaching for the mouse.', scene:'launch', glyph:'◎', label:'Browser'},
  {id:'files', category:'Applications', description:'File manager', title:'Open your files', detail:'Launch the file manager.', scene:'launch', glyph:'▰', label:'Files'},
  {id:'editor', category:'Applications', description:'Editor', title:'Open your editor', detail:'A fresh place to write some code.', scene:'launch', glyph:'</>', label:'Editor'},
  {id:'obsidian', category:'Applications', description:'Obsidian', title:'Open Obsidian', detail:'Bring your notes to the desktop.', scene:'launch', glyph:'◇', label:'Obsidian'},
  {id:'calculator', category:'Applications', description:'Calculator', title:'Open the calculator', detail:'A quick calculation, one chord away.', scene:'launch', glyph:'±', label:'Calculator'},
  {id:'music', category:'Applications', description:'Music', title:'Open your music player', detail:'Launch your music application.', scene:'launch', glyph:'♫', label:'Music'},
  {id:'menu', category:'Desktop', description:'Omarchy menu', title:'Open the Omarchy menu', detail:'Your command center for the whole desktop.', scene:'menu', glyph:'⌘', label:'Omarchy'},
  {id:'keys', category:'Desktop', description:'Keybindings', title:'Find your keyboard shortcuts', detail:'Open the searchable shortcut reference.', scene:'menu', glyph:'?', label:'Keybindings'},
  {id:'close', category:'Windows', description:'Close window', title:'Close the highlighted window', detail:'Practice here—the real window stays safe.', scene:'close', glyph:'×', label:'Close'},
  {id:'float', category:'Windows', description:'Toggle window floating/tiling', title:'Float the highlighted window', detail:'Lift a window out of the tiled layout.', scene:'float', glyph:'▣', label:'Float'},
  {id:'fullscreen', category:'Windows', description:'Full screen', title:'Make the window fullscreen', detail:'Let the highlighted window take the whole screen.', scene:'fullscreen', glyph:'⛶', label:'Fullscreen'},
  {id:'layout', category:'Windows', description:'Cycle workspace layout', title:'Cycle the workspace layout', detail:'Switch between tiling, scrolling, and floating.', scene:'layout', glyph:'▥', label:'Layout'},
  {id:'left', category:'Navigation', description:'Focus on left window', title:'Focus the window on the left', detail:'Move your attention without moving the mouse.', scene:'left', glyph:'←', label:'Focus left'},
  {id:'right', category:'Navigation', description:'Focus on right window', title:'Focus the window on the right', detail:'Move focus to the neighboring window.', scene:'right', glyph:'→', label:'Focus right'},
  {id:'swap', category:'Navigation', description:'Swap window to the right', title:'Move this window to the right', detail:'Swap the highlighted window with its neighbor.', scene:'swap', glyph:'⇄', label:'Swap'},
  {id:'workspace2', category:'Workspaces', description:'Switch to workspace 2', title:'Go to workspace 2', detail:'Keep a different context one shortcut away.', scene:'workspace', glyph:'2', label:'Workspace 2'},
  {id:'move2', category:'Workspaces', description:'Move window to workspace 2', title:'Send this window to workspace 2', detail:'Move the highlighted window to another workspace.', scene:'move', glyph:'2', label:'Move to 2'},
  {id:'scratch', category:'Workspaces', description:'Toggle scratchpad', title:'Reveal the scratchpad', detail:'Bring your hidden scratchpad into view.', scene:'float', glyph:'▤', label:'Scratchpad'},
  {id:'next', category:'Workspaces', description:'Next workspace', title:'Go to the next workspace', detail:'Advance to your next desktop context.', scene:'workspace', glyph:'→', label:'Next workspace'}
]
if (typeof module !== 'undefined') module.exports = lessons
