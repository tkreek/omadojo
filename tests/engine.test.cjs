const {test} = require('node:test');
const assert = require('node:assert/strict');
const E = require('../Engine.js');
const lessons = require('../Lessons.js');
test('reads customized shortcuts, ignores releases, mouse and other submaps', () => {
 const bindings = [
  {description:'Terminal', key:'t', modmask:68},
  {description:'Terminal', key:'x', modmask:64, submap:'resize'},
  {description:'Switch to workspace 2', key:'', keycode:11, modmask:64},
  {description:'Browser', key:'b', modmask:64, release:true}
 ];
 const out = E.resolve(lessons, bindings);
 assert.equal(out.find(x=>x.id==='terminal').chord,'SUPER+CTRL+T');
 assert.equal(out.find(x=>x.id==='workspace2').chord,'SUPER+2');
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
test('lesson definitions have unique ids and complete visual prompts',()=>{
 assert.equal(new Set(lessons.map(x=>x.id)).size,lessons.length);
 for(const l of lessons) for(const key of ['id','description','category','title','detail','scene','glyph','label']) assert.ok(l[key]);
});
