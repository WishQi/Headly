// DOM integration checks for the actual standalone prototype. No user browser is controlled.
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM, VirtualConsole } = require(process.env.HEADLY_JSDOM || 'jsdom');
const html = fs.readFileSync(path.join(__dirname, '../../Prototype/index.html'), 'utf8');
const KEY = 'headly.prototype.records.v1';
let passed = 0;
function assert(condition, name) {
  if (!condition) throw Error('FAIL ' + name);
  passed++; console.log('PASS ' + name);
}
function environment(stored, options = {}) {
  const errors = [], downloads = [];
  const console = new VirtualConsole();
  console.on('jsdomError', e => errors.push(e.message));
  const dom = new JSDOM(html, {
    url: 'http://127.0.0.1:8769/Prototype/', runScripts: 'dangerously', virtualConsole: console,
    beforeParse(window) {
      if (stored !== undefined) window.localStorage.setItem(KEY, stored);
      window.URL.createObjectURL = blob => { downloads.push(blob); return 'blob:headly-test'; };
      window.URL.revokeObjectURL = () => {};
      window.HTMLAnchorElement.prototype.click = function () {};
      if (options.writeFailure) window.Storage.prototype.setItem = () => { throw Error('test quota error'); };
    }
  });
  const document = dom.window.document;
  const q = selector => document.querySelector(selector);
  const click = selector => { const element = q(selector); if (!element) throw Error('missing ' + selector); element.click(); };
  const fill = (name, value) => {
    const input = q(`[name="${name}"]`); if (!input) throw Error('missing input ' + name);
    input.value = value;
    input.dispatchEvent(new dom.window.Event(input.type === 'datetime-local' ? 'change' : 'input', { bubbles: true }));
  };
  const data = () => JSON.parse(dom.window.localStorage.getItem(KEY) || '{"records":[]}').records;
  return { dom, q, click, fill, data, errors, downloads, document };
}

let e = environment();
assert(e.q('#app').textContent.includes('从一条记录开始'), 'first launch empty state');
e.click('[data-action="new"]');
assert(e.q('[data-action="save"]').disabled, 'intensity not preselected and save disabled');
e.click('[data-action="intensity"][data-value="4"]');
e.click('[data-action="chip"][data-value="左侧"]');
e.click('[data-action="save"]');
assert(e.data().length === 1 && !e.data()[0].endedAt, 'quick save ongoing record');
const id = e.data()[0].id, created = e.data()[0].createdAt;
let reopened = environment(e.dom.window.localStorage.getItem(KEY));
assert(reopened.data()[0].id === id && reopened.q('#app').textContent.includes('头痛记录进行中'), 'reload retains same ongoing record');
reopened.dom.window.close();
e.click('[data-action="new"]'); e.click('[data-action="intensity"][data-value="7"]'); e.click('[data-action="save"]');
assert(e.q('[role="alert"]').textContent.includes('已有一条') && e.data().length === 1, 'second ongoing rejected without losing draft');
e.click('[data-action="close"]'); e.click('[data-action="confirm-no"]');
assert(e.q('.modal .intensity-number').textContent === '7', 'cancel discard retains draft');
e.click('[data-action="close"]'); e.click('[data-action="confirm-yes"]');
assert(!e.q('.modal'), 'confirmed discard closes unchanged draft');
e.click('[data-action="detail"]'); e.click('[data-action="edit"]');
if (!e.q('[name="notes"]')) e.click('[data-action="expand"]');
e.fill('notes', '=SUM(1,2)\n中文，"引号"');
e.click('[data-action="chip"][data-field="factors"][data-value="睡眠不足"]');
e.click('[data-action="save"]');
assert(e.data()[0].id === id && e.data()[0].createdAt === created && e.data()[0].notes.includes('中文'), 'edit preserves identity creation time and text');
// Move start slightly earlier before testing finish, avoiding equal-time event timestamps.
e.click('[data-action="detail"]'); e.click('[data-action="edit"]');
const earlier = new Date(Date.now() - 3600000);
const local = d => `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}T${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`;
e.fill('startedAt', local(earlier)); e.click('[data-action="save"]');
e.click('[data-action="detail"]'); e.click('[data-action="finish"]');
assert(!!e.data()[0].endedAt && e.data()[0].id === id, 'finish updates same record');
e.click('[data-action="review"]');
assert(e.q('#app').textContent.includes('平均时长') && e.q('.record-row'), 'review calendar statistics and records');
e.click('[data-action="settings"]'); e.click('[data-action="export"]');
assert(e.downloads.length === 1 && e.downloads[0].type === 'text/csv;charset=utf-8' && e.downloads[0].size > 100, 'CSV download assembled');
e.click('[data-action="close"]'); e.click('[data-action="detail"]'); e.click('[data-action="delete"]'); e.click('[data-action="confirm-no"]');
assert(e.data().length === 1, 'delete cancellation preserves record');
e.click('[data-action="delete"]'); e.click('[data-action="confirm-yes"]');
assert(e.data().length === 0 && !e.q('.record-row'), 'confirmed delete persists and updates review');
e.click('[data-action="demo"]'); e.click('[data-action="confirm-yes"]');
assert(e.data().length === 5 && e.data().every(r => r.isDemo) && e.q('.demo-label'), 'explicit demo labeled and loaded');
e.click('[data-action="demo"]');
assert(e.data().length === 5 && !e.q('.confirm-box'), 'demo cannot overwrite existing records');
e.click('[data-action="settings"]'); e.click('[data-action="clear"]'); e.click('[data-action="confirm-yes"]');
assert(e.data().length === 0, 'clear all returns persisted empty state');
e.dom.window.close();

e = environment(); e.click('[data-action="new"]'); e.click('[data-action="intensity"][data-value="2"]');
const future = new Date(Date.now() + 86400000); e.fill('startedAt', local(future)); e.click('[data-action="save"]');
assert(e.q('[role="alert"]').textContent.includes('晚于现在') && e.data().length === 0, 'future start rejected');
e.fill('startedAt', local(earlier)); const toggle = e.q('[name="ongoing"]'); toggle.checked = false; toggle.dispatchEvent(new e.dom.window.Event('change',{bubbles:true}));
e.fill('endedAt', local(new Date(+earlier - 60000))); e.click('[data-action="save"]');
assert(e.q('[role="alert"]').textContent.includes('晚于开始') && e.data().length === 0, 'invalid end rejected');
e.dom.window.close();

e = environment(undefined, { writeFailure: true }); e.click('[data-action="new"]'); e.click('[data-action="intensity"][data-value="5"]'); e.click('[data-action="save"]');
assert(e.q('[role="alert"]').textContent.includes('保存失败') && e.q('.modal .intensity-number').textContent === '5' && e.data().length === 0, 'quota error retains draft and prior storage');
e.dom.window.close();
e = environment('broken JSON');
assert(e.q('[role="alert"]').textContent.includes('原数据已保留') && e.dom.window.localStorage.getItem(KEY) === 'broken JSON', 'corrupt data original preserved');
e.click('[data-action="new"]'); e.click('[data-action="intensity"][data-value="5"]');
assert(e.q('[data-action="save"]').disabled, 'corrupt data blocks writes'); e.dom.window.close();

const seed = [{id:'fixture-1',startedAt:'2026-09-30T23:30:00+08:00',endedAt:'2026-10-01T00:30:00+08:00',intensity:6,location:'左侧',symptoms:[],factors:['压力','压力'],relief:[],medication:'',notes:'',createdAt:'2026-10-01T01:00:00+08:00',updatedAt:'2026-10-01T01:00:00+08:00',isDemo:false}];
e = environment(JSON.stringify({schemaVersion:1,records:seed}));
e.click('[data-action="detail"]'); e.click('[data-action="edit"]'); if (!e.q('[name="notes"]')) e.click('[data-action="expand"]'); e.fill('notes','当前窗口尚未保存的内容');
let changed = {...seed[0],notes:'另一个窗口已保存',updatedAt:'2026-10-03T02:00:00+08:00'};
const next = JSON.stringify({schemaVersion:1,records:[changed]});
e.dom.window.localStorage.setItem(KEY, next);
e.dom.window.dispatchEvent(new e.dom.window.StorageEvent('storage',{key:KEY,newValue:next}));
e.click('[data-action="save"]');
assert(e.q('[role="alert"]').textContent.includes('其他窗口') && e.data()[0].notes === changed.notes && e.q('[name="notes"]').value.includes('当前窗口'), 'cross window conflict rejected and both inputs preserved');
assert(e.errors.length === 0, 'prototype JavaScript runs without DOM errors');
e.dom.window.close();
console.log(`RESULT ${passed} checks passed`);
