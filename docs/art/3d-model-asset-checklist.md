# 3D 模型资源 Checklist

本文按当前设计规格、实现计划和现有灰盒场景整理第一阶段需要制作或替换的 3D 模型资源。资源尺寸、枢轴、网格对齐和 VR 通行要求以 [`3d-grid-size-standard.md`](3d-grid-size-standard.md) 为准。

## 使用约定

- 勾选状态：`[ ]` 未开始，`[~]` 制作中，`[x]` 已导入并在场景中验证。
- 源文件建议放在 `assets/models/<category>/`，例如 `.blend` 与导出的 `.glb` 同目录。
- 概念图和参考图放在 `docs/concept-art/`，不要混入 `assets/models/`。
- 每个可交互资源都要拆分视觉模型、碰撞体和 `Area3D` 交互范围。

## 1. 小镇建筑与街区

### 核心建筑

- [ ] `assets/models/town/inn_*.glb` — 可进入客栈建筑 1 套；需要支持掌柜 NPC 交互空间。
- [ ] `assets/models/town/tavern_*.glb` — 可进入酒馆建筑 1 套；需要支持酒馆老板/说书人 NPC 交互空间。
- [ ] `assets/models/town/building_shell_core_*.glb` — 核心建筑壳体 6 个；用于可玩区错落屋顶和街区体量。
- [ ] `assets/models/town/building_shell_distant_*.glb` — 远景建筑壳体 12 个；用于不可进入街巷和飞行视角下的小镇规模感。

### 建筑模块

- [ ] `assets/models/town/wall_2x3m_*.glb` — 2 m × 3 m 标准墙段。
- [ ] `assets/models/town/wall_1x3m_*.glb` — 1 m 半墙段，用于转角和补缝。
- [ ] `assets/models/town/roof_*.glb` — 中式层叠屋顶模块，高度 1–1.5 m，檐口外挑 0.5 m。
- [ ] `assets/models/town/door_frame_*.glb` — 门框/门洞模块，核心入口不小于 1.5 m × 2.4 m。
- [ ] `assets/models/town/window_*.glb` — 窗户模块。
- [ ] `assets/models/town/courtyard_*.glb` — 庭院围墙、门槛、地面组合模块。

### 街区与市场

- [ ] `assets/models/town/market_stall_2x2m_*.glb` — 市集摊位/棚屋，推荐 2 m × 2 m × 2.5 m。
- [ ] `assets/models/town/lantern_*.glb` — 灯笼模型，可用于街道、飞行路线和酒馆氛围。
- [ ] `assets/models/town/shop_sign_*.glb` — 招牌/牌匾模型。
- [ ] `assets/models/town/street_prop_*.glb` — 木箱、酒坛、桌凳、货架等街景道具。
- [ ] `assets/models/town/main_street_4x4m_*.glb` — 主街石板路模块，推荐 4 m × 4 m。
- [ ] `assets/models/town/side_street_2x4m_*.glb` — 小巷/支路模块，推荐 2 m × 4 m。
- [ ] `assets/models/town/stone_step_*.glb` — 城镇台阶模块。
- [ ] `assets/models/town/gate_paifang_*.glb` — 镇门/牌坊 1 套，作为小镇边界和山路入口。
- [ ] `assets/models/town/practice_yard_*.glb` — 练剑空地地面/平台。
- [ ] `assets/models/town/sword_rack_*.glb` — 练剑架、木桩或训练靶等练剑空地道具。

### 小镇远景

- [ ] `assets/models/town/distant_rooftop_layer_*.glb` — 多层屋顶远景。
- [ ] `assets/models/town/distant_street_block_*.glb` — 不可进入街巷剪影。
- [ ] `assets/models/town/field_ridge_*.glb` — 田埂/郊外地形远景。
- [ ] `assets/models/town/tree_cluster_*.glb` — 低模树木或树丛。

## 2. 山路、试炼与远景

### 山路可玩区

- [ ] `assets/models/mountain/path_segment_*.glb` — 山路主路径模块；主任务路线建议保持 3 m 宽。
- [ ] `assets/models/mountain/stone_step_*.glb` — 山路石阶，参考 0.3 m 高 × 0.5 m 深。
- [ ] `assets/models/mountain/cliff_near_*.glb` — 近景崖壁/岩石模块。
- [ ] `assets/models/mountain/platform_3x3m_*.glb` — 3 m × 3 m 停留平台。
- [ ] `assets/models/mountain/platform_4x4m_*.glb` — 4 m × 4 m 试炼或观景平台。

### 试炼区域

- [ ] `assets/models/mountain/trial_platform_*.glb` — 封印战斗区平台 1 套，支持站立施法。
- [ ] `assets/models/mountain/sword_altar_*.glb` — 飞剑祭台 1 套；飞剑从祭台或封印处出现。
- [ ] `assets/models/mountain/seal_pillar_*.glb` — 封印柱/任务石，1–2 m 大型道具。
- [ ] `assets/models/mountain/trial_stone_prop_*.glb` — 试炼石灯、碎石、符文石等环境道具。

### 水体与山川远景

- [ ] `assets/models/mountain/waterfall_vista_*.glb` — 瀑布地标 1 套。
- [ ] `assets/models/mountain/stream_*.glb` — 溪流或水面模块。
- [ ] `assets/models/mountain/distant_mountain_4m_*.glb` — 4 m 倍数远山/岩块模块。
- [ ] `assets/models/mountain/distant_mountain_8m_*.glb` — 8 m 倍数远山剪影。
- [ ] `assets/models/mountain/distant_mountain_16m_*.glb` — 16 m 倍数大远山剪影。
- [ ] `assets/models/mountain/plank_road_silhouette_*.glb` — 不可达栈道剪影。
- [ ] `assets/models/mountain/cloud_fog_band_*.glb` — 云雾带或雾气面片。

## 3. NPC 模型

第一阶段设计范围为 3–5 个 NPC。可以先用同一基础体型加服装/颜色变体实现。

- [ ] `assets/models/npc/innkeeper_*.glb` — 客栈掌柜 1 个。
- [ ] `assets/models/npc/tavern_keeper_*.glb` — 酒馆老板或说书人 1 个。
- [ ] `assets/models/npc/trial_spirit_*.glb` — 山谷残影/守阵灵 1 个。
- [ ] `assets/models/npc/townsperson_*.glb` — 镇民或氛围 NPC 1 个，可选但在设计范围内。
- [ ] `assets/models/npc/sword_practice_youth_*.glb` — 练剑少年或操作提示 NPC 1 个，可选。
- [ ] `assets/models/npc/npc_base_body_*.glb` — NPC 通用低模身体基础件，可供上述角色复用。

NPC 资源检查：

- [ ] 占位直径约 0.75–1 m。
- [ ] 视觉体与 1.5–2 m 交互触发区分离。
- [ ] 支持待机姿态；后续可扩展待机动画。

## 4. 封印、小妖与交互物

- [ ] `assets/models/interaction/seal_core_*.glb` — 封印核心/魔法节点 1 个；替换 `SealVisual` 球体占位。
- [ ] `assets/models/interaction/seal_weakened_*.glb` — 封印削弱状态模型或可切换部件。
- [ ] `assets/models/interaction/seal_cleansed_*.glb` — 封印净化状态模型或可切换部件。
- [ ] `assets/models/interaction/demon_minor_*.glb` — 小妖/魔影 1 个；替换 `DemonVisual` 胶囊占位。
- [ ] `assets/models/interaction/task_stone_*.glb` — 任务石/符文石，可与封印柱组合使用。
- [ ] `assets/models/interaction/rune_ring_*.glb` — 法阵环、符文环或封印底座。

## 5. 法术与特效辅助模型

当前法术 ID：`spirit_bolt`、`guard_charm`、`seal_break`。

- [ ] `assets/models/spells/spirit_bolt_projectile_*.glb` — 灵光弹投射物；替换当前球体占位。
- [ ] `assets/models/spells/spirit_bolt_trail_*.glb` — 灵光弹轨迹网格或面片。
- [ ] `assets/models/spells/guard_charm_glyph_*.glb` — 护身诀符纹、护盾环或法印。
- [ ] `assets/models/spells/seal_break_glyph_*.glb` — 破封印法印、符纸、光环或光束辅助网格。
- [ ] `assets/models/spells/hand_glow_focus_*.glb` — 手部聚气/施法聚焦辅助模型。
- [ ] `assets/models/spells/hit_feedback_*.glb` — 命中反馈火花、碎片或符文片。

## 6. 飞剑与御剑飞行

- [ ] `assets/models/items/flying_sword_1_2m_*.glb` — 飞剑主体 1 个，长度 1.2–1.5 m。
- [ ] `assets/models/items/flying_sword_hover_ring_*.glb` — 飞剑悬浮光环或底部气流辅助件。
- [ ] `assets/models/items/flying_sword_reveal_*.glb` — 出现/出鞘展示用部件，可选。
- [ ] `assets/models/items/flying_sword_flight_mount_*.glb` — 御剑飞行视角下的脚下/前方可见部件，避免遮挡视线。

## 7. 飞行路线与空中观景

- [ ] `assets/models/flight/route_ring_*.glb` — 飞行路线环形标记。
- [ ] `assets/models/flight/route_lantern_*.glb` — 空中灯笼标记，可复用小镇灯笼风格。
- [ ] `assets/models/flight/cloud_wisp_marker_*.glb` — 云缕/雾气路线标记。
- [ ] `assets/models/flight/town_aerial_vista_*.glb` — 御剑返回时可见的小镇整体远景组合。
- [ ] `assets/models/flight/mountain_aerial_vista_*.glb` — 御剑路线中的山川远景组合。

## 8. 通用道具库

### 小型道具：0.25–0.5 m

- [ ] `assets/models/props/cup_*.glb` — 杯盏。
- [ ] `assets/models/props/jade_pendant_*.glb` — 玉佩。
- [ ] `assets/models/props/talisman_*.glb` — 符纸/符箓。
- [ ] `assets/models/props/small_bottle_*.glb` — 小瓶或药瓶。

### 中型道具：0.5–1 m

- [ ] `assets/models/props/wooden_box_*.glb` — 木箱。
- [ ] `assets/models/props/incense_burner_*.glb` — 香炉。
- [ ] `assets/models/props/small_stone_tablet_*.glb` — 小石碑。
- [ ] `assets/models/props/barrel_or_jar_*.glb` — 酒坛/木桶。

### 大型道具：1–2 m

- [ ] `assets/models/props/signboard_large_*.glb` — 大型牌匾。
- [ ] `assets/models/props/task_stone_large_*.glb` — 大型任务石。
- [ ] `assets/models/props/seal_column_*.glb` — 封印柱。
- [ ] `assets/models/props/practice_dummy_*.glb` — 练剑木桩或训练靶。

## 9. 导入与场景替换检查

每个模型完成后，导入 Godot 前后检查：

- [ ] `.blend` 或源文件已保存在 `assets/models/<category>/`。
- [ ] `.glb` 导出文件已保存在同一分类目录。
- [ ] Godot 导入后节点 `scale` 为 `(1, 1, 1)`。
- [ ] 枢轴符合用途：地面模块底面中心，挂件安装面中心，交互物视觉/握持中心。
- [ ] 碰撞体只覆盖可达和需要阻挡的区域。
- [ ] 可交互对象已经拆分视觉模型、碰撞体和 `Area3D`。
- [ ] 主路径宽度不小于 3 m，最低可通行宽度不小于 1.5 m。
- [ ] 模型替换灰盒后不破坏任务触发、NPC 交互、封印战斗和飞剑拾取流程。
