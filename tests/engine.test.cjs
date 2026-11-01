const {test} = require('node:test');
const assert = require('node:assert/strict');
const E = require('../Engine.js');
const lessons = require('../Lessons.js');
const S = require('../Scenes.js');
test('reads customized shortcuts, ignores releases, mouse and other submaps', () => {
 const bindings = [
  {description:'Terminal', key:'t', modmask:68},
  {description:'Terminal', key:'x', modmask:64, submap:'resize'},
  {description:'Switch to workspace 2', key:'', keycode:11, modmask:64},
  {description:'Browser', key:'b', modmask:64, release:true}
 ];
 const out = E.resolve(lessons, bindings);
 assert.equal(out.find(x=>x.id==='terminal').chord,'SUPER+CTRL+T');
 assert.equal(out.find(x=>x.id==='ws2').chord,'SUPER+2');
 assert.equal(out.some(x=>x.id==='browser'),false);
});
test('extra modifiers are an incorrect chord, aliases normalize',()=>{
 assert.equal(E.chord('Return',65),'SUPER+SHIFT+ENTER');
 assert.notEqual(E.chord('f',65),E.chord('f',64));
});
test('wrong answers lower accuracy, do not advance, and break streaks',()=>{
 let s=E.initial(1000);
 s=E.answer(s,true,2000); s=E.answer(s,false,2500);
 assert.equal(s.correct,1); assert.equal(s.streak,0); assert.equal(s.promptAt,2000);
 s=E.answer(s,true,4000);
 assert.deepEqual(E.stats(s,4000),{seconds:3,accuracy:67,average:1.5,perMinute:40,score:143});
});
test('hints cost an attempt and cannot extend a streak',()=>{
 let s=E.answer(E.initial(0),true,1000);
 s=E.hint(E.answer(s,false,1100)); s=E.answer(s,true,2000);
 assert.equal(s.streak,0); assert.equal(s.bestStreak,1); assert.equal(E.stats(s,2000).accuracy,67);
});
test('empty deck is safe, rounds contain requested count, no batch-boundary repeats',()=>{
 assert.deepEqual(E.deck([],15,Math.random),[]);
 let d=E.deck([{id:'a'},{id:'b'}],30,()=>0.5);
 assert.equal(d.length,30);
 for(let i=1;i<d.length;i++) assert.notEqual(d[i].id,d[i-1].id);
});
test('fresh round has finite zero statistics',()=>{
 assert.deepEqual(E.stats(E.initial(0),0),{seconds:0,accuracy:0,average:0,perMinute:0,score:0});
});
test('lesson definitions have unique ids, unique descriptions and complete prompts',()=>{
 assert.equal(new Set(lessons.map(x=>x.id)).size,lessons.length);
 assert.equal(new Set(lessons.map(x=>x.description)).size,lessons.length);
 for(const l of lessons) for(const key of ['id','description','category','title','scene','label','family']) assert.ok(l[key],l.id+' '+key);
});
test('category-specific rounds never include another category',()=>{
 const available = [ {id:'a',category:'Applications'}, {id:'b',category:'Workspaces'}, {id:'c',category:'Applications'} ];
 const selected = E.categoryItems(available,'Applications');
 assert.deepEqual(selected.map(x=>x.id),['a','c']);
 assert.ok(E.deck(selected,30,Math.random).every(x=>x.category==='Applications'));
 assert.deepEqual(E.categoryItems(available,'Plugins'),[]);
 assert.deepEqual(E.categoryItems(available,'All shortcuts'),available);
});
test('memory ladder: clean answers promote, misses reset and remember the wrong chord',()=>{
 let p=E.emptyProgress();
 p=E.record(p,'close','correct','',1); p=E.record(p,'close','correct','',2);
 assert.equal(E.memory(p,'close').box,2); assert.equal(E.guided(p,'close'),false);
 p=E.record(p,'close','correct','',3); assert.equal(E.mastered(p,'close'),true);
 p=E.record(p,'close','wrong','SUPER+Q',4);
 assert.deepEqual([E.memory(p,'close').box,E.memory(p,'close').wrong,E.memory(p,'close').lastPressed],[0,1,'SUPER+Q']);
 p=E.record(p,'close','recovered','',5); assert.equal(E.memory(p,'close').box,0);
 p=E.record(p,'float','hint','',6); assert.equal(E.memory(p,'float').box,0); assert.equal(E.memory(p,'float').wrong,0);
 assert.deepEqual(E.mistakes([{id:'close'},{id:'float'},{id:'x'}],p).map(x=>x.id),['close']);
});
test('record does not mutate the previous progress object',()=>{
 const p=E.emptyProgress(); const q=E.record(p,'a','wrong','SUPER+A',1);
 assert.deepEqual(p.items,{}); assert.equal(q.items.a.wrong,1);
});
test('learn deck favours missed lessons and never repeats back to back',()=>{
 let p=E.emptyProgress();
 for(let i=0;i<4;i++) p=E.record(p,'a','correct','',i);
 p=E.record(p,'b','wrong','SUPER+X',9);
 let seed=1; const rnd=()=>{seed=(seed*16807)%2147483647; return seed/2147483647};
 const d=E.learnDeck([{id:'a'},{id:'b'},{id:'c'}],p,300,rnd);
 assert.equal(d.length,300);
 for(let i=1;i<d.length;i++) assert.notEqual(d[i].id,d[i-1].id);
 const n=id=>d.filter(x=>x.id===id).length;
 assert.ok(n('b')>n('a')); assert.deepEqual(E.learnDeck([],p,5,rnd),[]);
 assert.equal(E.learnDeck([{id:'a'}],p,3,rnd).length,3);
});
test('requeue schedules a hidden-key retest a few prompts later, once',()=>{
 const r=[{id:'a'},{id:'b'},{id:'c'},{id:'d'},{id:'e'}];
 const q=E.requeue(r,0,r[0],3);
 assert.deepEqual(q.map(x=>x.id),['a','b','c','d','a','e']); assert.equal(q[4].retest,true);
 const again=E.requeue([{id:'a'},{id:'b'},{id:'a'},{id:'c'}],0,{id:'a'},3);
 assert.deepEqual(again.map(x=>x.id),['a','b','a','c']); assert.equal(again[2].retest,true);
 assert.deepEqual(E.requeue(r,4,r[4],3).map(x=>x.id),['a','b','c','d','e','e']);
});
test('findByChord identifies what a wrong press actually does',()=>{
 const items=[{id:'close',chord:'SUPER+W'},{id:'float',chord:'SUPER+T'}];
 assert.equal(E.findByChord(items,'SUPER+W').id,'close'); assert.equal(E.findByChord(items,'SUPER+K'),null);
});

test('keycode binds recover their key from hyprctl text output',()=>{
 const text='bindd\n\tmodmask: 65\n\tkey: SUPER + SHIFT + code:11\n\tdescription: Move window to workspace 2\n\targ: 112\n\nbindd\n\tmodmask: 64\n\tkey: SUPER + code:20\n\tdescription: Expand window left\n\targ: 183\n';
 const keys=E.textKeys(text);
 assert.deepEqual(keys,{'112':'SUPER + SHIFT + code:11','183':'SUPER + code:20'});
 const live=E.withTextKeys([
  {description:'Move window to workspace 2',key:'',keycode:0,modmask:65,arg:'112'},
  {description:'Expand window left',key:'',keycode:0,modmask:64,arg:'183'},
  {description:'Switch to workspace 10',key:'',keycode:0,modmask:64,arg:'135',textKey:'SUPER + code:19'}],keys);
 const out=E.resolve(lessons,live);
 assert.equal(out.find(x=>x.id==='move2').chord,'SUPER+SHIFT+2');
 assert.equal(out.find(x=>x.id==='expand-left').chord,'SUPER+MINUS');
 assert.equal(out.find(x=>x.id==='ws10').chord,'SUPER+0');
});
test('every binding for a description is accepted, simplest shown first',()=>{
 const out=E.resolve(lessons,[{description:'Close window',key:'W',modmask:64},{description:'Close window',key:'Q',modmask:64},
  {description:'Browser',key:'RETURN',modmask:65},{description:'Browser',key:'B',modmask:65}]);
 const close=out.find(x=>x.id==='close');
 assert.deepEqual(close.chords,['SUPER+W','SUPER+Q']);
 assert.ok(E.matches(close,'SUPER+Q')); assert.ok(!E.matches(close,'SUPER+E'));
 assert.equal(E.findByChord(out,'SUPER+SHIFT+ENTER').id,'browser');
});
test('described binds without a lesson become extra lessons, once',()=>{
 const live=[{description:'Close window',key:'W',modmask:64},{description:'Toggle weather',key:'W',modmask:76},{description:'Toggle weather',key:'Y',modmask:76},{description:'',key:'Z',modmask:64}];
 const covered=E.resolve(lessons,live);
 const extra=E.extraLessons(live,covered,'More','toast');
 assert.equal(extra.length,1); assert.deepEqual(extra[0].chords,['SUPER+CTRL+ALT+W','SUPER+CTRL+ALT+Y']);
 assert.equal(extra[0].category,'More');
});
test('every lesson animates a visible change on the desktop',()=>{
 for(const l of lessons){
  const before=JSON.stringify(S.state(l.scene,l.arg,false)), after=JSON.stringify(S.state(l.scene,l.arg,true));
  assert.notEqual(before,after,l.id+' ('+l.scene+') shows no change');
 }
});
test('permutations within a family look different from each other',()=>{
 const families={};
 for(const l of lessons) (families[l.family]=families[l.family]||[]).push(l);
 for(const [name,items] of Object.entries(families)){
  if(['launch','menus','panels','clipboard-keys','capture','notify','zoom','group-step'].includes(name)) continue;
  const looks=new Set(items.map(l=>JSON.stringify([S.state(l.scene,l.arg,false),S.state(l.scene,l.arg,true)])));
  assert.equal(looks.size,items.length,'family '+name+' has identical animations');
 }
});
test('focus and swap cover all four directions',()=>{
 for(const fam of ['focus','swap','group-join']) assert.deepEqual(lessons.filter(l=>l.family===fam).map(l=>l.arg).sort(),['down','left','right','up']);
 assert.equal(lessons.filter(l=>l.family==='resize').length,12);
 for(const fam of ['ws-switch','ws-move','ws-silent']) assert.equal(lessons.filter(l=>l.family===fam).length,10);
});
test('progress loaded from disk is rebuilt into a safe shape',()=>{
 const raw=JSON.parse('{"version":1,"items":{"__proto__":{"box":4},"close":{"correct":"3","wrong":-2,"box":99,"lastPressed":"SUPER+Q","evil":"x"},"bad id!":{"box":1},"float":{"lastPressed":"<b>x</b>"},"n":null}}');
 const p=E.sanitizeProgress(raw);
 assert.deepEqual(Object.keys(p.items).sort(),['close','float']);
 assert.deepEqual(p.items.close,{correct:3,wrong:0,box:4,lastPressed:'SUPER+Q',updated:0});
 assert.equal(p.items.float.lastPressed,'');
 assert.equal(Object.getPrototypeOf(p.items),Object.prototype);
 assert.equal(E.memory(p,'toString').box,0);
 assert.deepEqual(E.sanitizeProgress(null),E.emptyProgress());
 assert.deepEqual(E.sanitizeProgress('nonsense'),E.emptyProgress());
});
