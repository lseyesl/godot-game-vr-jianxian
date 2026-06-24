# 3D 模型资产盘点报告

> 生成时间: 2026-06-24
> 依据: `docs/art/3d-model-asset-checklist.md` + `assets/models/` 实际文件

---

## ✅ 已存在（有 .glb）

| 分类 | 模型 | 文件 |
|------|------|------|
| 建筑 | 客栈 | `Inn/Inn.glb` |
| 建筑 | 酒馆 | `Tavern/Tavern.glb` |
| 建筑 | 牌坊 | `Gate/Gate.glb` |
| 建筑 | 屋顶模块 ×10 | `Roof/Roof01-10.glb` |
| 建筑 | 墙体 2×3m | `Wall/Wall_2x3.glb` |
| 建筑 | 墙体 1×3m | `Wall/Wall_1x3.glb` |
| 街区 | 市集摊位 | `Market_Stall/Market_Stall.glb` |
| 街区 | 灯笼 ×10 | `Props/灯笼1-10.glb` |
| 街区 | 坛 ×4 | `Props/坛1-4.glb` |
| 街区 | 架子 ×4 | `Props/架1-4.glb` |
| 街区 | 箱子 ×3 | `Props/箱1-3.glb` |
| 街区 | 袋子 ×2 | `Props/袋1-2.glb` |
| 街区 | 小山石、石灯笼 | `Props/小山石.glb`、`Props/石灯笼.glb` |
| NPC | 客栈掌柜 | `Innkeeper/Innkeeper.glb` |
| 飞剑 | 飞剑主体 | `FlyingSword/FlyingSword.glb` |
| 植被 | 23 种植物 | `Vegetation/*.glb`（苍松、车前草、垂柳、淡竹、杜鹃花、狗尾草、荷花、红梅、蕨菜、兰草、芦苇、楠树、山樱、石菖蒲、树根、绣球、萱草、野草、野菊、迎春花、竹1、竹2、紫草） |

---

## ❌ 仍缺失（按 checklist 分类）

### 1. 小镇建筑与街区

| 缺失模型 | 用途 | 优先级 |
|----------|------|--------|
| `building_shell_core` ×6 | 核心建筑壳体，用于可玩区错落屋顶 | ★★★ |
| `building_shell_distant` ×12 | 远景建筑壳体，飞行视角下的小镇规模感 | ★★★ |
| `door_frame_*` | 门框/门洞模块（核心入口 ≥ 1.5×2.4m） | ★★ |
| `window_*` | 窗户模块 | ★★ |
| `courtyard_*` | 庭院围墙、门槛、地面组合 | ★★ |
| `shop_sign_*` | 招牌/牌匾 | ★★ |
| `main_street_4x4m_*` | 主街石板路模块 | ★★★ |
| `side_street_2x4m_*` | 小巷/支路模块 | ★★★ |
| `stone_step_*` | 城镇台阶 | ★★ |
| `practice_yard_*` | 练剑空地地面/平台 | ★★ |
| `sword_rack_*` | 练剑架、木桩、训练靶 | ★★ |
| `distant_rooftop_layer_*` | 多层屋顶远景 | ★★ |
| `distant_street_block_*` | 不可进入街巷剪影 | ★★ |
| `field_ridge_*` | 田埂/郊外地形远景 | ★ |
| `tree_cluster_*` | 低模树木/树丛（已有单棵植被，缺组合） | ★ |

### 2. 山路、试炼与远景

| 缺失模型 | 用途 | 优先级 |
|----------|------|--------|
| `path_segment_*` | 山路主路径模块 | ★★★ |
| `stone_step_*`（山路） | 山路石阶 | ★★★ |
| `cliff_near_*` | 近景崖壁/岩石 | ★★★ |
| `platform_3x3m_*` | 3m 停留平台 | ★★★ |
| `platform_4x4m_*` | 4m 试炼/观景平台 | ★★★ |
| `trial_platform_*` | 封印战斗区平台 | ★★★ |
| `sword_altar_*` | 飞剑祭台 | ★★★ |
| `seal_pillar_*` | 封印柱/任务石 | ★★★ |
| `trial_stone_prop_*` | 试炼石灯、碎石、符文石 | ★★ |
| `waterfall_vista_*` | 瀑布地标 | ★★ |
| `stream_*` | 溪流/水面模块 | ★★ |
| `distant_mountain_4m_*` | 4m 远山/岩块 | ★★ |
| `distant_mountain_8m_*` | 8m 远山剪影 | ★★ |
| `distant_mountain_16m_*` | 16m 大远山剪影 | ★★ |
| `plank_road_silhouette_*` | 不可达栈道剪影 | ★ |
| `cloud_fog_band_*` | 云雾带/雾气面片 | ★★ |

### 3. NPC 模型

| 缺失模型 | 用途 | 优先级 |
|----------|------|--------|
| `tavern_keeper_*` | 酒馆老板/说书人 | ★★★ |
| `trial_spirit_*` | 山谷残影/守阵灵 | ★★★ |
| `townsperson_*` | 镇民/氛围 NPC | ★★ |
| `sword_practice_youth_*` | 练剑少年 | ★ |
| `npc_base_body_*` | NPC 通用低模身体基底 | ★★ |

### 4. 封印、小妖与交互物

| 缺失模型 | 用途 | 优先级 |
|----------|------|--------|
| `seal_core_*` | 封印核心/魔法节点 | ★★★ |
| `seal_weakened_*` | 封印削弱状态 | ★★ |
| `seal_cleansed_*` | 封印净化状态 | ★★ |
| `demon_minor_*` | 小妖/魔影 | ★★★ |
| `task_stone_*` | 任务石/符文石 | ★★ |
| `rune_ring_*` | 法阵环/封印底座 | ★★ |

### 5. 法术与特效辅助模型

| 缺失模型 | 用途 | 优先级 |
|----------|------|--------|
| `spirit_bolt_projectile_*` | 灵光弹投射物 | ★★★ |
| `spirit_bolt_trail_*` | 灵光弹轨迹网格 | ★★ |
| `guard_charm_glyph_*` | 护身诀符纹/护盾环 | ★★ |
| `seal_break_glyph_*` | 破封印法印/符纸 | ★★★ |
| `hand_glow_focus_*` | 手部聚气辅助模型 | ★★ |
| `hit_feedback_*` | 命中反馈碎片/符文片 | ★★ |

### 6. 飞剑与御剑飞行

| 缺失模型 | 用途 | 优先级 |
|----------|------|--------|
| `flying_sword_hover_ring_*` | 飞剑悬浮光环 | ★★ |
| `flying_sword_reveal_*` | 出鞘展示部件 | ★ |
| `flying_sword_flight_mount_*` | 御剑飞行视角可见部件 | ★★ |

### 7. 飞行路线与空中观景

| 缺失模型 | 用途 | 优先级 |
|----------|------|--------|
| `route_ring_*` | 飞行路线环形标记 | ★★ |
| `route_lantern_*` | 空中灯笼标记 | ★★ |
| `cloud_wisp_marker_*` | 云缕/雾气路线标记 | ★★ |
| `town_aerial_vista_*` | 小镇整体远景组合 | ★★ |
| `mountain_aerial_vista_*` | 山川远景组合 | ★★ |

### 8. 通用道具库

| 缺失模型 | 用途 | 优先级 | 备注 |
|----------|------|--------|------|
| `cup_*` | 杯盏 | ★ | |
| `jade_pendant_*` | 玉佩 | ★ | |
| `talisman_*` | 符纸/符箓 | ★ | |
| `small_bottle_*` | 小瓶/药瓶 | ★ | |
| `wooden_box_*` | 木箱 | ★ | 已有箱1-3可复用 |
| `incense_burner_*` | 香炉 | ★ | |
| `small_stone_tablet_*` | 小石碑 | ★ | |
| `signboard_large_*` | 大型牌匾 | ★★ | |
| `task_stone_large_*` | 大型任务石 | ★★ | |
| `seal_column_*` | 封印柱 | ★★ | |
| `practice_dummy_*` | 练剑木桩/训练靶 | ★★ | |

---

## 汇总

| 状态 | 数量 |
|------|------|
| ✅ 已有 .glb 模型 | ~60 个文件（含植被、屋顶、灯笼等模块） |
| ❌ Checklist 标记缺失 | **约 65–70 个模型项未制作** |

## 核心玩法最缺（★★★ 优先级）

直接影响主线流程的模型，建议优先制作：

1. **NPC**: 酒馆老板 (`tavern_keeper`)、守阵灵 (`trial_spirit`)
2. **交互物**: 封印核心 (`seal_core`)、小妖 (`demon_minor`)、封印柱 (`seal_pillar`)、飞剑祭台 (`sword_altar`)
3. **山路模块**: 路径段 (`path_segment`)、石阶 (`stone_step`)、崖壁 (`cliff_near`)、平台 (`platform_3x3m` / `platform_4x4m`)、试炼平台 (`trial_platform`)
4. **小镇结构**: 核心建筑壳体 (`building_shell_core`)、远景建筑 (`building_shell_distant`)、主街/支路模块
5. **法术**: 灵光弹投射物 (`spirit_bolt_projectile`)、破封印法印 (`seal_break_glyph`)

> **注意**: 现阶段大量场景使用灰盒（Godot 基础几何体），模型替换是可选的视觉升级。以上优先级以核心玩法流程完整性为标准。
