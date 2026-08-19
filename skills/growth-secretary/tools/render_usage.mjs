#!/usr/bin/env node
/**
 * render_usage.mjs · 把 usage_stats.mjs 的 JSON 渲成单文件 HTML 用量看板
 *
 * 照 references/visual-records.md 的定稿基准线:青瓷蓝单色阶 + 纸纹叠底 +
 * 数字墙 / 面积图 / GitHub 式逐日热力图 / 小倍数条 / 横向分布条 / 可展开数据表,
 * 全套入场动效并守 prefers-reduced-motion。产物自包含,双击即看,不依赖外网。
 *
 * 用法:
 *   node render_usage.mjs --data stats.json --out 看板.html [--title "..."]
 */

import fs from 'node:fs';

const argv = process.argv.slice(2);
const arg = (k, d = null) => { const i = argv.indexOf(k); return i >= 0 && argv[i + 1] ? argv[i + 1] : d; };
const DATA = arg('--data');
const OUT = arg('--out');
const TITLE = arg('--title', 'AI 用量看板');
if (!DATA || !OUT) { console.error('用法:node render_usage.mjs --data stats.json --out out.html'); process.exit(1); }

const d = JSON.parse(fs.readFileSync(DATA, 'utf8'));
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// 中文数量级:1.3 亿 / 4.5 万,比 13,000,000 好读
const cn = n => {
  n = Number(n) || 0;
  if (n >= 1e8) return (n / 1e8).toFixed(n / 1e8 >= 100 ? 0 : 1) + ' 亿';
  if (n >= 1e4) return (n / 1e4).toFixed(n / 1e4 >= 100 ? 0 : 1) + ' 万';
  return n.toLocaleString('en-US');
};
const full = n => (Number(n) || 0).toLocaleString('en-US');

const T = d.总计, K = d.口径, days = d.逐日 || [];
const since = K.区间.since, until = K.区间.until;

// ---------- 热力图:按周分列 ----------
const dayMs = 86400000;
function heatCells() {
  if (!days.length) return { cols: [], max: 0, first: null };
  const max = Math.max(...days.map(x => x.output));
  const first = new Date(days[0].day + 'T00:00:00Z');
  // 对齐到周一
  const dow = (first.getUTCDay() + 6) % 7;
  const start = new Date(first.getTime() - dow * dayMs);
  const last = new Date(days[days.length - 1].day + 'T00:00:00Z');
  const map = Object.fromEntries(days.map(x => [x.day, x]));
  const cols = [];
  for (let t = start; t <= last; t = new Date(t.getTime() + 7 * dayMs)) {
    const col = [];
    for (let i = 0; i < 7; i++) {
      const k = new Date(t.getTime() + i * dayMs).toISOString().slice(0, 10);
      col.push(map[k] ? { ...map[k], on: true } : { day: k, output: 0, on: false });
    }
    cols.push(col);
  }
  return { cols, max, first: days[0].day };
}
const heat = heatCells();
const level = v => (v <= 0 ? 0 : v / heat.max > .66 ? 4 : v / heat.max > .33 ? 3 : v / heat.max > .12 ? 2 : 1);

// ---------- 面积图 ----------
function areaPath(vals, w, h) {
  if (!vals.length) return { line: '', area: '' };
  const max = Math.max(...vals, 1);
  const step = vals.length > 1 ? w / (vals.length - 1) : w;
  const pts = vals.map((v, i) => [i * step, h - (v / max) * h]);
  const line = pts.map((p, i) => (i ? 'L' : 'M') + p[0].toFixed(1) + ' ' + p[1].toFixed(1)).join(' ');
  return { line, area: `${line} L${w} ${h} L0 ${h} Z`, max };
}
const spendSeries = days.map(x => x.output + x.cacheCreate + x.input);
const AW = 900, AH = 190;
const area = areaPath(spendSeries, AW, AH);

// ---------- 小倍数 / 分布条 ----------
const rows = (obj, key, limit = 12) => {
  const e = Object.entries(obj || {});
  const arr = e.map(([k, v]) => [k, typeof v === 'object' ? (v[key] || 0) : v]).filter(x => x[1] > 0);
  arr.sort((a, b) => b[1] - a[1]);
  return arr.slice(0, limit);
};
const bars = (list, unit = '') => {
  if (!list.length) return '<p class="empty">这一项本区间没有数据。</p>';
  const max = Math.max(...list.map(x => x[1]));
  return `<div class="bars">` + list.map(([k, v], i) => `
    <div class="bar-row" style="--i:${i}">
      <span class="bar-k" title="${esc(k)}">${esc(k)}</span>
      <span class="bar-t"><i style="--w:${(v / max * 100).toFixed(1)}%"></i></span>
      <span class="bar-v">${cn(v)}${unit}</span>
    </div>`).join('') + `</div>`;
};

const modelRows = rows(d.按模型, 'output', 8);
const projRows = rows(d.按项目, 'output', 8).map(([k, v]) => [k.replace(/^[A-Z]:\\/, '').replace(/\\/g, '/') || k, v]);
const builtinRows = rows(d.工具?.内置工具, null, 12);
const pluginRows = rows(d.工具?.插件, null, 10);
const mcpRows = rows(d.工具?.MCP服务, null, 10);
const skillRows = rows(d.工具?.skill调用, null, 14);

const tc = d.工具?.分类计数 || {};
const toolTotal = (tc.builtin || 0) + (tc.mcp || 0) + (tc.plugin || 0) + (tc.skill || 0);

const mainOut = d.主线vs子agent?.主线?.output || 0;
const subOut = d.主线vs子agent?.子agent?.output || 0;
const subPct = mainOut + subOut ? (subOut / (mainOut + subOut) * 100).toFixed(1) : '0';

// cache_create 是不是大头(按数量)
const ccRatio = T.新花token ? (T.cacheCreate / T.新花token * 100).toFixed(1) : '0';

// ---------- 成本权重:四种 token 单价不同,只看数量会看错大头 ----------
// 相对倍率(以 input=1 计,各 Claude 模型一致):缓存读 0.1× / 缓存写 1.25× / output 5×
const RATE = { cacheRead: 0.1, input: 1, cacheCreate: 1.25, output: 5 };
const weighted = {
  cacheRead: T.cacheRead * RATE.cacheRead,
  cacheCreate: T.cacheCreate * RATE.cacheCreate,
  output: T.output * RATE.output,
  input: T.input * RATE.input,
};
const wTotal = Object.values(weighted).reduce((a, b) => a + b, 0) || 1;
const wPct = k => (weighted[k] / wTotal * 100);
const costRows = [
  ['cache_read · 重读上下文', wPct('cacheRead'), '0.1×'],
  ['cache_create · 写缓存', wPct('cacheCreate'), '1.25×'],
  ['output · 模型吐字', wPct('output'), '5×'],
  ['input · 新输入', wPct('input'), '1×'],
].sort((a, b) => b[1] - a[1]);
const avgCtx = T.requests ? T.cacheRead / T.requests : 0;
const avgNew = T.requests ? T.cacheCreate / T.requests : 0;
const topCtx = (d.top会话 || [])
  .map(s => ({ ...s, ctx: s.requests ? s.cacheRead / s.requests : 0 }))
  .sort((a, b) => b.ctx - a.ctx).slice(0, 6);

const stat = (label, value, sub, cls = '') => `
  <div class="stat ${cls}">
    <div class="stat-v" data-to="${value}">${cn(value)}</div>
    <div class="stat-k">${esc(label)}</div>
    <div class="stat-s">${sub}</div>
  </div>`;

const html = `<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(TITLE)}</title>
<style>
:root{
  --bg:#F7F2EB; --ink:#081F5C; --data:#334EAC; --data-2:#7096D1;
  --faint:#BAD6EB; --grid:rgba(8,31,92,.16);
  --l0:rgba(8,31,92,.06); --l1:#BAD6EB; --l2:#7096D1; --l3:#334EAC; --l4:#081F5C;
  --ease:cubic-bezier(.22,.68,.36,1);
}
*{box-sizing:border-box}
html,body{margin:0;padding:0}
body{
  background:var(--bg); color:var(--ink);
  font:16px/1.75 "Source Han Sans SC","Noto Sans SC","PingFang SC","Microsoft YaHei",system-ui,sans-serif;
  -webkit-font-smoothing:antialiased;
}
/* 纸纹:程序化生成,自包含、不引外部图 */
body::before{
  content:""; position:fixed; inset:0; pointer-events:none; z-index:0; opacity:.5;
  mix-blend-mode:multiply;
  background-image:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='220' height='220'><filter id='g'><feTurbulence type='fractalNoise' baseFrequency='.85' numOctaves='4' stitchTiles='stitch'/><feColorMatrix type='saturate' values='0'/></filter><rect width='220' height='220' filter='url(%23g)' opacity='.36'/></svg>");
}
.wrap{position:relative; z-index:1; max-width:1080px; margin:0 auto; padding:64px 28px 96px}
header{margin-bottom:56px}
h1{font:400 40px/1.25 Georgia,"Times New Roman",serif; margin:0 0 14px; letter-spacing:.01em}
.lede{max-width:62ch; color:rgba(8,31,92,.78); margin:0 0 8px}
.meta{font-size:13px; color:rgba(8,31,92,.55); border-top:1px solid var(--grid); padding-top:12px; margin-top:20px}
section{margin:0 0 60px}
h2{font:400 24px/1.3 Georgia,serif; margin:0 0 6px; padding-bottom:10px; border-bottom:1px solid var(--grid)}
.sub{font-size:14px; color:rgba(8,31,92,.62); margin:0 0 22px}
.empty{font-size:14px; color:rgba(8,31,92,.5)}

/* 数字墙 */
/* 固定 4 列:8 个数刚好两行,不留空格子 */
.wall{display:grid; grid-template-columns:repeat(4,1fr); gap:1px; background:var(--grid); border:1px solid var(--grid)}
@media(max-width:860px){.wall{grid-template-columns:repeat(2,1fr)}}
@media(max-width:440px){.wall{grid-template-columns:1fr}}
.stat{background:var(--bg); padding:20px 18px 18px}
.stat-v{font:400 34px/1.1 Georgia,serif; color:var(--ink); letter-spacing:-.01em}
.stat-k{font-size:13px; margin-top:8px; font-weight:600}
.stat-s{font-size:12px; color:rgba(8,31,92,.55); margin-top:3px; line-height:1.5}
.stat.alt .stat-v{color:var(--data)}
.stat.mute{background:rgba(186,214,235,.28)}

/* 热力图 */
.heat{display:flex; gap:3px; align-items:flex-start; overflow-x:auto; padding-bottom:6px}
.heat-col{display:flex; flex-direction:column; gap:3px}
.cell{width:15px; height:15px; border-radius:2.5px; background:var(--l0); transform:scale(.2); opacity:0}
.reveal .cell{animation:pop .38s var(--ease) forwards; animation-delay:calc(var(--n) * 9ms)}
@keyframes pop{to{transform:scale(1); opacity:1}}
.cell.off{background:transparent}
.cell.l1{background:var(--l1)} .cell.l2{background:var(--l2)}
.cell.l3{background:var(--l3)} .cell.l4{background:var(--l4)}
.legend{display:flex; align-items:center; gap:7px; font-size:12px; color:rgba(8,31,92,.6); margin-top:14px}
.legend i{width:14px;height:14px;border-radius:2.5px;display:inline-block}

/* 面积图 */
.chart{border:1px solid var(--grid); padding:18px 16px 10px; background:rgba(255,255,255,.35)}
.chart svg{display:block; width:100%; height:auto}
.gl{stroke:var(--grid); stroke-width:1}
.ln{fill:none; stroke:var(--data); stroke-width:2; stroke-linecap:round;
    stroke-dasharray:var(--len); stroke-dashoffset:var(--len)}
.reveal .ln{animation:draw 1.5s var(--ease) forwards}
@keyframes draw{to{stroke-dashoffset:0}}
.ar{fill:var(--faint); opacity:0}
.reveal .ar{animation:fade .9s .5s var(--ease) forwards}
@keyframes fade{to{opacity:.5}}
.axis{font-size:11px; fill:rgba(8,31,92,.55)}

/* 条形 */
.bars{display:flex; flex-direction:column; gap:9px}
.bar-row{display:grid; grid-template-columns:minmax(120px,220px) 1fr 84px; gap:14px; align-items:center; font-size:14px}
.bar-k{overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:rgba(8,31,92,.85)}
.bar-t{height:12px; background:rgba(8,31,92,.06); position:relative; border-radius:6px; overflow:hidden}
.bar-t i{position:absolute; inset:0 auto 0 0; width:0; background:var(--data); border-radius:6px;
         transition:width 1s var(--ease); transition-delay:calc(var(--i) * 55ms)}
.reveal .bar-t i{width:var(--w)}
.bar-v{text-align:right; font:400 14px/1 Georgia,serif; color:rgba(8,31,92,.72); font-variant-numeric:tabular-nums}

/* 两栏 */
.cols{display:grid; grid-template-columns:1fr 1fr; gap:38px}
@media(max-width:760px){.cols{grid-template-columns:1fr} .bar-row{grid-template-columns:minmax(96px,150px) 1fr 70px}}

/* 分流条 */
.split{display:flex; height:36px; border:1px solid var(--grid); overflow:hidden}
.split div{display:flex; align-items:center; justify-content:center; font-size:12.5px; color:#fff;
  width:0; transition:width 1.1s var(--ease); white-space:nowrap; overflow:hidden}
.reveal .split div{width:var(--w)}
.split .a{background:var(--data)} .split .b{background:var(--data-2)}
.split-key{display:flex; gap:22px; font-size:13px; color:rgba(8,31,92,.7); margin-top:10px}
.split-key i{width:11px;height:11px;border-radius:2px;display:inline-block;margin-right:7px;vertical-align:-1px}

/* 结论 */
.notes{border-left:2px solid var(--data); padding:2px 0 2px 20px; margin:0}
.notes li{margin:0 0 12px; max-width:64ch}
.notes li:last-child{margin-bottom:0}

/* 数据表 */
details{border-top:1px solid var(--grid); padding-top:14px; margin-top:26px}
summary{cursor:pointer; font-size:14px; color:var(--data)}
table{border-collapse:collapse; width:100%; font-size:13px; margin-top:14px}
th,td{border-bottom:1px solid var(--grid); padding:7px 10px; text-align:right; font-variant-numeric:tabular-nums}
th:first-child,td:first-child{text-align:left}
th{font-weight:600; color:rgba(8,31,92,.7)}

/* 分区渐显 */
.fx{opacity:0; transform:translateY(14px); transition:opacity .7s var(--ease), transform .7s var(--ease)}
.fx.reveal{opacity:1; transform:none}

@media (prefers-reduced-motion:reduce){
  .fx{opacity:1 !important; transform:none !important; transition:none !important}
  .cell{opacity:1 !important; transform:none !important; animation:none !important}
  .ln{stroke-dashoffset:0 !important; animation:none !important}
  .ar{opacity:.5 !important; animation:none !important}
  .bar-t i{width:var(--w) !important; transition:none !important}
  .split div{width:var(--w) !important; transition:none !important}
}
</style></head><body><div class="wrap">

<header class="fx">
  <h1>${esc(TITLE)}</h1>
  <p class="lede">本页数字全部来自本机 <code>~/.claude/projects</code> 下的会话记录逐行聚合,不是估算、不联网、不调账号接口。区间 ${esc(since || '—')} 至 ${esc(until || '—')}。</p>
  <p class="meta">口径:<b>output + cache_create + input</b> = 这段时间真正新花掉的 token,是优化的靶子;<b>cache_read</b> 是每轮重读缓存,量极大但单价最低,单独列、不并进总花费。扫描 ${full(K.扫描.文件数)} 个会话文件 / ${full(K.扫描.总行数)} 行,命中 ${full(K.扫描.命中记录)} 条。</p>
</header>

<section class="fx">
  <h2>用量总览</h2>
  <p class="sub">大字是量级(万 / 亿),精确值在页末数据表。</p>
  <div class="wall">
    ${stat('新花 token', T.新花token, 'output+cache_create+input,优化靶子', 'alt')}
    ${stat('output', T.output, '模型吐出来的字,最贵')}
    ${stat('cache_create', T.cacheCreate, `写缓存,占新花的 ${ccRatio}%`)}
    ${stat('input', T.input, '未命中缓存的新输入')}
    ${stat('cache_read', T.cacheRead, `重读缓存,命中率 ${T.缓存命中率}%`, 'mute')}
    ${stat('请求数', T.requests, '一次 API 往返算一次')}
    ${stat('活跃天数', T.活跃天数, `${esc(since || '')} 起`)}
    ${stat('会话数', T.会话数, `覆盖 ${full(T.项目数)} 个工作目录`)}
  </div>
</section>

<section class="fx">
  <h2>成本权重 · 只看 token 数量会看错大头</h2>
  <p class="sub">四种 token 单价差 50 倍。以 input 为 1:重读缓存 0.1×、写缓存 1.25×、output 5×(各 Claude 模型倍率一致)。按倍率加权后的真实占比:</p>
  <div class="bars">
    ${costRows.map(([k, p, r], i) => `
    <div class="bar-row" style="--i:${i}">
      <span class="bar-k">${esc(k)} <span style="opacity:.55">${r}</span></span>
      <span class="bar-t"><i style="--w:${p.toFixed(1)}%"></i></span>
      <span class="bar-v">${p.toFixed(1)}%</span>
    </div>`).join('')}
  </div>
  <p class="sub" style="margin-top:20px">每次请求平均<b>读回 ${full(Math.round(avgCtx))}</b> token 的上下文,<b>新写 ${full(Math.round(avgNew))}</b> token 缓存。上下文越大,之后每一轮都在为它付重读的钱。</p>
  <h3 style="font:600 14px/1 inherit;margin:24px 0 14px">上下文最大的几个对话(平均每轮读回)</h3>
  ${bars(topCtx.map(s => {
    const p = (s.project || '').replace(/^[A-Z]:\\/, '').replace(/\\/g, '/') || '(未记录目录)';
    return [`${p} · ${full(s.requests)} 轮`, Math.round(s.ctx)];
  }))}
</section>

<section class="fx">
  <h2>逐日热力</h2>
  <p class="sub">按当日 output 分档,颜色越深当天吐得越多。空格 = 那天没开工。</p>
  <div class="heat">
    ${heat.cols.map((col, ci) => `<div class="heat-col">${col.map((c, ri) => {
      const lv = c.on ? level(c.output) : -1;
      const cls = lv < 0 ? 'cell off' : 'cell l' + lv;
      const t = c.on ? `${c.day} · output ${full(c.output)} · 工具 ${full(c.tools || 0)} 次` : c.day;
      return `<div class="${cls}" style="--n:${ci * 7 + ri}" title="${esc(t)}"></div>`;
    }).join('')}</div>`).join('')}
  </div>
  <div class="legend"><span>少</span>
    <i style="background:var(--l0)"></i><i style="background:var(--l1)"></i><i style="background:var(--l2)"></i><i style="background:var(--l3)"></i><i style="background:var(--l4)"></i>
    <span>多</span><span style="margin-left:14px">峰值 ${cn(heat.max)} output / 天</span>
  </div>
</section>

<section class="fx">
  <h2>每日新花 token</h2>
  <p class="sub">output + cache_create + input 的逐日曲线。峰值 ${cn(area.max || 0)} / 天。</p>
  <div class="chart">
    <svg viewBox="0 0 ${AW} ${AH + 26}" preserveAspectRatio="none" role="img" aria-label="每日新花 token 趋势">
      ${[0, .25, .5, .75, 1].map(f => `<line class="gl" x1="0" y1="${(AH * f).toFixed(1)}" x2="${AW}" y2="${(AH * f).toFixed(1)}"/>`).join('')}
      <path class="ar" d="${area.area}"/>
      <path class="ln" d="${area.line}" style="--len:${AW * 2.2}"/>
      <text class="axis" x="0" y="${AH + 20}">${esc(days[0]?.day || '')}</text>
      <text class="axis" x="${AW}" y="${AH + 20}" text-anchor="end">${esc(days[days.length - 1]?.day || '')}</text>
    </svg>
  </div>
</section>

<section class="fx">
  <h2>模型与项目</h2>
  <p class="sub">左:各模型吐出的 output。右:各工作目录的 output。</p>
  <div class="cols">
    <div><h3 style="font:600 14px/1 inherit;margin:0 0 14px">按模型</h3>${bars(modelRows)}</div>
    <div><h3 style="font:600 14px/1 inherit;margin:0 0 14px">按工作目录</h3>${bars(projRows)}</div>
  </div>
</section>

<section class="fx">
  <h2>主线 vs 子 agent</h2>
  <p class="sub">子 agent(后台并行的分身)吃掉 output 的 ${subPct}%。这个比例高说明活是分出去干的,低说明都在主线硬扛。</p>
  <div class="split">
    <div class="a" style="--w:${(100 - subPct)}%">${100 - subPct >= 15 ? '主线 ' + cn(mainOut) : ''}</div>
    <div class="b" style="--w:${subPct}%">${subPct >= 15 ? '子 agent ' + cn(subOut) : ''}</div>
  </div>
  <div class="split-key">
    <span><i style="background:var(--data)"></i>主线 ${cn(mainOut)}（${(100 - subPct).toFixed(1)}%）</span>
    <span><i style="background:var(--data-2)"></i>子 agent ${cn(subOut)}（${subPct}%）</span>
  </div>
</section>

<section class="fx">
  <h2>工具 · MCP · 插件 · skill</h2>
  <p class="sub">共 ${full(toolTotal)} 次调用:内置 ${full(tc.builtin || 0)} · 插件 ${full(tc.plugin || 0)} · 独立 MCP ${full(tc.mcp || 0)} · skill ${full(tc.skill || 0)}。</p>
  <div class="cols">
    <div>
      <h3 style="font:600 14px/1 inherit;margin:0 0 14px">内置工具</h3>${bars(builtinRows, ' 次')}
      <h3 style="font:600 14px/1 inherit;margin:26px 0 14px">插件(MCP)</h3>${bars(pluginRows, ' 次')}
      <h3 style="font:600 14px/1 inherit;margin:26px 0 14px">独立 MCP 服务</h3>${bars(mcpRows, ' 次')}
    </div>
    <div><h3 style="font:600 14px/1 inherit;margin:0 0 14px">skill 调用</h3>${bars(skillRows, ' 次')}</div>
  </div>
</section>

<section class="fx">
  <h2>读数</h2>
  <ul class="notes">
    <li><b>最大的开销是"重读上下文",占 ${wPct('cacheRead').toFixed(1)}%。</b>单看 token 数量会误判成 cache_create 是大头(它占新花量的 ${ccRatio}%),但重读的单价虽只有 0.1×,量是 ${(T.cacheRead / Math.max(1, T.cacheCreate)).toFixed(0)} 倍,加权后反超。平均每轮要读回 ${full(Math.round(avgCtx))} token。</li>
    <li><b>所以真正的杠杆是"别让单个对话把上下文养肥"。</b>上下文不是一次性成本:第 100 轮读进来的一个大文件,会在剩下的每一轮里被重读一遍。一次多读 3 万 token、后面还有 1000 轮,代价就是 3 万 × 1000 × 0.1。该做的是及时压缩、到自然边界就开新对话、别顺手读整个大文件。</li>
    <li><b>常驻规则不是主战场。</b>全部 skill 描述 + 全局规则加起来只占平均上下文的百分之几。值得顺手收拾,但指望靠它省钱是找错了地方——${skillRows.length ? `顺带一提,${esc(skillRows[0][0])} 用了 ${skillRows[0][1]} 次,多数 skill 只被叫过 1–4 次。` : ''}</li>
    <li><b>output 占 ${wPct('output').toFixed(1)}%。</b>单价最贵(5×),但量只有 ${cn(T.output)}。少写废话有用,不过它排第三。子 agent 目前只吃掉 output 的 ${subPct}%——把重活分出去,子 agent 的上下文是独立的,不会推高主线那 ${full(Math.round(avgCtx))} token 的重读账。</li>
    <li><b>独立 MCP 服务 ${full(tc.mcp || 0)} 次调用。</b>挂着没用的连接器该摘,但按上面的账,这属于零头,别当成省钱手段。</li>
  </ul>
</section>

<details class="fx">
  <summary>展开原始数据表</summary>
  <table>
    <thead><tr><th>模型</th><th>output</th><th>cache_create</th><th>input</th><th>cache_read</th><th>请求</th></tr></thead>
    <tbody>${Object.entries(d.按模型 || {}).map(([k, v]) => `<tr><td>${esc(k)}</td><td>${full(v.output)}</td><td>${full(v.cacheCreate)}</td><td>${full(v.input)}</td><td>${full(v.cacheRead)}</td><td>${full(v.requests)}</td></tr>`).join('')}
    <tr><td><b>合计</b></td><td><b>${full(T.output)}</b></td><td><b>${full(T.cacheCreate)}</b></td><td><b>${full(T.input)}</b></td><td><b>${full(T.cacheRead)}</b></td><td><b>${full(T.requests)}</b></td></tr></tbody>
  </table>
  <table>
    <thead><tr><th>日期</th><th>output</th><th>cache_create</th><th>input</th><th>cache_read</th><th>工具调用</th></tr></thead>
    <tbody>${days.filter(x => x.requests).map(x => `<tr><td>${x.day}</td><td>${full(x.output)}</td><td>${full(x.cacheCreate)}</td><td>${full(x.input)}</td><td>${full(x.cacheRead)}</td><td>${full(x.tools)}</td></tr>`).join('')}</tbody>
  </table>
</details>

<p class="meta">生成于 ${esc((d.生成时间 || '').slice(0, 19).replace('T', ' '))} UTC · 数据源 ${esc(K.数据源)} · 由 growth-secretary 的 <code>usage_stats.mjs</code> + <code>render_usage.mjs</code> 产出,可随时重跑</p>

</div><script>
(function(){
  var reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  var els = document.querySelectorAll('.fx');
  function countUp(root){
    root.querySelectorAll('.stat-v[data-to]').forEach(function(el){
      var to = +el.dataset.to, txt = el.textContent, t0 = null, dur = 900;
      if (reduce || !to) return;
      function fmt(n){
        if (n >= 1e8) return (n/1e8).toFixed(n/1e8>=100?0:1) + ' 亿';
        if (n >= 1e4) return (n/1e4).toFixed(n/1e4>=100?0:1) + ' 万';
        return Math.round(n).toLocaleString('en-US');
      }
      function step(t){
        if (!t0) t0 = t;
        var p = Math.min(1, (t - t0)/dur), e = 1 - Math.pow(1-p, 3);
        el.textContent = fmt(to * e);
        if (p < 1) requestAnimationFrame(step); else el.textContent = txt;
      }
      requestAnimationFrame(step);
    });
  }
  if (reduce || !('IntersectionObserver' in window)) {
    els.forEach(function(e){ e.classList.add('reveal'); });
    return;
  }
  var io = new IntersectionObserver(function(list){
    list.forEach(function(en){
      if (!en.isIntersecting) return;
      en.target.classList.add('reveal');
      countUp(en.target);
      io.unobserve(en.target);
    });
  }, { threshold: .12, rootMargin: '0px 0px -8% 0px' });
  els.forEach(function(e){ io.observe(e); });
})();
</script></body></html>`;

fs.writeFileSync(OUT, html, 'utf8');
console.error(`写出:${OUT}  (${(Buffer.byteLength(html) / 1024).toFixed(1)} KB)`);
