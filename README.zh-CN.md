<div align="center">

# 🧭 AI 对话治理框架

### 给你手上的每个 AI 一份共同的事实底本 —— 让它们不再失忆、互相打架、说不清哪份文件才算数。

[![License: MIT](https://img.shields.io/badge/License-MIT-3da639.svg)](LICENSE)
[![治理规范](https://img.shields.io/badge/%E6%B2%BB%E7%90%86%E8%A7%84%E8%8C%83-v2.2-4c6ef5.svg)](VERSIONS.md)
[![发布](https://img.shields.io/badge/%E5%8F%91%E5%B8%83-v2.2.3-4c6ef5.svg)](VERSIONS.md)
[![校验器](https://img.shields.io/badge/%E6%A0%A1%E9%AA%8C%E5%99%A8-21%20passing-3da639.svg)](tools/)
[![运行时预算](https://img.shields.io/badge/%E8%BF%90%E8%A1%8C%E6%97%B6%E9%A2%84%E7%AE%97-%E2%89%A48KB-4c6ef5.svg)](tools/validate_runtime.py)
[![个人信息](https://img.shields.io/badge/%E4%B8%AA%E4%BA%BA%E4%BF%A1%E6%81%AF-%E6%97%A0-3da639.svg)](#)

[English](README.md) · **简体中文**

</div>

---

## 它解决什么

你早就不是只用一个 AI 了 —— Claude 一个窗口、Codex 一个窗口、还有浏览器标签页、同事的会话。每一个都会:

- **忘**了上次定了什么,
- 跟别的助手**互相矛盾**,
- 说不清**哪份文件才算数**,
- 要么什么都不敢碰,要么悄悄做了件不可逆的事。

换个更聪明的模型解决不了。**把事实钉进文件**才行 —— 任何一个 AI 接手时就已经知道:*去哪读、谁说了算、什么还没确认、什么时候该停下问你。*

## 你到手的是什么

|  | 没有它 | 有了这套框架 |
|---|---|---|
| 🔧 **改个错别字** | AI 把整本 14KB 宪章 + 你全部偏好塞进上下文 | 判为 **QUICK** —— 只读 3 个小文件(约 3800 字)就动手 |
| 💻 **换台电脑** | 「项目在哪?谁能提交?哪份是正本?」 | 方法一字不改 —— 你只重填*这台机*的事实 |
| 💬 **多个对话同时开** | 各说各话、互相覆盖、出事说不清 | 一套权威顺序 + 四维状态 + 门禁 —— 每处冲突都可追溯 |
| 📋 **一份进度汇报** | 一大段「我理解了……」,毫无证据 | 三行:**Changed / Verified / Remaining** |
| 🔁 **换模型 / 换账号** | 记忆和偏好每次都归零 | 基础记忆 + 个性化跟着你走,跨 agent 同步 |

## 为什么它扛得住 —— 工程上的硬功夫

大多数「AI 规则」就是一大段文字,贴进去、然后祈祷它照办。这套是当成系统来造的,下面每一条都由脚本自动核过:

- **治理几乎不占你的上下文。** 常驻加载的那一层是*有上限、且被测量*的 —— 入口 ≤ 1200 字、核心规则 ≤ 3500、你的画像 ≤ 2000,**合计 ≤ 8000**。任何一个文件超了,`validate_runtime.py` 直接判败。整本 14KB 宪章和所有手册都留在硬盘上,任务真需要时才开 —— 于是日常里 AI 读的是几 KB,不是你整座库。
- **每条规则都能追回宪章。** 15 条 `GOV-*` 规则全部在 `migration/rule-traceability.yaml` 里钉住出处,逐条标注 `none`(原文抽取)或 `added`(确为新增)—— 你能*证明*那个跑得快的 runtime 层,从没偷偷偏离它所概括的宪章。
- **它自己校验自己 —— 21 项检查、3 道闸。** `validate_runtime`(预算 · 规则唯一性 · 可追溯)、`validate_paths`(每个路径引用都能解析;每类事实只有一个正本)、`validate_release`(YAML 能解析 · 无过期命名 · 清单完整)。你改坏了什么,校验器直接点名。
- **「个人信息:无」是道构建闸,不是一句承诺。** 公开这个仓,是脚本从私有源*生成*出来的:先抹掉标识符,再**只要漏出一个违禁字符串就直接构建失败**。那个绿徽章之所以在,是因为构建拒绝产出一个会泄密的副本。
- **纯文件。零依赖。零锁定。** 全是 Markdown + YAML —— 没有常驻进程、没有要装的包、没有运行时。同一批文件能治理 Claude、Codex、一个浏览器标签页、或同事的会话,因为任何 agent 直接读就行。
- **三条互相独立的版本轴** —— 治理规范 · 工程接线 · 发布打包 —— 所以一处只改文档的修补,永远冒充不成对规则的改动。

## 怎么运作 —— 两层,一条铁律

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/architecture-dark.png">
    <img alt="两层:任意 AI 对话只加载 runtime 一层,在治理约束内动手;更深的层按需加载,你始终是唯一批准人。" src="docs/assets/architecture-light.png" width="880">
  </picture>
</p>

完整宪章、你的全套画像、每一本手册都在那儿,但**「存在 ≠ 要读它」**。普通任务永远只加载 runtime 这一层。

## 每个任务先分类,再决定开哪些重文件

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/routing-dark.png">
    <img alt="每个任务先分类为 QUICK / NORMAL / STRUCTURAL / INCIDENT,各自回一份三行回执,STRUCTURAL 还要过批准人门禁。" src="docs/assets/routing-light.png" width="880">
  </picture>
</p>

两档拿不准?取写入面更小的那一档。一旦涉及不可逆、越权或私密材料,直接进 **INCIDENT**。

## 快速开始 —— 四步上手

**1 · 装进你的 AI。** clone 下来,把两个 skill 放进你 agent 的 skills 文件夹,任何对话就能调用它:

```bash
git clone https://github.com/yunmin311/governance-framework.git
cp -r governance-framework/skills/* ~/.claude/skills/      # Claude Code
```

用 Codex 或别的 agent?拷进那个 agent 的 skills 目录即可 —— 或者干脆不装,直接把 `launchers/总管AI-日常启动-v2.txt` 整段贴进对话。

**2 · 适配成你自己的 —— 最关键的一步。** 刚下下来它还是通用的,得适配成*你的*,它才治理*你的*活:

- 复制 `profiles/user/user-profile.template.md` → 填你的角色、**你用什么语言**、报告怎么给你、哪些只有你能定;
- 用 `profiles/machines/machine-profile.template.yaml` + `projects/project-adapter.template.yaml` 记下你的项目在哪、谁能提交;
- 这些填好的文件放进**你自己的私有仓** —— 别推回本框架。

这一步,才把“硬盘上一个框架”变成“治理*我的*活、跨*我的*机器和模型”。

**3 · 自检。**

```bash
cd governance-framework
python -X utf8 tools/validate_runtime.py       # --- 11 passed, 0 failed ---
```

**4 · 用起来。** 给你的 AI 任意一个任务。它会分类、只加载需要的、在规矩内动手,并回你三行 —— 就像下面这样:

## 看它怎么干活

**小事 —— 它直接就做了。**

> **你**:帮我把 README 里那个错别字改一下。
>
> **AI(照本框架运行)**:
> 1. 读 `runtime/00-entry.md`,把任务判为 **QUICK** —— 一个已知文件、可回滚、不动结构。
> 2. 只加载 runtime 这一层:入口 + 15 条承重规则 + 你的画像(约 3800 字),**跳过**整本 14KB 宪章和所有手册 —— 因为“存在 ≠ 要读它”。
> 3. 改好、重读那行确认,给你三行回执:
>
> ```text
> Changed:   README.md 第 12 行   "的的" → "的"
> Verified:  已重读该行,改动到位
> Remaining: 无
> ```

没有冗长开工声明,没有整本规则复述 —— 该轻的地方轻。

**高风险的事 —— 它停下来,把决定权还给你。**

> **你**:不错 —— 那把旧的 `/drafts` 文件夹删了,然后全部推公开。
>
> **AI(照本框架运行)**:
> 1. 判定这**不是** QUICK:它踩了两条硬触发 —— 不可逆的**删除**和**公开发布**(`GOV-011`)。
> 2. **不往下做**。它停住,说清自己会碰什么、不碰什么,把决定还给你(`GOV-001`):
>
> ```text
> ⛔ 停 —— 这事只有你能定(GOV-001 / GOV-011)
>   • 删 /drafts    不可逆 —— 我无法证明删掉是安全的
>   • 推公开        会暴露整个仓库 —— 发布是你的决定
> 选一个:(a) 只删   (b) 只发布   (c) 两个都要 —— 请确认
> 回滚点:/drafts 还原封不动在硬盘上;什么都还没推。
> ```

这就是全部意义所在:**小事快跑,遇到任何不可逆的就急刹车 —— 决定权永远在你手里。**

## 引擎 —— 一个可移植的「总管」skill

框架本体就是一个 skill:[`skills/global-ai-dialogue-governor`](skills/global-ai-dialogue-governor/SKILL.md)。装上它(Claude / Codex / 任意 agent),或直接贴启动器,任何 AI 在动你的东西之前都会变成一个**总管**:

- **只选一个模式** —— `DISCOVERY-READ-ONLY` / `NORMAL-GOVERNANCE` / `INCIDENT-READ-ONLY`,并先声明该模式里什么不许碰;
- **只加载任务需要的层** —— 日常活先走 `runtime/`,而不是把整个库倒进对话;
- **四维状态分开记** —— 生命周期 / 执行 / 验证 / 事故,绝不把 `UNKNOWN`、`DRAFT` 当成品;
- **动手前先声明**角色、地盘、正本来源、Git 路径,收尾给一份「实际读了什么 / 改了什么 / 剩什么」的回执;
- **按风险配仪式** —— 遇到目标方向、不可逆动作、公开发布、真实花钱、改硬权限(这些只有你能定)就直接刹车。

一个精简入口文件,references 只下探一层。这就是全部引擎,仓库其余部分都是它按需去读的。

## 越用越懂你 —— 「成长秘书」skill

框架还带第二个 skill:[`growth-secretary`](skills/growth-secretary/SKILL.md)。它每周(或你点名时)回顾你这段时间怎么用的,**提议**哪些偏好值得记住,跟你确认,并且**只有你批准**才把稳定的习惯写进你的画像。系统越用越懂你,且绝不背着你偷学。

- **四层记忆**(对话 → 原子 → 场景 → 人格),纯 markdown 文件。
- **记忆跟着你走** —— 放在中立、可移植的位置,换模型、换账号都不会没。
- **学什么你批准** —— 有反证能撤销学到的模式,绝不自动固化。
- **代码记忆**只在碰代码时启用。

## 自带的防跑偏

框架会自我纠正:发现自己漂了就停下来改(`GOV-013`);不管文档是什么语言,永远用**你的**语言回复(`GOV-015`);被问到不归它管的事,简答一句再指路,不越权(`GOV-014`)。

## 它保证的 7 条根本原则

1. **用户是唯一最高决策人** —— 方向、批准、删除、发布终归你。
2. **文档高于对话记忆** —— 给不出来源的,只是待核线索,不是事实。
3. **一事一正本** —— 每类事实只有一个可编辑真相源。
4. **先证明来源,再陈述事实** —— 缺证据就标 `UNKNOWN`,不硬编。
5. **探索与决定分离** —— 只有指定批准人能把草稿升为「已批准」。
6. **没进正式记录,不算完成** —— 无产物 / 验证 / 路径 / 回滚 = 口头完成。
7. **总管有治理权,无无限执行权** —— 协调可以,越权删改不行。

## 目录结构

```text
core/        治理内核 —— 七原则 / 四维状态 / 权威顺序 / 门禁
runtime/     最小加载层 —— 入口 + 承重规则 GOV-001~015 + 用户画像位 + 路由
launchers/   分模式启动 & 手动提示词   ← 复制即用
profiles/    user/ 用户画像模板 · machines/ 机器 Profile 模板
projects/    项目 adapter 协议与模板
adapters/    Claude / Codex / 通用 加载与硬权限适配
templates/   开工声明、任务包、回执、决策记录……
skills/      总管 + 成长秘书 两个 skill
tools/       校验器 —— validate_runtime / validate_paths / validate_release
docs/        专项手册 · 分层导航指南
VERSIONS.md  三个版本维度    ·    AGENTS.md  agent 入口说明
```

## 换台电脑,方法不变

原样拷走框架,用模板只重填*这台机*的事实,再跑一遍 `python -X utf8 tools/validate_runtime.py` —— 移植就这些:方法照搬,本机事实现场重查,你填好的实例留在**你自己的私有仓**。

> 复用层与本机层为什么要分开,见 [`docs/分层导航-复用层与本机层.md`](docs/分层导航-复用层与本机层.md)。

## 版本

三个互相独立的维度 —— **治理规范**、**工程接线**、**发布打包** —— 一处只改文档的修补,永远不会冒充成规范变更。见 [VERSIONS.md](VERSIONS.md)。

## 许可

[MIT](LICENSE) —— 暂定,可日后调整。
