# 可玩版本实施计划

## Goal
把现有剑仙原型完善为有入口、引导、战斗反馈、可恢复进度及完整结束流程的中文游戏试玩版，支持键鼠并补齐 PCVR 输入。

## Scope
沿用 QuestState、EventBus、法术、生命和御剑系统。保留原有大地图与资源；增加不依赖 Git LFS 美术和 Terrain3D 的紧凑试炼场景，保证新环境能直接试玩。VR 真机舒适性仍需头显验收。

## Affected files
project.godot、scripts/autoload、scripts/core/SaveState.gd、scripts/player、scripts/npc/NpcDialogue.gd、scripts/items/FlyingSword.gd、scripts/interaction/SealEncounter.gd、scripts/ui、scenes/menu、scenes/main、新增 playable world 脚本、tests、README 与运行说明。

## Steps
- [x] 保存可获取的原仓库源码快照，记录缺失的二进制/LFS 资源。
- [x] 默认入口改为主菜单，添加新游戏/继续、模式选择、暂停/重试/返回菜单。
- [x] 保存并校验任务检查点，恢复场景、飞剑和舒适设置；处理损坏存档。
- [x] 显示 NPC 对话、目标位置、生命、冷却、护符和战斗反馈。
- [x] 修复提前拾剑/破封、重力累积、下降、飞行开关及 XR 按键/生命事件。
- [x] 建立可走通的小镇至试炼路线并复用现有玩法脚本。
- [x] 运行原测试、专项回归及真实场景集成测试，修复失败并记录无法验证项。
- [x] 提供可审查补丁/分支和准确的启动、控制、导出说明。

## Verification criteria
Godot 4.6.3 headless import、原 test_runner（如原美术依赖缺失需明确记录）、check-only；新增测试覆盖非法顺序、存档恢复、死亡重试和完整任务链。可玩场景启动无脚本错误。若没有图形/VR 设备，不把 headless 通过表述为真机验收。

## Environment evidence
普通 Git clone 在当前 sandbox 内无法连接 proxy:8080；两次网络权限调用未返回并被用户中断。后续仅使用可用的 GitHub 连接器，禁止再次等待此下载通道。源码基线：8738a674fd4772f6eab625dd2f38a58b14ba05da。

## Results and deviations
- 已保存源码快照，无法取得 Git LFS 美术与 Terrain3D 二进制；保留原场景，默认启动新增紧凑试玩关卡。
- 玩法专项 280 断言、整条真实场景流程 41 断言及 XR 桥接检查通过；新源码目录与 PCK 也分别验证。
- 原完整测试仍有 81 项失败（基线同样 81），详见 docs/testing/playable-release.md。不会把环境缺失和旧地图问题伪装为通过。
- 尚无头显/图形验收、独立可执行文件导出模板。交付源码和 PCK，并提供可审查补丁、构建工作流；VR 真机验收仍为后续事项。

- 本地补丁已通过 git apply --check；GitHub 写入权限重试后恢复，使用独立分支和配套草稿 PR 交付。
