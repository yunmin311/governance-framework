# AI 对话治理框架 · 可复用层

> 面向「一个人 + 多个 AI 对话 + 多项目 + 多平台 + 多电脑」的**可复用治理框架**。
> 让任何接手的 AI 都能回答:去哪读取事实、什么覆盖什么、哪些尚未确认、何时必须停下交还用户。

**这是纯复用层,不含任何个人信息。** 用户画像是空白模板,机器实例、项目适配、来源证据都不在此仓——
它们属于**你自己的私有实例仓**,各自维护。本框架换任何电脑一字不改。

| 维度 | 版本 | 状态 |
|---|---|---|
| 治理规范 governance-spec | v2.2 | APPROVED |
| 工程接线 engineering-wiring | v2.2.1 | — |
| 发布打包 release-package | v2.2.3 | APPROVED |

详见 `VERSIONS.md`。

## 结构

```text
core/       治理内核(宪章:七原则 / 四维状态 / 权威顺序 / 门禁)
runtime/    普通任务最小加载层(入口 + 承重规则 GOV-001~012 + 用户画像位 + 路由)
profiles/   user/ 用户画像**模板**;machines/ 机器 Profile 模板
projects/   项目 adapter 协议与模板
adapters/   Claude / Codex / 通用 平台加载与硬权限适配
templates/  开工声明、任务包、回执、决策记录等模板
skills/     总管 skill(global-ai-dialogue-governor)
launchers/  分模式启动 / 手动提示词
docs/       专项手册(按需)
registry/   来源登记模板、候选能力登记
migration/  规则追踪(rule-traceability)
tools/      校验器(validate_runtime / validate_paths / validate_release)
```

## 怎么用(新电脑落地三步)

1. 带走本框架(不改)。
2. 复制 `profiles/user/user-profile.template.md` 填成你的用户画像;用
   `profiles/machines/machine-profile.template.yaml`、`projects/project-adapter.template.yaml`
   为本机重填机器与项目事实。这些**填好的实例存进你自己的私有仓,不要塞回本框架**。
3. 自检:`python -X utf8 tools/validate_runtime.py` / `validate_paths.py` / `validate_release.py`。

## 分层最小加载

普通任务不通读全库。入口 `runtime/00-entry.md` 先判 `QUICK / NORMAL / STRUCTURAL / INCIDENT`,
再按 `runtime/router.yaml` 只加载该模式文件(QUICK 只读 runtime 三件)。

## 许可

见 `LICENSE`。开源前请替换为正式许可(如 MIT / Apache-2.0)。
