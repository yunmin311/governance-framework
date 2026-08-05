---
schema_version: 2
layer: machine-profile-guide
version: v2.2
status: APPROVED
portable: true
authority: governance-core-v2
---

# 机器 Profile：换电脑时重新发现，而不是照抄

机器 Profile 保存只在当前电脑成立的事实：治理仓库、Obsidian、桌面和 Skill 根目录，`project_id` 对应的项目实际位置，平台是否安装，以及上下文、Rules、Hook、permissions 是否经过无害测试。它不是用户长期偏好，也不是项目宪章。

## 首次装配流程

1. 复制 `machine-profile.template.yaml` 为本机实例；实例只留在 `profiles/machines/instances/`，不进入便携包。
2. 逐项只读发现路径与项目；用 Git 远端、稳定 `project_id` 和项目规则相对路径建立 `project_bindings`，没有证据的字段保持 `UNKNOWN`。
3. 分开验证“平台读到了文档”和“危险动作会被机械阻断”；没有实际阻断测试就保持 `UNVERIFIED`。
4. 核验 GitHub 远端、当前分支与同步方式；同一正本采用“写入设备先推送，另一台先拉取”。
5. 给出发现回执和未验证项，进入正常模式前不得用旧机器路径补空，也不得覆盖其他设备的机器 Profile。

## 多电脑项目绑定

项目 adapter 不保存任何电脑的绝对项目根。每台电脑只在自己的机器 Profile 维护：

```yaml
project_bindings:
  PROJECT_ID:
    local_root: '<当前电脑发现的项目根>'
    discovery_evidence: '<Git 远端与规则文件证据>'
    verification: VERIFIED
```

同一个 `project_id` 在不同电脑可以对应不同盘符和目录。adapter 负责稳定身份和正本相对路径，机器 Profile 负责本机位置；二者不得合并。

## 便携与私有边界

模板、字段解释、个人项目 adapter 和发现方法可以跨机器复用；机器实例中的绝对路径、账号、令牌、平台权限和本机花名册不能进入发布包。单一发布包把通用模板放在 `framework/`，把不含机器路径的项目 adapter 放在 `instance-example/`，两层不能混用。

## 失败时怎么做

治理根无法定位、项目正本不可达、远端来源变化或硬权限未验证时，保持 `DISCOVERY-READ-ONLY`。不得为了尽快开工而猜路径、复制另一台电脑的事实或宣称规则已经生效。
