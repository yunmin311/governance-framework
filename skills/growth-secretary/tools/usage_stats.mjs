#!/usr/bin/env node
/**
 * usage_stats.mjs · 从本机 Claude Code 会话记录聚合「用量真值」
 *
 * 数据源:~/.claude/projects/<项目>/*.jsonl  每行一条记录。
 *   - message.usage       → input / output / cache_creation / cache_read tokens
 *   - message.model       → 按模型分摊
 *   - message.content[]   → type:"tool_use" 的 name,用来数工具 / MCP / 插件 / skill
 *   - timestamp / cwd / sessionId / isSidechain / slug
 *
 * 全部是本机文件,不联网、不调账号 API。
 *
 * 用法:
 *   node usage_stats.mjs                          # 全量,JSON 打到 stdout
 *   node usage_stats.mjs --since 2026-08-01       # 限定区间
 *   node usage_stats.mjs --out stats.json         # 写文件
 *
 * 口径说明(报告里要照抄):
 *   - output / cache_creation / input = 「新花的贵 token」,优化重点。
 *   - cache_read = 每轮重读缓存,量极大但单价最低,单独列、不与上面三项相加当"总花费"。
 *   - 一条 assistant 记录 = 一次 API 往返(requests)。
 */

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import readline from 'node:readline';

// ---------- 参数 ----------
const argv = process.argv.slice(2);
const arg = (k, d = null) => {
  const i = argv.indexOf(k);
  return i >= 0 && argv[i + 1] ? argv[i + 1] : d;
};
const ROOT = arg('--root', path.join(os.homedir(), '.claude', 'projects'));
const SINCE = arg('--since');            // YYYY-MM-DD,含当天
const UNTIL = arg('--until');            // YYYY-MM-DD,含当天
const OUT = arg('--out');
const QUIET = argv.includes('--quiet');

const log = (...a) => { if (!QUIET) process.stderr.write(a.join(' ') + '\n'); };

// ---------- 累加器 ----------
const zero = () => ({ input: 0, output: 0, cacheCreate: 0, cacheRead: 0, requests: 0 });
const addInto = (b, u) => {
  b.input += u.input_tokens || 0;
  b.output += u.output_tokens || 0;
  b.cacheCreate += u.cache_creation_input_tokens || 0;
  b.cacheRead += u.cache_read_input_tokens || 0;
  b.requests += 1;
};
const bump = (bucket, key, u) => addInto((bucket[key] ||= zero()), u);

const totals = zero();
const perDay = {};
const perModel = {};
const perProject = {};
const perSession = {};       // sessionId -> {…, project, slug, firstDay, lastDay}
const perDayModel = {};      // "YYYY-MM-DD|model" -> tokens
const main = zero();         // 主线(非 sidechain)
const sub = zero();          // 子 agent(sidechain)

const tools = {};            // 原始工具名 -> 次数
const skills = {};           // skill 名 -> 次数
const mcpServers = {};       // MCP server -> 次数
const plugins = {};          // 插件 -> 次数
const toolClass = { builtin: 0, mcp: 0, plugin: 0, skill: 0 };
const toolsPerDay = {};      // 日 -> 工具调用次数

let lines = 0, parsed = 0, skipped = 0, files = 0;

// ---------- 工具名分类 ----------
function classifyTool(name, input) {
  if (name === 'Skill') {
    toolClass.skill++;
    const s = (input && (input.skill || input.name)) || '(未记录)';
    skills[s] = (skills[s] || 0) + 1;
    return;
  }
  if (name.startsWith('mcp__plugin_')) {
    toolClass.plugin++;
    // mcp__plugin_<插件>_<server>__<工具>
    const rest = name.slice('mcp__plugin_'.length);
    const plug = rest.split('__')[0].split('_')[0] || rest;
    plugins[plug] = (plugins[plug] || 0) + 1;
    return;
  }
  if (name.startsWith('mcp__')) {
    toolClass.mcp++;
    const server = name.slice(5).split('__')[0] || '(未知)';
    mcpServers[server] = (mcpServers[server] || 0) + 1;
    return;
  }
  toolClass.builtin++;
}

// ---------- 主循环 ----------
function inRange(day) {
  if (SINCE && day < SINCE) return false;
  if (UNTIL && day > UNTIL) return false;
  return true;
}

async function scanFile(file, projectDir) {
  files++;
  const rl = readline.createInterface({
    input: fs.createReadStream(file, { encoding: 'utf8' }),
    crlfDelay: Infinity,
  });
  for await (const line of rl) {
    lines++;
    // 便宜的预筛:没有 usage 也没有 tool_use 的行直接跳过,省掉 JSON.parse
    if (line.length < 40) continue;
    const hasUsage = line.includes('"usage"');
    const hasTool = line.includes('"tool_use"');
    if (!hasUsage && !hasTool) continue;

    let rec;
    try { rec = JSON.parse(line); } catch { skipped++; continue; }
    const ts = rec.timestamp;
    if (!ts) continue;
    const day = ts.slice(0, 10);
    if (!inRange(day)) continue;
    parsed++;

    const msg = rec.message || {};
    const project = rec.cwd || projectDir;
    const sid = rec.sessionId || '(无会话号)';

    if (hasUsage && msg.usage) {
      const u = msg.usage;
      const model = msg.model || '(未记录)';
      addInto(totals, u);
      addInto(rec.isSidechain ? sub : main, u);
      bump(perDay, day, u);
      bump(perModel, model, u);
      bump(perProject, project, u);
      bump(perDayModel, `${day}|${model}`, u);

      const s = (perSession[sid] ||= { ...zero(), project, slug: null, firstDay: day, lastDay: day });
      addInto(s, u);
      if (day < s.firstDay) s.firstDay = day;
      if (day > s.lastDay) s.lastDay = day;
      if (!s.slug && rec.slug) s.slug = rec.slug;
    }

    if (hasTool && Array.isArray(msg.content)) {
      for (const c of msg.content) {
        if (c && c.type === 'tool_use' && c.name) {
          tools[c.name] = (tools[c.name] || 0) + 1;
          toolsPerDay[day] = (toolsPerDay[day] || 0) + 1;
          classifyTool(c.name, c.input);
        }
      }
    }
  }
}

const sortDesc = (obj, key = 'output') =>
  Object.entries(obj).sort((a, b) => (b[1][key] || b[1]) - (a[1][key] || a[1]));

async function run() {
  if (!fs.existsSync(ROOT)) {
    process.stderr.write(`找不到会话目录:${ROOT}\n`);
    process.exit(1);
  }
  // 会话文件是嵌套的:<项目>/*.jsonl 是主线,<项目>/<会话uuid>/agent-*.jsonl 是子 agent。
  // 两层都要,否则漏掉子 agent 的消耗(那是大头)。
  const all = [];
  const walk = (dir, projectName) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (e.name === 'memory') continue;   // 记忆档目录,不是会话
        walk(full, projectName);
      } else if (e.name.endsWith('.jsonl')) {
        all.push([full, projectName]);
      }
    }
  };
  for (const d of fs.readdirSync(ROOT, { withFileTypes: true })) {
    if (d.isDirectory()) walk(path.join(ROOT, d.name), d.name);
  }
  log(`扫描 ${all.length} 个会话文件…`);
  let n = 0;
  for (const [f, proj] of all) {
    await scanFile(f, proj);
    if (++n % 100 === 0) log(`  ${n}/${all.length}`);
  }

  const days = Object.keys(perDay).sort();
  const activeDays = days.length;
  const newSpend = totals.output + totals.cacheCreate + totals.input;
  const cacheHit = totals.cacheRead / Math.max(1, totals.cacheRead + totals.cacheCreate + totals.input);

  // 按天补齐(热力图要连续日历)
  const dense = [];
  if (days.length) {
    const d0 = new Date(days[0] + 'T00:00:00Z');
    const d1 = new Date(days[days.length - 1] + 'T00:00:00Z');
    for (let t = d0; t <= d1; t = new Date(t.getTime() + 86400000)) {
      const k = t.toISOString().slice(0, 10);
      const v = perDay[k] || zero();
      dense.push({ day: k, ...v, tools: toolsPerDay[k] || 0 });
    }
  }

  const out = {
    生成时间: new Date().toISOString(),
    口径: {
      数据源: ROOT,
      说明: 'output/cache_creation/input = 新花的贵 token(优化重点);cache_read 每轮重读缓存、量大单价最低,单独列不相加',
      区间: { since: SINCE || days[0] || null, until: UNTIL || days[days.length - 1] || null },
      扫描: { 文件数: files, 总行数: lines, 命中记录: parsed, 解析失败: skipped },
    },
    总计: {
      ...totals,
      新花token: newSpend,
      缓存命中率: +(cacheHit * 100).toFixed(1),
      活跃天数: activeDays,
      会话数: Object.keys(perSession).length,
      项目数: Object.keys(perProject).length,
    },
    主线vs子agent: { 主线: main, 子agent: sub },
    逐日: dense,
    按模型: Object.fromEntries(sortDesc(perModel)),
    按项目: Object.fromEntries(sortDesc(perProject)),
    按日模型: perDayModel,
    top会话: sortDesc(perSession).slice(0, 20).map(([id, v]) => ({ 会话: id, ...v })),
    工具: {
      分类计数: toolClass,
      内置工具: Object.fromEntries(Object.entries(tools).filter(([k]) => !k.startsWith('mcp__') && k !== 'Skill').sort((a, b) => b[1] - a[1])),
      MCP服务: Object.fromEntries(Object.entries(mcpServers).sort((a, b) => b[1] - a[1])),
      插件: Object.fromEntries(Object.entries(plugins).sort((a, b) => b[1] - a[1])),
      skill调用: Object.fromEntries(Object.entries(skills).sort((a, b) => b[1] - a[1])),
      全部工具名: Object.fromEntries(Object.entries(tools).sort((a, b) => b[1] - a[1])),
    },
  };

  const json = JSON.stringify(out, null, 2);
  if (OUT) { fs.writeFileSync(OUT, json, 'utf8'); log(`写出:${OUT}`); }
  else process.stdout.write(json);
  log(`完成:${parsed} 条命中 / ${lines} 行 / ${files} 文件`);
}

run().catch(e => { process.stderr.write(String(e && e.stack || e) + '\n'); process.exit(1); });
