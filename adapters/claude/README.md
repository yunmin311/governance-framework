---
schema_version: 2
layer: platform-adapter
platform: claude
status: APPROVED
hard_enforcement: UNVERIFIED
---

# Claude 平台适配

## 目标

让 Claude 在进入一台电脑或一个项目时可靠读取正确层级，同时明确区分“上下文加载”和“机械约束”。本文不是 Claude 配置的第二正本；它记录装配方法和验证门。

## 上下文加载

建议装配顺序：

1. 读取治理内核 `core/01-governance-charter-v2.md`；
2. 读取用户 Profile `profiles/user/user-profile.template.md`；
3. 解析当前机器 Profile；
4. 取得稳定 `project_id`，从当前机器的 `project_bindings` 解析本机路径；
5. 读取 `projects/instances/<project_id>.adapter.yaml`；缺失时进入只读发现，绝不替用另一个项目 adapter；
6. 读取项目自己的唯一 `CLAUDE.md`；
7. 读取当前角色卡、任务 Spec 和必要基线。

项目 `CLAUDE.md` 可以使用平台实测支持的导入机制引用稳定规则，但不能人工复制总章全文后独立维护。每次安装都要用无害测试确认导入是否真的被加载；没有测试证据时标 `UNVERIFIED`。

## 机械约束

`CLAUDE.md`、Prompt 和 Skill 只能提供上下文，不能保证危险工具调用一定被阻止。以下红线应在平台支持时进入 Hook 或外围权限：

- 设计角色运行 Git 写命令；
- 把 private 或公司材料写进公开仓库；
- 写入另一个项目；
- 删除、强推、改远端和历史改写；
- 覆盖冻结设计或项目正本。

Hook 必须由机器 Profile 登记版本、作用域、测试命令、预期阻断、实际结果和回滚方法。没有完成无害阻断测试时，`hard_enforcement` 保持 `UNVERIFIED`。

## 最小验证

1. 新对话复述治理根、用户角色、当前项目正本和自身写入范围；
2. 把一个不存在的来源放入任务，确认它标为 `UNKNOWN` 而不是声称已读；
3. 使用临时测试目录触发一条无害禁令，确认 Hook 阻止并留下可解释回执；
4. 确认回滚后正常授权命令仍可运行。

## 失败处理

自动加载失败时进入 `DISCOVERY-READ-ONLY`，把实际读到与未读到的来源分开列出。不要用再复制一本宪章来修复加载问题；先修入口、导入或 Hook，再重新验证。
