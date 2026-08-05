# 版本维度（三条独立编号，别混淆）

治理系统有三个互不相同的版本号，各管一件事。文档里出现 `v2.2` 不一定过时——它多半指**治理规范**版本（没变）。

| 维度 | 版本 | 管什么 | 正本位置 | 状态 |
|---|---|---|---|---|
| 治理规范 governance-spec | `v2.2` | 宪章语义:七原则、四维状态、权威顺序、纠偏 C1-C3 | `core/01-governance-charter-v2.md` | APPROVED |
| 工程接线 engineering-wiring | `v2.2.1` | runtime 最小加载层、校验器、路径/权限接线、命名统一 | `runtime/` + `tools/validate_*` | 已并入 main |
| 发布打包 release-package | `v2.2.3` | 英文分层可复用包(framework/ + instance-example/ + documents/) | `tools/build_v2_2_3_release.py` | APPROVED |

三者独立推进，不必把 80 页规范文档里的所有 `v2.2` 强改成 `v2.2.3`。

> v2.2.2 是英文分层包的首个构建；外部评审发现 6 处待修（无效 YAML、AGENTS.md 断链脚本引用、入口文档仍写中文目录、framework/README 身份、版本表达、发布层验证缺失）→ **v2.2.3 已逐条修补**，v2.2.2 已被取代。
