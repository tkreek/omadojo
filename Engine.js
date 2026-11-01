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
function bindingKey(binding) {
  if (binding.key) return normalizedKey(binding.key)
  var code = Number(binding.keycode)
  if (code >= 10 && code <= 18) return String(code - 9)
  if (code === 19) return '0'
  return ''
}
function usable(binding) {
  return !binding.mouse && !binding.release && !binding.submap && !binding.catch_all &&
    !!bindingKey(binding) && /^[A-Z0-9]+$/.test(bindingKey(binding)) &&
    !/^XF86|^MOUSE/.test(bindingKey(binding)) && (Number(binding.modmask) & 64) !== 0
}
function resolve(lessons, bindings) {
  return lessons.map(function(lesson) {
    var found = bindings.filter(function(binding) { return usable(binding) && binding.description === lesson.description })[0]
    if (!found) return null
    var result = Object.assign({}, lesson)
    result.chord = chord(bindingKey(found), Number(found.modmask))
    return result
  }).filter(function(lesson) { return lesson !== null })
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
if (typeof module !== 'undefined') module.exports = { normalizedKey: normalizedKey, chord: chord, bindingKey: bindingKey, usable: usable, resolve: resolve, shuffle: shuffle, deck: deck, initial: initial, hint: hint, answer: answer, stats: stats }
