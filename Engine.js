// Pure scoring and shortcut logic, shared by QML and Node tests.
var MODS = { SHIFT: 1, CTRL: 4, ALT: 8, SUPER: 64 }
function normalizedKey(key) {
  var name = String(key || '').toUpperCase()
  var aliases = { RETURN: 'ENTER', KP_ENTER: 'ENTER', ESC: 'ESCAPE', ISO_LEFT_TAB: 'TAB', ' ': 'SPACE', CONTROL: 'CTRL', META: 'SUPER' }
  return aliases[name] || name
}
function chord(key, mods) {
  var parts = []
  ;['SUPER', 'CTRL', 'ALT', 'SHIFT'].forEach(function(name) {
    if ((mods & MODS[name]) !== 0) parts.push(name)
  })
  parts.push(normalizedKey(key))
  return parts.join('+')
}
// XKB keycodes Omarchy binds by number (layout independent).
function keycodeName(code) {
  code = Number(code)
  if (code >= 10 && code <= 18) return String(code - 9)
  if (code === 19) return '0'
  if (code === 20) return 'MINUS'
  if (code === 21) return 'EQUAL'
  if (code === 34) return 'BRACKETLEFT'
  if (code === 35) return 'BRACKETRIGHT'
  return ''
}
function bindingKey(binding) {
  if (binding.key) return normalizedKey(binding.key)
  // Lua binds by keycode come back with an empty key in JSON; the text output
  // still carries "SUPER + SHIFT + code:11", merged in as textKey.
  var text = String(binding.textKey || '')
  var last = text.split('+').pop().trim()
  var match = /^code:(\d+)$/.exec(last)
  if (match) return keycodeName(match[1])
  if (last) return normalizedKey(last)
  return keycodeName(binding.keycode)
}
// Parse `hyprctl binds` text output into { arg: "MODS + key" }.
function textKeys(text) {
  var out = {}
  String(text || '').split(/\n\s*\n/).forEach(function(block) {
    var key = /\n\s*key: (.*)/.exec('\n' + block)
    var arg = /\n\s*arg: (.*)/.exec('\n' + block)
    if (key && arg) out[arg[1].trim()] = key[1].trim()
  })
  return out
}
function withTextKeys(bindings, keys) {
  return bindings.map(function(binding) {
    if (binding.key || !keys[String(binding.arg)]) return binding
    return Object.assign({}, binding, { textKey: keys[String(binding.arg)] })
  })
}
function modCount(mods) { var n = 0; for (var bit = 1; bit <= 64; bit <<= 1) if (mods & bit) n++; return n }
// Practicable binds: a real key (not a mouse button, media key or lone
// modifier) held with Super, Ctrl or Alt. Print also works on its own.
function usable(binding) {
  var key = bindingKey(binding)
  var mods = Number(binding.modmask)
  return !binding.mouse && !binding.release && !binding.submap && !binding.catch_all &&
    !!key && /^[A-Z0-9]+$/.test(key) && !/^XF86|^MOUSE/.test(key) &&
    ((mods & (64 | 4 | 8)) !== 0 || key === 'PRINT')
}
function resolve(lessons, bindings) {
  return lessons.map(function(lesson) {
    var found = bindings.filter(function(binding) { return usable(binding) && binding.description === lesson.description })
    if (!found.length) return null
    found.sort(function(x, y) { return modCount(Number(x.modmask)) - modCount(Number(y.modmask)) })
    var chords = []
    found.forEach(function(binding) {
      var value = chord(bindingKey(binding), Number(binding.modmask))
      if (chords.indexOf(value) < 0) chords.push(value)
    })
    return Object.assign({}, lesson, { chord: chords[0], chords: chords })
  }).filter(function(lesson) { return lesson !== null })
}
// Any other described Super binding becomes a generic lesson so nothing bound
// is left out.
function extraLessons(bindings, covered, category, scene) {
  var seen = {}
  covered.forEach(function(item) { (item.chords || [item.chord]).forEach(function(c) { seen[c] = true }) })
  var byDescription = {}
  bindings.forEach(function(binding) {
    if (!usable(binding) || !binding.description) return
    var value = chord(bindingKey(binding), Number(binding.modmask))
    if (seen[value]) return
    seen[value] = true
    var item = byDescription[binding.description]
    if (item) { item.chords.push(value); return }
    byDescription[binding.description] = { id: 'extra-' + value, category: category, family: 'extra-' + binding.description,
      description: binding.description, title: binding.description, scene: scene, arg: binding.description,
      label: binding.description, chord: value, chords: [value] }
  })
  return Object.keys(byDescription).map(function(key) { return byDescription[key] })
}
function matches(item, value) { return !!item && (item.chords || [item.chord]).indexOf(value) >= 0 }
function categoryItems(items, category) {
  return items.filter(function(item) { return category === 'All shortcuts' || item.category === category })
}
function shuffle(items, random) {
  var out = items.slice()
  for (var i = out.length - 1; i > 0; i--) {
    var j = Math.floor(random() * (i + 1)), value = out[i]
    out[i] = out[j]; out[j] = value
  }
  return out
}
function deck(items, count, random) {
  if (!items.length) return []
  var out = []
  while (out.length < count) {
    var batch = shuffle(items, random)
    if (out.length && batch.length > 1 && out[out.length - 1].id === batch[0].id) {
      var swap = batch[0]; batch[0] = batch[1]; batch[1] = swap
    }
    out = out.concat(batch)
  }
  return out.slice(0, count)
}
function initial(now) { return { started: now, attempts: 0, correct: 0, streak: 0, bestStreak: 0, responseTotal: 0, promptAt: now, hinted: false } }
function hint(state) { return Object.assign({}, state, { hinted: true }) }
function answer(state, correct, now) {
  var next = Object.assign({}, state, { attempts: state.attempts + 1 })
  if (!correct) { next.streak = 0; return next }
  next.correct++
  next.streak = state.hinted ? 0 : state.streak + 1
  next.bestStreak = Math.max(state.bestStreak, next.streak)
  next.responseTotal += Math.max(0, now - state.promptAt)
  next.promptAt = now
  next.hinted = false
  return next
}
function stats(state, now) {
  var seconds = Math.max(0, now - state.started) / 1000
  var accuracy = state.attempts ? state.correct / state.attempts : 0
  return { seconds: seconds, accuracy: Math.round(accuracy * 100),
    average: state.correct ? state.responseTotal / state.correct / 1000 : 0,
    perMinute: seconds > 0 ? state.correct * 60 / seconds : 0,
    score: Math.round(state.correct * 100 * accuracy + state.bestStreak * 10) }
}

// ---- Learning memory -------------------------------------------------------
// Each lesson climbs a five-step mastery ladder (box 0..4). A clean answer
// promotes it, any miss or hint sends it back to 0 and remembers what was
// pressed instead.
var MASTERED_BOX = 3
var GUIDED_BOX = 2
function emptyProgress() { return { version: 1, items: {} } }
// Rebuild progress read from disk into the exact expected shape, so a
// corrupted or hand-edited file (odd keys such as __proto__, strings,
// huge numbers) cannot leak into the trainer.
function sanitizeProgress(data) {
  var out = emptyProgress()
  var items = data && typeof data === 'object' && data.items && typeof data.items === 'object' ? data.items : {}
  function count(value, max) { value = Math.floor(Number(value)); return isFinite(value) && value > 0 ? Math.min(value, max) : 0 }
  Object.keys(items).forEach(function(id) {
    if (!/^[A-Za-z0-9+._-]{1,80}$/.test(id) || id === '__proto__' || id === 'constructor' || id === 'prototype') return
    var item = items[id]
    if (!item || typeof item !== 'object') return
    var pressed = typeof item.lastPressed === 'string' && /^[A-Z0-9+ ]{0,60}$/.test(item.lastPressed) ? item.lastPressed : ''
    out.items[id] = { correct: count(item.correct, 1e6), wrong: count(item.wrong, 1e6), box: count(item.box, 4),
      lastPressed: pressed, updated: count(item.updated, 1e15) }
  })
  return out
}
function memory(progress, id) {
  var found = progress && progress.items && progress.items[id]
  return Object.assign({ correct: 0, wrong: 0, box: 0, lastPressed: '', updated: 0 }, found || {})
}
function record(progress, id, outcome, pressed, now) {
  var items = Object.assign({}, (progress && progress.items) || {})
  var item = memory(progress, id)
  if (outcome === 'correct') { item.correct++; item.box = Math.min(4, item.box + 1) }
  else if (outcome === 'recovered') { item.correct++ }
  else if (outcome === 'hint') { item.box = 0 }
  else { item.wrong++; item.box = 0; if (pressed) item.lastPressed = pressed }
  item.updated = now || 0
  items[id] = item
  return { version: 1, items: items }
}
function mastered(progress, id) { return memory(progress, id).box >= MASTERED_BOX }
function guided(progress, id) { return memory(progress, id).box < GUIDED_BOX }
function mistakes(items, progress) {
  return items.filter(function(item) { var m = memory(progress, item.id); return m.box === 0 && m.wrong > 0 })
}
function learnWeight(progress, id) {
  var m = memory(progress, id)
  if (m.box === 0) return m.wrong > 0 ? 6 : 4
  return Math.max(1, 4 - m.box)
}
// Weighted round that favours weak and missed lessons, never repeating a
// lesson back to back.
function learnDeck(items, progress, count, random) {
  if (!items.length) return []
  // Big permutation families (workspaces 1-10, resize sizes) should not crowd
  // out everything else, so each item's weight is shared across its family.
  var familySize = {}
  items.forEach(function(item) { var f = item.family || item.id; familySize[f] = (familySize[f] || 0) + 1 })
  function weight(item) { return learnWeight(progress, item.id) / Math.sqrt(familySize[item.family || item.id]) }
  var out = []
  for (var n = 0; n < count; n++) {
    var previous = out.length ? out[out.length - 1].id : null
    var pool = items.length > 1 ? items.filter(function(item) { return item.id !== previous }) : items
    var total = pool.reduce(function(sum, item) { return sum + weight(item) }, 0)
    var pick = random() * total
    for (var i = 0; i < pool.length; i++) {
      pick -= weight(pool[i])
      if (pick < 0 || i === pool.length - 1) { out.push(pool[i]); break }
    }
  }
  return out
}
// Schedule a missed prompt to come back a few prompts later as a recall test.
function requeue(round, index, item, gap) {
  var at = Math.min(round.length, index + 1 + gap)
  var out = round.slice()
  for (var i = index + 1; i < at; i++) {
    // Already coming up soon: make that occurrence the recall test instead.
    if (out[i].id === item.id) { out[i] = Object.assign({}, out[i], { retest: true }); return out }
  }
  out.splice(at, 0, Object.assign({}, item, { retest: true }))
  return out
}
function findByChord(items, value) {
  return items.filter(function(item) { return matches(item, value) })[0] || null
}
if (typeof module !== 'undefined') module.exports = { normalizedKey: normalizedKey, chord: chord, bindingKey: bindingKey, keycodeName: keycodeName, textKeys: textKeys, withTextKeys: withTextKeys, extraLessons: extraLessons, matches: matches, usable: usable, resolve: resolve, categoryItems: categoryItems, shuffle: shuffle, deck: deck, initial: initial, hint: hint, answer: answer, stats: stats,
  emptyProgress: emptyProgress, sanitizeProgress: sanitizeProgress, memory: memory, record: record, mastered: mastered, guided: guided, mistakes: mistakes,
  learnWeight: learnWeight, learnDeck: learnDeck, requeue: requeue, findByChord: findByChord }
