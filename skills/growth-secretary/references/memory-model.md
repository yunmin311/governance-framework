# 记忆模型 · 四层 + 八机制 + 文件布局 + 跨模型同步

> 设计原则:正本永远是 git+markdown,所有机制靠 frontmatter + 约定实现,**不上任何数据库/向量库/常驻服务**;跨模型可移植(纯文本,各 agent 都能读写);把系统已有的 **GOV 事实优先级 / 一事一正本 / 证据纪律**延伸进记忆层,不推翻四层。完整设计与生命周期演算见维护者私有档(operation-notes/29)。

## 四层(L0 → L3,递进沉淀)
- **L0 对话**:原始交互全文。核对原话/时间/来源。不长期堆,过期归档。
- **L1 原子**:抽出的事实/偏好/约束/事件,一事一档。精确召回。= 现有记忆档。
- **L2 场景**:按项目/主题组织的知识块。快速恢复项目上下文。对应 `topics/` + 项目正本。
- **L3 人格**:长期稳定的偏好与模式。让任何 agent 快速进入上下文。= 画像层(可移植)。

## 原子档 frontmatter schema(一切机制的载体)
**新字段一律并入现有 `metadata:`(与 `type`/`node_type` 同级),不另起顶层结构;`type` 沿用现有类别枚举;`#标签` 与 `[[链接]]` 沿用放正文,不进 frontmatter。**
```yaml
---
name: example-slug              # 与文件名一致(沿用现有)
description: 一句话,召回相关性判断用(沿用现有)
metadata:
  node_type: memory             # 沿用
  type: feedback                # user | feedback | project | reference(类别,沿用)
  originSessionId: <uuid>       # 沿用
  # —— 新增·时效与溯源 ——
  source: user-said             # project-file|git|test|spec|adapter|registry|conversation|user-said
  verification: VERIFIED        # VERIFIED | UNVERIFIED | UNKNOWN
  valid_at: '2026-01-01'        # 成立起点
  invalid_at: null              # 被推翻时填日期;非 null = 已失效
  superseded_by: null           # 被哪条新档取代([[新档]])
  supersedes: null              # 本档取代了哪条旧档
  # —— 新增·生命周期与召回 ——
  status: active                # active | archived(archived 不物理删、召回默认不注入)
  weight: 3                     # 1–5:硬红线=5、稳定偏好=3–4、一次性=1–2
  last_recalled_at: '2026-01-01'# 每次被召回时更新(驱动遗忘)
  recall_count: 0
---
正文:**Why:** / **How to apply:** + #标签 + [[链接]](沿用现有约定)
```
存量档不必一次全填:新档用全套,老档"碰到即回填"(见迁移);可选一次性只补 `status: active`。`MEMORY.md` 索引行建议带 `· w3 · active`,扫索引即见权重与状态。

## 八机制(存—取—忘闭环)

**1 · atom 写入四态(ADD/UPDATE/DELETE/NOOP)**——写任何一条前,按去重键 `(type, tags/链接邻域)` 先查 `MEMORY.md`:没有=ADD;有且同一事实有实质变化=UPDATE;过时=DELETE→archive(不物理删);无变化=NOOP(只刷 `last_recalled_at`)。**别自由摘要**(实测丢 ~20% 事实)。同主题不同侧面 → ADD 不硬塞。

**2 · 双时间失效,不物理删**——事实被推翻:旧档 `invalid_at`+`superseded_by`+`status:archived`+正文顶注"已被 X 取代";新档 `valid_at`+`supersedes`。召回默认只给现行,历史可下探。可审计的"改主意"。

**3 · 冲突消解走确定性规则**——两条冲突不问模型"哪个新",按固定优先级:**项目文件/Git/测试 > 已批 Spec/baseline > adapter > 登记册 > Memory/旧对话**;同源按 `valid_at`;真平手则两条降 `confidence:low`+标 `#conflict`+并列待用户裁,不擅选。= GOV 事实优先级延伸到记忆层。

**4 · 巩固攒批,不实时**——L0→L1→L2 提炼在复盘时/计数阈值/会话末批量做,不每轮实时。L2→L3 人格**须重复出现 + 用户批准**才升(反过拟合)。省 token、少碎片。

**5 · 显式遗忘/降权**——`status` + 三信号,从不物理删:`invalid_at!=null` → archive;`weight<=2` 且久未召回(如 >90 天)且非承重 → archive;`weight>=4` 承重档永不自动 archive(只人工)。召回预算只注入 active;archived 可 grep、可复活。

**6 · 召回程序 + 反馈回路**——预算(字符/条数上限,别通读全库);优先级:未决/`#conflict` > 相关 L2 场景 > L3 画像 > 相关 L1 active(按 weight 再按 last_recalled_at);只给现行;索引优先、按需下探。**闭环**:每次真召回并用上 → `last_recalled_at=今天`+`recall_count+=1`,常用档自然保活、没人碰的冷却到期自然沉底。

**7 · 形成规则(什么才配当一条原子)**——须同时:会改变将来执行方式 / 一事一档 / 带溯源(没证据标 UNVERIFIED)/ 非可推导(仓库/git/CLAUDE.md 已记的不重存)。不存:只在本次对话有意义的临时状态、别的 AI 自述当事实。

**8 · 溯源与证据分级**——每条带 `source`+`verification`,召回一并暴露置信:VERIFIED 可当事实;UNVERIFIED = 线索不是现状(状态类事实必实测/问用户再用);UNKNOWN 留白不硬编。与机制 3 联动裁冲突。

## 文件布局(纯 markdown)
```
<memory-root>/
  MEMORY.md            # 索引:一行一条 + · w? · status,指向原子档
  <原子档>             # L1:一事一档(上面的 frontmatter + 正文 + [[链接]] + #标签)
  daily/2026-08-06.md  # 追加式日志(L0)
  topics/<主题>.md     # L2 场景/主题
```
约定:`#decision` `#preference` 等标签 + `[[wiki 链接]]`,方便关键词/语义召回。无数据库、无云、git 友好。

## 中立位置 + 跨账号/跨模型同步
- 记忆放各 agent 都能读写的**中立目录**(用户私有实例仓的 `memory/`),不放某家私有 memory 服务。
- 各 agent 各装一份**指向同一记忆目录**的薄 skill(Claude/Codex/…)。
- 同步:私有仓 push/pull,单写者(做完推、另一端先拉、永不双写)。
- 底线:换账号/换模型,最基础记忆(L1 原子 + L3 画像)必须还在。

## 迁移(不 big-bang)
新档用全套 schema;存量档"碰到即回填"(被召回/更新时补 `status`/`source`/`valid_at`);可选一次性只补 `status:active`,其余留待碰到。

## 反模式(必守)
- 确认偏误固化错误 → L3 改动须用户批准、有反证可撤销(旧档失效不删);
- 单次过拟合 → 升稳定须重复出现,单样本只挂候选;
- lost-in-middle → 召回预算 + 索引优先 + 只注入 active;
- 旧盘点当现状 → 状态类事实看 verification,UNVERIFIED 必实测/问;
- 灾难性覆盖/只升不降 → 失效不删 + 承重永不自动 archive + 召回反馈驱动退役。

## 与将来检索层的组合
上面 frontmatter 正好是将来可选 T1 检索层(SQLite FTS5 + 薄 MCP)的过滤维度(`status=active`、`invalid_at IS NULL`、`weight` 排序、`type`/`source`/`verification` 过滤)。索引是从 frontmatter 派生的可弃缓存,frontmatter 才是正本 → 机制层与检索层解耦、可分别演进;检索层是否建按信号触发,不在本文件强制。召回信号除关键词/向量外,**`[[链接]]` 邻域可当第三条**(链接图:顺双链扩,比纯向量更可审计)——现有约定天然支持,建索引时一并利用。
