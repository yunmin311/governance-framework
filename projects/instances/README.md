---
schema_version: 2
layer: personal-project-instances
version: v2.2
status: APPROVED
portable: personal-overlay
authority: user
---

# 个人项目实例：稳定身份，不保存电脑路径

这里每个 `*.adapter.yaml` 对应用户的一个真实项目。它们不是通用模板、默认项目或第二本项目宪章，只保存稳定项目 ID、远端身份、项目规则相对路径、角色、门禁和验证证据。

## 在另一台电脑怎么继续使用

另一台电脑先读取通用模板，再读取这里的实例。总管使用 Git 远端、`project_id` 和项目规则相对路径，在该电脑获准访问的项目根内寻找匹配项目；实际路径只写入该电脑自己的机器 Profile：

```yaml
project_bindings:
  PROJECT_ID:
    local_root: '<当前电脑发现的项目根>'
    discovery_evidence: '<Git 远端与规则文件证据>'
    verification: VERIFIED
```

不得把家里电脑、公司电脑或其他设备的盘符写入 adapter。无法匹配时保持 `READ-ONLY`，列出候选路径和缺失证据，不得复用另一个项目的实例补空。

## 新项目怎么加入

1. 从 `../project-adapter.template.yaml` 创建新的候选文件。
2. 为项目分配独立 ASCII `project_id`；显示名可以使用中文。
3. 读取真实 Git 远端和项目唯一规则文件，记录来源证据。
4. 在当前机器 Profile 建立本机绑定。
5. 用户批准项目进入治理后，状态才从 `VERIFIED` 进入 `GOVERNED`。

发现项目不等于已经治理。未经授权，不得批量修改项目的 `AGENTS.md`、`CLAUDE.md`、文件结构或 Git 状态。
