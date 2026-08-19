---
schema_version: 2
layer: platform-adapter
platform: codex
status: APPROVED
hard_enforcement: UNVERIFIED
---

# Codex 平台适配

## 目标

让 Codex 通过目录层级 `AGENTS.md`、Skill、Rules 和 permissions 读取最小必要上下文，同时不把普通文本指针误认为可靠导入或硬权限。

## 项目中立加载

普通任务（QUICK / NORMAL）先经 `runtime/00-entry.md` 分模式，按 `runtime/router.yaml` 最小加载；只有 STRUCTURAL / INCIDENT 才执行下面的完整分层加载。

Codex 进入结构性或事故任务时必须：

1. 解析当前设备的 `governance_root`。
2. 读取治理内核和用户 Profile。
3. 读取当前机器 Profile。
4. 确认稳定 `project_id`。
5. 从 `project_bindings[project_id]` 解析当前机器的项目根。
6. 读取 `projects/instances/<project_id>.adapter.yaml`。
7. 读取 adapter 指向的项目唯一规则文件。
8. 声明当前角色、所有权和任务边界。

`AGENTS.md` 中的文本指针不证明后续文件已自动加载。必须列出实际读取来源；缺失绑定、adapter 或项目正本时保持 `READ-ONLY`。

## 机械约束

`AGENTS.md` 和 Skill 属于上下文加载。Codex Rules 用于阻断命令模式，permissions 用于限制可读写范围；任何配置在当前平台没有实际无害测试前都标为 `UNVERIFIED`。

优先机械化的红线：

- 设计角色和子代理禁用 Git 写命令。
- 工作目录不得越出当前项目授权范围。
- 禁止删除、强推、改远端和历史改写。
- private 素材不能进入公开仓库。
- 机器实例和密钥不进入便携包。

## 失败处理

加载或权限测试不符合预期时记录 Codex 版本、配置位置、输入、实际输出和回滚方式。不得拿另一个项目 adapter 顶替当前项目，也不得把 `UNVERIFIED` 改成“应该可用”。
