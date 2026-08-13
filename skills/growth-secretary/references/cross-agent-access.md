# 多 agent 接同一份记忆 · Cross-Agent Access

对面不止一个 Codex，还有很多 agent（不同模型、不同账号、不同机器）。它们要都用上同一份记忆，就靠两件事：**记忆放在一个中立、可搬的地方** + **每个 agent 那边放一小段指针，指向它、并照同一套规矩用**。

## 一份记忆，两种位置
- **搬运正本**：你的私有记忆仓里的 `memory/`（`MEMORY.md` 索引 + 一事一档的原子）。它靠 git 跨机器/跨 agent 流动。
- **各 agent 的活副本**：每个 agent 在自己机器上读写的记忆目录。用 `tools/sync_memory.ps1` 在"活副本 ↔ 仓"之间搬，单写者 push-then-pull（谁干完活谁 push，别人先 pull 再动）。

也就是说：记忆本身不绑任何单一模型；换 agent、换账号、换机器，记忆都跟着仓走。

## 可移植指针（往任意 agent 的"全局指令"里贴这一段）
```
共享治理记忆：仓 <你的私有仓>/memory/ 里有 MEMORY.md（索引）+ 原子档。
- 开工先读 MEMORY.md；具体原子按需再读，别一次全塞。
- 记忆是"只在需要时进上下文的工具"，不通读。
- 要改用户长期画像：先提议、用户批准了才写（不自动固化，有反证要撤）。
- 跨机器同步走单写者 push-then-pull；别两处同时改。
- 回复用用户的语言。
```
这段不提任何具体模型，谁都能用。

## 各家往哪贴（对照表）
| Agent | 全局指令放哪 | 活副本记忆在哪 |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/projects/<盘符哈希>/memory/`（如 D 盘=`D--`），自动加载 |
| Codex | `~/.codex/AGENTS.md`（全局）或项目根 `AGENTS.md` | 按你给 Codex 约定的目录，用 sync 脚本对齐 |
| Cursor / Windsurf 等 | 项目 Rules / `.cursorrules` | 项目内约定目录 |
| 其它（网页版/自定义） | 该 agent 的"自定义指令 / 系统提示" | 手动 pull 到本地再喂 |

## 新机器 / 新 agent 上线三步
1. `git clone` 私有仓 → `tools/sync_memory.ps1 -Pull` 把记忆拉到本机（详见仓根 `BOOTSTRAP.md`）。
2. 把上面那段指针贴进这个 agent 的全局指令位。
3. 干完活 `-Push`，换到别的 agent/机器前先 `-Pull`。

## 底线
任何 agent 接进来，都照同一套：文档高于对话记忆、一事一正本、改画像要用户批准、单写者同步。指针只是"告诉它去哪读、按什么规矩用"，不给它新权限。
