# AI 对话治理框架 · Reusable Governance for Multi-AI Work

> **多个 AI 对话老是失忆、互相打架、说不清哪份文件才算数?**
> 这套框架把「事实」钉进文件,让任何 AI 一接手就知道:**去哪读、谁说了算、什么还没确认、什么时候该停下问你。**

`治理规范 v2.2` · `发布 v2.2.3` · `校验 validate_runtime 11 / validate_paths 6 / validate_release 4 全通过` · `纯复用层,零个人信息`

---

## 30 秒看它值不值

|  | 没有它 | 有了它 |
|---|---|---|
| 改个错别字 | AI 把整本 14KB 宪章 + 你全部偏好塞进上下文 | 先判 **QUICK**,只读 3 个小文件(约 3800 字) |
| 换台电脑 | 忘了项目在哪、谁能提交、哪份是正本 | 方法一字不改,只重填本机事实 |
| 多个对话 | 各说各话、互相覆盖、事故说不清 | 一套权威顺序 + 四维状态 + 门禁,冲突有据可查 |
| 回执 | 长篇「我理解了…」,证据全无 | 三行:Changed / Verified / Remaining |

## 快速开始 · 5 分钟

```bash
git clone <你 fork 的本框架仓>
cd governance-framework
python -X utf8 tools/validate_runtime.py     # 先证明它是真的、测过的
```

你会看到:

```text
--- 11 passed, 0 failed ---
```

然后把日常启动器**整段**贴给你的 AI(Claude / Codex / 任意对话),再给它一个任务:

```text
# 复制 launchers/总管AI-日常启动-v2.txt 全文 → 贴给 AI → 给一个具体任务
```

## 看它怎么干活(一个真实任务)

> **你**:帮我把 README 里那个错别字改一下。
>
> **AI(照本框架)**:
> 1. 读 `runtime/00-entry.md` → 判为 **QUICK**(改一个已知文件、可回滚)。
> 2. 只加载 `runtime/` 三件(入口 + 承重规则 + 用户画像),**不翻完整宪章**。
> 3. 改完给你三行:
>
> ```text
> Changed:   README.md 第 12 行 "的的" → "的"
> Verified:  已重读该行确认
> Remaining: 无
> ```

没有长篇开工声明、没有整本规则复述——**该轻的地方轻,该停的地方停。** 只有真正高风险(删除 / 越权 / 公开发布)才升级模式、走门禁、停下来问你。

## 它保证什么 · 七条根本原则

1. **用户是唯一最高决策人** —— 方向、批准、删除、发布终归你。
2. **文档高于对话记忆** —— 给不出来源的,只是待核线索,不是事实。
3. **一事一正本** —— 每类事实只有一个可编辑真相源。
4. **先证明来源,再陈述事实** —— 缺证据就标 `UNKNOWN`,不硬编。
5. **探索与决定分离** —— 只有指定批准人能把草稿升为「已批准」。
6. **没进正式记录,不算完成** —— 无产物 / 验证 / 路径 / 回滚 = 口头完成。
7. **总管有治理权,无无限执行权** —— 协调可以,越权删改不行。

## 结构一览

```text
core/       治理内核(七原则 / 四维状态 / 权威顺序 / 门禁)
runtime/    最小加载层(入口 + 承重规则 GOV-001~012 + 用户画像位 + 路由)
launchers/  分模式启动 / 手动提示词  ← 复制即用
profiles/   user/ 用户画像模板;machines/ 机器 Profile 模板
projects/   项目 adapter 协议与模板
adapters/   Claude / Codex / 通用 平台加载与硬权限适配
templates/  开工声明、任务包、回执、决策记录…
skills/     总管 skill(global-ai-dialogue-governor)
tools/      校验器(validate_runtime / validate_paths / validate_release)
docs/       专项手册(按需)  ·  VERSIONS.md 版本维度  ·  分层导航 两层怎么分
```

## 换电脑 / 落地(3 步)

1. **带走本框架**(不改一个字)。
2. 复制 `profiles/user/user-profile.template.md` 填成你的画像;用
   `machine-profile.template.yaml` / `project-adapter.template.yaml` 为本机重填事实。
   **填好的实例存进你自己的私有仓,别塞回本框架。**
3. `python -X utf8 tools/validate_runtime.py` 自检。

> 复用流程(本框架) vs 本机适配(你的私有仓)怎么分,见 `分层导航-复用层与本机层.md`。

## 许可

MIT License,见 `LICENSE`。(暂定 MIT,可日后调整。)
