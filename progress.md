# 项目进度总览

> 最后更新: 2026-06-16

---

## 已完成任务

### 近期完成

- [x] **法术视觉反馈** — 弹道体 Shader 脉冲发光 + GPUParticles3D 拖尾 + 命中爆发粒子
- [x] **Beehave AI 行为树驱动** — TownNpc `_ready` 设置 MANUAL 模式 + `_physics_process` 注入 delta 并 tick；集成测试验证树运行
- [x] **Playable Loop 基础** — Main 场景安全生成、NPC 显式交互、玩家击败事件、弹道冷却安全
- [x] **小镇战斗反馈** — 小镇通道路径标记 + SealEncounter 战斗反馈信号
- [x] **主线完成反馈** — 任务完成信号、CompletionFeedback UI、主线流程测试
- [x] **小镇 NPC AI** — TownNpc 可复用脚本、6 个 Beehave action/condition 节点、TownNpc.tscn、小镇 6 个 NPC 实例

### 之前完成

- 长剑飞行、封印遭遇战、法术系统（施法/冷却）、任务状态机、NPC 对话、舒适度模式、Desktop/XR 玩家控制器、场景 LOD 组、地形 Ground Plane、水面预置体、模型预置体与碰撞体、小镇模型展示、小镇布局重规划

---

## 未完成任务

### 1. VR 手动验收清单（vr-demo-acceptance.md）

**主线流程（15 项未验证，需 VR 头显）：**
- [ ] 主菜单打开
- [ ] Desktop Simulation 模式基本流程
- [ ] VR 模式头显验证
- [ ] 默认舒适模式
- [ ] 沉浸模式可选
- [ ] 玩家进入小镇
- [ ] 客栈 NPC 推动任务到酒馆
- [ ] 酒馆 NPC 推动任务到山谷
- [ ] 试炼触发器推动任务到封印
- [ ] 灵光弹削弱封印
- [ ] 破封印完成封印
- [ ] 飞剑可拾取
- [ ] 仅拾取后解锁飞行模式
- [ ] 玩家可飞回小镇
- [ ] 返回触发器完成任务
- [ ] 完成反馈 UI 出现并播放音效

**VR 舒适度（5 项未验证，需 VR 头显）：**
- [ ] 舒适模式 snap turn 生效
- [ ] 舒适模式 teleport/comfort 移动
- [ ] 舒适模式飞行速度限制
- [ ] 飞行渐晕效果
- [ ] 沉浸模式平滑移动/转向

**场景质量（6 项未验证，需 VR 头显）：**
- [ ] 客栈/酒馆可进入
- [ ] 小镇地面视角显大
- [ ] 小镇飞行视角显大
- [ ] 山谷路线可见远方景色
- [ ] 飞行路线框出小镇和山景
- [ ] 一次完整游玩无卡死碰撞

**环境说明：** 当前 headless 环境无法完成；Desktop Simulation 可用于逻辑验证，但无法替代 VR 验收。

### 2. PCVR Export 不可用

- [ ] `godot --export-release "PCVR Demo"` 失败
- **原因**：缺少 Godot 4.6.2 Windows 导出模板（`windows_debug_x86_64.exe` / `windows_release_x86_64.exe`）
- **解决**：在 Windows 机器或含模板的环境执行导出

### 3. 音频资源缺失

- `assets/audio/` 仅含 `.gitkeep`，无任何音频文件
- 场景中 `AudioStreamPlayer3D` 节点的 `stream` 全部为 null（水流、环境声、NPC 语音、完成反馈音效）
- **影响**：运行时有警告，但无功能阻塞

### 4. 遗留测试问题

- `test_model_prefabs.gd` 和 `test_model_prefab_colliders.gd` 在导入 .glb 前有模型引用警告（不影响测试通过）
- `tests/test_xr_player.gd` 中 flight provider 的 `last_flying` 存在已知的时序断言（`assert_true(not ...last_flying)`）
- 以上均为非阻塞性问题，测试套件 843+ 断言全绿

---

## 已知技术债务

| 项目 | 说明 | 优先级 |
|------|------|--------|
| 场景模型 .glb 未全部导入 | 部分测试使用 `ResourceLoader.exists()` 跳过，需运行 `--import` | 低 |
| Godot XR Tools 不可在 headless 测试 | 插件安装后需 `--xr-mode off` 启动 | 低 |
| Beehave debugger headless 噪音 | `Capture not registered: 'beehave'` 在清理阶段出现，不影响功能 | 低 |
| 弹道体 HitEffect.tscn Curve 格式 | `_data` 中 mode 字段使用 float 而非 int，引擎报 warning 但不崩溃 | 低 |
