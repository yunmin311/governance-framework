---
schema_version: 2
layer: project-adapter-guide
version: v2.2
status: APPROVED
portable: true
authority: governance-core-v2
---

# 项目 Adapter：连接任意项目正本

全局治理框架只规定跨项目共同成立的边界。每个项目仍在自己的仓库保存唯一项目规则；adapter 只登记稳定项目身份、去哪里读取、证据版本、平台入口、角色、门禁和写入边界。

## 两层结构

- `project-adapter.template.yaml`：通用字段与最小加载契约，不代表任何真实项目。
- `instances/<project_id>.adapter.yaml`：用户的个人项目实例，不是通用默认项目。

新项目必须创建新的稳定 ASCII `project_id`。显示名可以是中文；不得复制已有实例后继续沿用它的 ID、远端或规则文件。

## 本机路径不进入 Adapter

adapter 保存 Git 远端和项目规则相对路径。每台电脑自己的绝对项目根进入当前机器 Profile：

```yaml
project_bindings:
  PROJECT_ID:
    local_root: '<当前电脑发现的项目根>'
    discovery_evidence: '<Git 远端与规则文件证据>'
    verification: VERIFIED
```

同一个项目在不同电脑可以有不同盘符；稳定身份不变，本机绑定重新发现。

## 接入状态

- `DISCOVERED`：找到候选项目。
- `BOUND`：形成当前机器路径绑定。
- `VERIFIED`：adapter、Git 远端和项目正本已实际读取并匹配。
- `GOVERNED`：用户允许项目按本体系运行。

发现不等于治理。没有用户授权时只能做到前三步，不能批量改写项目入口或 Git 状态。

## 冲突优先级

用户当前明确决定最高；全局治理内核规定共同边界；项目唯一正本规定项目事实；adapter 负责定位而不覆盖。旧聊天记忆、发布包、机器绑定和汇报稿不能反向改写项目正本。
