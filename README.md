# 青岚 · 剑仙试炼 / VR Xianxia

Godot 4.6.3 中文单人试玩版。问询客栈与酒馆，沿山道进入试炼，击败两只山魈、净化封印，取回飞剑并飞上小镇归剑台。键鼠模式无需头显；PCVR 使用 OpenXR。

## 直接运行

用 **Godot 4.6.3 标准版**打开 `project.godot`，按 F5 运行项目。在主菜单选择「键鼠」，点击「开始新的试炼」。也可以执行：

```bash
godot --path . --xr-mode off
```

默认入口为 `scenes/menu/MainMenu.tscn`，启动 `scenes/main/PlayableJourney.tscn`。该紧凑关卡使用程序化场景、内置几何体和合成提示音，不依赖大型模型、Git LFS 美术或 Terrain3D。无需联网游玩。约 5–10 分钟，保留原任务状态机与法术/飞剑系统。

原大地图 `scenes/main/Main.tscn`、Town 与 MountainTrial、美术预制体仍保留。编辑原地图需安装/还原 Terrain3D 和 Git LFS 资源；它们不属于本次已验证的试玩路线。

## 键鼠操作

| 操作 | 按键 |
|---|---|
| 移动 / 转向 | WASD / 鼠标 |
| 交谈 | 靠近 NPC 后 F |
| 灵光弹 | 鼠标左键，冷却 1 秒 |
| 护身诀 | Q，持续 3 秒，冷却 4 秒 |
| 破封诀 | E，冷却 2 秒；也能攻击山魈 |
| 御剑开关 | 取剑后 V；拾剑时自动启用 |
| 飞行升降 | 空格 / Ctrl |
| 暂停 | Esc |

跟随青色目标光环与 HUD 距离提示。先击败两只守卫再净化封印；取剑后飞上镇中高台完成试炼。护身诀生效期间免疫伤害。主菜单提供新游戏/继续；暂停、死亡和完成界面可以重试或返回菜单。

## 存档

每次任务阶段推进时自动保存到 Godot `user://jianxian_checkpoint.json`。继续/重试会回到该阶段的安全出生点，恢复完整气血并重建未完成的遭遇战。已完成的封印与飞剑解锁状态由任务阶段恢复；损坏或未知版本存档不会被载入。新游戏会覆盖旧进度。

舒适模式提供 6 m/s 飞行上限、45 m 高度上限和渐晕；沉浸模式为 9 m/s、60 m，无渐晕。舒适设置随存档恢复。

## PCVR

先连接头显，启动 SteamVR 或其他 OpenXR 运行时：

```bash
godot --path . --xr-mode on
```

在电脑主菜单中选择 PCVR。未检测到 OpenXR 时显示原因，允许改选键鼠。项目内带有 XR Tools 源码，试玩所需瞬移图标使用本地 SVG。

| 操作 | 控制器 |
|---|---|
| 灵光弹 / 破封诀 | 右扳机 / 右握键 |
| 交谈 | 右 A |
| 护身诀 | 左握键 |
| 御剑开关 | 取剑后左 Y |
| 飞行方向 / 升降 | 左摇杆，左手控制器朝向决定俯仰 |
| 暂停 / 继续 | 右 B |
| 暂停或结算时重试 / 返回电脑主菜单 | 左 X / 左 Y |
| 舒适模式移动 | 左摇杆瞬移，右摇杆分段转向 |
| 沉浸模式移动 | 右摇杆平移与转向（XR Tools 默认映射） |

任务、对话、生命与暂停提示显示在头显内。**VR 场景加载、输入桥接和受伤转发经过无头测试；头显显示、实际控制器映射、帧率与舒适性未做真机验收。**

## 测试

```bash
godot --headless --xr-mode off --path . --editor --import --quit
# 不依赖大地图美术的玩法回归
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd -- --suite=gameplay
# 实际场景中的移动、交互、弹道、御剑、完成、读档与死亡重试
godot --headless --xr-mode off --fixed-fps 60 --path . --script res://tests/test_playable_integration.gd
# XR 场景及控制器信号桥接，无需头显
godot --headless --xr-mode off --path . --script res://tests/test_xr_integration.gd
# 默认仍保留完整原测试集；需要原模型和地形资源
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

验证结果与限制见 [试玩验收记录](docs/testing/playable-release.md)。

## 导出

可用 `python3 tools/package_playable.py /path/to/new/folder` 生成不含原大地图/LFS 资源的独立源码目录。PR 上的 `Playable demo` 工作流会在该目录中测试并尝试构建 Windows/Linux 可执行文件；原大地图的完整测试仍由原构建流程保留。

安装对应 Godot 4.6.3 导出模板后：

```bash
mkdir -p builds/playable
godot --headless --xr-mode off --path . --export-release "Playable Windows" builds/playable/Jianxian.exe
godot --headless --xr-mode off --path . --export-release "Playable Linux" builds/playable/Jianxian.x86_64
```

试玩预设只导出菜单、试玩与 XR 场景依赖，保留原 `PCVR Demo` 预设用于大地图开发。未安装模板时可以导出数据包，用相同版本 Godot 运行：

```bash
godot --headless --xr-mode off --path . --export-pack "Playable Linux" Jianxian.pck
godot --main-pack Jianxian.pck --xr-mode off
```

## 原项目资料

- [原设计](docs/superpowers/specs/2026-05-19-vr-xianxia-demo-design.md)
- [3D 尺寸规范](docs/art/3d-grid-size-standard.md)
- [VR 真机验收清单](docs/testing/vr-demo-acceptance.md)
- [本次实施计划](docs/superpowers/plans/2026-10-08-playable-release.md)
