# 可玩试玩版验证记录（2026-10-08）

本次交付针对默认的紧凑试玩路线 `PlayableJourney.tscn`。原大地图和美术文件保留，不能将下面的结果当作整套原项目或 VR 真机验收。

## 已验证

环境：Linux、Godot 4.6.3 stable、`--headless --xr-mode off`，没有图形桌面/头显。源码基于上游提交 `8738a674fd4772f6eab625dd2f38a58b14ba05da`，经 GitHub 连接器读取；环境代理不可达，Git clone / Git LFS 下载未成功。

- 菜单启动、试玩场景启动、`--check-only --quit`：退出 0，无脚本错误。
- 玩法回归 `test_runner.gd -- --suite=gameplay`：**280 assertions passed**。显式选择不依赖原地图的测试；默认完整测试列表未移除。
- `test_playable_integration.gd`：**41 assertions passed**。实例化真实场景并驱动移动输入，覆盖走到两个 NPC、显示对话、通过山谷触发器、提前拾剑/破封拒绝、护符防御、移动弹道击败两个敌人、封印只受一次命中、拾剑、升降、返乡、完成结算、回菜单、读取已完成存档、暂停、死亡和检查点重试。
- `test_xr_integration.gd`：XR 场景可实例化；控制器交互/暂停信号和 PlayerBody 受伤转发正确。
- `tools/package_playable.py` 生成全新目录后重新导入，在不含 LFS 美术和 Terrain3D 的目录内通过上述玩法、主线与 XR 检查。
- `Playable Linux` 数据包（PCK）成功导出；离开源码目录使用 `--main-pack` 启动，并对数据包再次跑通 41 项主线集成检查。
- `git diff --check`、Python 打包脚本语法检查通过。

导入和数据包导出阶段有当前 sandbox 禁止编辑器监听 TCP 的 `_sock == -1` / `ERR_CANT_CREATE` 消息；命令退出 0，运行时检查无这些消息。

## 未通过或未验证

- **原完整测试集未通过。** 同一份缺失二进制美术/地形依赖的上游快照为 81 failures / 879 assertions；本次早期完整测试为 81 failures / 898 assertions。错误包括缺失 GLB/概念图/Terrain3D 类型、旧 Town 预制体断言、TownNpc 测试中的 typed Array 赋值。不能宣称全仓测试绿灯。
- **Windows/Linux 独立可执行文件未在本环境导出**：没有对应导出模板。已提供试玩导出预设及 PR 工作流；本地验证的交付物是源码和可由 Godot 4.6.3 运行的 PCK。
- 没有 GPU/桌面截图检查，没有 HMD。立体显示、头显 HUD 易读性、真实手柄映射、帧率、舒适性和全部 OpenXR 平台需按真机清单检查。
- 本次采用简洁程序化美术和合成提示音；原高精模型地图不属于默认试玩流程。

## 真机补充验收

1. 在 Windows/Linux Godot 4.6.3 中键鼠完整游玩，确认中文字体、1280×720 菜单布局、目标指引、施法命中与声音。
2. 用实际头显跑舒适/沉浸两种模式，检查左右手按键、瞬移、转向、御剑开关/升降、渐晕和高度限制。
3. 检查 VR 暂停/死亡/完成提示，右 B 继续，左 X 重试，左 Y 返回电脑菜单。
4. 使用对应导出模板构建 EXE/Linux 程序，并在未安装 Godot 的机器上启动。

## 交付状态

源码、PCK 和补丁已在工作区生成，GitHub 改动通过独立分支和配套草稿 PR 审查。补丁基于上述上游提交，可在完整仓库中运行 `git apply --check Jianxian-playable.patch` 后再 `git apply Jianxian-playable.patch`。
