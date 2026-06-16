# 地形与世界构建 — 分阶段实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan phase-by-phase. Phases use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将当前 120×120 纯平地面的灰盒项目，建成具有地形起伏、区域划分、路径连接和视觉层次的可玩世界。

**前置条件：** Town.tscn 已有客栈/酒馆/城门/城墙/集市灰盒，MountainTrial.tscn 已有封印/飞剑/小妖/试炼灵骨架，Main.tscn 已实例化两者。

**设计约束：**
- VR 主路径宽度 ≥ 3m，最小通行 ≥ 1.5m，门洞 ≥ 1.5m×2.4m
- 飞行高度上限：舒适模式 45m，沉浸模式 60m
- 石阶：0.3m 高 × 0.5m 深，最大坡度 15°
- 战斗区：封印周围需要 8m+ 半径开放空间（小妖视距 8m）
- 投射物最远飞行 48m（16m/s × 3s）
- 所有新模型资源尺寸遵循 `docs/art/3d-grid-size-standard.md`

---

## 总体布局规划

```
地形高度分层（Z 轴俯视图，Y 为海拔）：

   Z- (北)
   ┌─────────────────────────────────────────┐
   │  远山剪影层 (Y=30~50)                     │
   │  ┌─────────────────────────────────────┐ │
   │  │  山谷试炼区 (Y=20~25)  封印 -48    │ │
   │  │  ┌───────┐                          │ │
   │  │  │战斗平台│                          │ │
   │  │  └───────┘                          │ │
   │  │     ↑ 山路 (Y=10→20)               │ │
   │  │     ┌──────────────────┐            │ │
   │  │     │ 石阶路径 3m宽     │            │ │
   │  │     └──────────────────┘            │ │
   │  │     ↑ 瀑布地标 (Y=15)              │ │
   │  │     ↑ 山脚过渡 (Y=0→10)            │ │
   │  │     ┌──────────────────┐            │ │
   │  └─────│ 缓坡/城郊         │────────────┘ │
   │        └──────────────────┘              │
   │  小镇区 (Y=0)  北门 (0,0,-32)           │
   │  ┌────────────────────────────────────┐  │
   │  │ 客栈  集市  酒馆                    │  │
   │  │ ██ 水车       ██ 衙门   ██ 寺庙      │  │
   │  └────────────────────────────────────┘  │
   │  ←西门             南门→    返回触发区→  │
   └─────────────────────────────────────────┘
   Z+ (南)
```

**世界节点层级（Main.tscn 改造后）：**

```
Main (Node3D)
├── WorldEnvironment + DirectionalLight3D + EnvironmentController (不变)
├── TerrainContainer (Node3D)         ← 新增：所有地形/地面/碰撞的父节点
│   ├── TownGround (StaticBody3D)     ← 小镇区域地面
│   ├── SuburbGround (StaticBody3D)   ← 城郊过渡地面
│   ├── MountainGround (StaticBody3D) ← 山路+山谷地面
│   └── WorldBoundary (StaticBody3D)  ← 世界边界碰撞墙
├── Town (Town.tscn 实例，位置保持不变)
├── MountainTrial (MountainTrial.tscn 实例，位置保持不变)
├── ConnectionCorridor (Node3D)       ← 新增：Town↔Mountain 连接
│   ├── MountainPath (Node3D)         ← 路径段 + 石阶
│   ├── WaterfallVista (Node3D)       ← 瀑布实例（从水预置体实例化）
│   ├── CliffWalls (Node3D)           ← 崖壁模块
│   └── DistantMountains (SceneLodGroup) ← 远山剪影
├── FlightRoute (Node3D)              ← 新增：飞行路线视觉
│   ├── RouteMarkers (SceneLodGroup)
│   ├── AerialLanterns (Node3D)
│   └── AerialVistas (SceneLodGroup)
├── WaterFeatures (Node3D)            ← 新增：世界中的水体实例
│   ├── Canal (RiverStraight 实例)
│   ├── TownLake (Lake 实例)
│   └── MountainStream (RiverBend 实例)
├── TownBuildingShells (Node3D)       ← 新增：替换区域标记的实际建筑
│   ├── WaterwheelBuilding (Node3D)
│   ├── YamenBuilding (Node3D)
│   ├── TempleBuilding (Node3D)
│   ├── DockStructure (Node3D)
│   ├── GranaryBuilding (Node3D)
│   ├── BlacksmithBuilding (Node3D)
│   ├── CoreShell_01~06 (Node3D)
│   └── DistantShells_01~12 (SceneLodGroup)
├── TaskHud + CompletionFeedback (不变)
```

**受影响文件清单：**

| 文件 | 操作 | 说明 |
|------|------|------|
| `scenes/main/Main.tscn` | 修改 | 添加新节点结构 |
| `scripts/main/Main.gd` | 可能修改 | 如需动态加载 |
| `scenes/town/Town.tscn` | 修改 | 移除区域标记灰盒（移到新节点） |
| `scenes/mountain/MountainTrial.tscn` | 修改 | 精简为只保留逻辑节点 |
| `scenes/prefabs/terrain/` | 新建目录 | 地形模块预置体 |
| `scenes/prefabs/buildings/` | 新建目录 | 建筑壳体预置体 |
| `scenes/prefabs/flight/` | 新建目录 | 飞行路线预置体 |
| `docs/art/town-layout.md` | 修改 | 更新新布局 |
| `tests/test_terrain.gd` | 新建 | 地形测试 |
| `tests/test_runner.gd` | 修改 | 注册新测试 |

---

## Phase 1：地形基础设施（Terrain Foundation）

将 120×120 纯平面分割为三个高度区域 + 世界边界。

### Task 1.1：创建地形场景目录和基础预置体

**Files:**
- Create: `scenes/prefabs/terrain/`（目录）
- Create: `scenes/prefabs/terrain/TownGround.tscn`
- Create: `scenes/prefabs/terrain/SuburbGround.tscn`
- Create: `scenes/prefabs/terrain/MountainGround.tscn`
- Create: `scenes/prefabs/terrain/WorldBoundary.tscn`

- [ ] **Step 1: 创建 TownGround.tscn**

```gdscript
# 一个 StaticBody3D，代表小镇区域（Y=0 平地）
# PlaneMesh 约 60×50m，位置在原点为中心
# 分 4 个 MeshInstance3D 子节点，方便后续替换为石板路纹理
# 碰撞体使用 BoxShape3D 覆盖整个区域

# 节点结构:
# TownGround (StaticBody3D)
# ├── Mesh_01 (MeshInstance3D)  - PlaneMesh 30x25, position (-15,0,-12.5)
# ├── Mesh_02 (MeshInstance3D)  - PlaneMesh 30x25, position (15,0,-12.5)
# ├── Mesh_03 (MeshInstance3D)  - PlaneMesh 30x25, position (-15,0,12.5)
# ├── Mesh_04 (MeshInstance3D)  - PlaneMesh 30x25, position (15,0,12.5)
# └── CollisionShape3D - BoxShape3D(60,0.2,50), position(0,-0.1,0)
```

- [ ] **Step 2: 创建 SuburbGround.tscn**

```gdscript
# 城郊过渡区 (Y=0 渐变到 Y=10)
# 从北门 (0,0,-32) 向北延伸约 30m
# 使用多个分段 PlaneMesh 逐步抬高，每段抬升 2m
# 可以用 5 段，每段 6m 深，Y 递增 2m

# 节点结构:
# SuburbGround (StaticBody3D)
# ├── Segment_01 (MeshInstance3D) - PlaneMesh 20x6, at (0,0,-35)  Y=0
# ├── Segment_02 (MeshInstance3D) - PlaneMesh 20x6, at (0,2,-41)  Y=2
# ├── Segment_03 (MeshInstance3D) - PlaneMesh 20x6, at (0,4,-47)  Y=4
# ├── Segment_04 (MeshInstance3D) - PlaneMesh 20x6, at (0,6,-53)  Y=6
# ├── Segment_05 (MeshInstance3D) - PlaneMesh 20x6, at (0,8,-59)  Y=8
# └── CollisionShape3D per segment
```

注意：实际使用中更好的做法是使用 CSG 或直接建模，但对于灰盒阶段，分段平面足以验证可玩性。

- [ ] **Step 3: 创建 MountainGround.tscn**

```gdscript
# 山路+山谷区域 (Y=10 到 Y=25)
# 路径部分：3m 宽连续路面，从 Y=10 到 Y=20~25
# 山谷平台：4×4m 战斗区
# 使用分段 BoxMesh 模拟路径+平台

# 节点结构:
# MountainGround (StaticBody3D)
# ├── PathSegment_01 (MeshInstance3D) - BoxMesh 3x0.2x6 at (0,10,-65)
# ├── PathSegment_02 (MeshInstance3D) - BoxMesh 3x0.2x6 at (0,12,-71)
# ├── PathSegment_03 (MeshInstance3D) - BoxMesh 3x0.2x6 at (0,14,-77)
# ├── PathSegment_04 (MeshInstance3D) - BoxMesh 3x0.2x6 at (0,16,-83)
# ├── PathSegment_05 (MeshInstance3D) - BoxMesh 3x0.2x6 at (0,18,-89)
# ├── ValleyPlatform (MeshInstance3D)  - BoxMesh 12x0.2x12 at (0,20,-95)
# ├── SealPlatform (MeshInstance3D)   - BoxMesh 8x0.2x8 at (0,20,-48)
# │   (注意：MountainTrial 节点在 Main 中位于 Z=-34~-52 范围，
# │    所以 SealPlatform 放在 (0,20,-48) 与现有 SealEncounter 对齐)
# └── 对应 CollisionShape3D 各段
```

- [ ] **Step 4: 创建 WorldBoundary.tscn**

```gdscript
# 在世界边缘的四个方向添加不可见碰撞墙
# 使用透明 MeshInstance3D + StaticBody3D
# 高度延伸到 60m（覆盖飞行高度上限）

# 边缘位置：X=±60, Z=±60

# 节点结构:
# WorldBoundary (StaticBody3D)
# ├── NorthWall - BoxShape3D(120,60,1) at (0,30,-60.5)
# ├── SouthWall - BoxShape3D(120,60,1) at (0,30,60.5)
# ├── WestWall  - BoxShape3D(1,60,120) at (-60.5,30,0)
# └── EastWall  - BoxShape3D(1,60,120) at (60.5,30,0)
#
# 每面墙附带一个 CollisionShape3D
# MeshInstance3D 可以不加（不可见）或加半透明面片
```

- [ ] **Step 5: 修改 Main.tscn**

将 Phase 1 的地形预置体实例化到 Main.tscn 中：
- 移除原有的 `Ground` (StaticBody3D) 节点
- 添加 `TerrainContainer` 节点，实例化 4 个地形预置体
- 保持 Town 和 MountainTrial 子节点不变（它们的坐标已经相对于 Main）

- [ ] **Step 6: 创建基础测试**

```gdscript
# tests/test_terrain.gd
extends RefCounted
class_name TestTerrain

func run(t) -> void:
    # 验证地形预置体可加载
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/TownGround.tscn"), "TownGround should exist")
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/SuburbGround.tscn"), "SuburbGround should exist")
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/MountainGround.tscn"), "MountainGround should exist")
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/WorldBoundary.tscn"), "WorldBoundary should exist")
    
    # 验证 Main.tscn 可加载（不实例化，只检查资源存在）
    t.assert_true(ResourceLoader.exists("res://scenes/main/Main.tscn"), "Main scene should exist")
    
    # 验证水位预置体仍可加载（未破坏）
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/water/Lake.tscn"), "Lake prefab should still exist")
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/water/RiverStraight.tscn"), "RiverStraight should still exist")
```

- [ ] **Step 7: 验证**

```bash
godot --headless --xr-mode off --path . --check-only --quit
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

期望结果：两项命令均 exit 0。

---

## Phase 2：城郊连接走廊（Connection Corridor）

创建从小镇北门到山谷的具体路径和视觉引导。

### Task 2.1：创建路径+石阶预置体

**Files:**
- Create: `scenes/prefabs/terrain/PathSegment_3x6m.tscn`
- Create: `scenes/prefabs/terrain/StoneStep_3x0_5m.tscn`
- Create: `scenes/prefabs/terrain/CliffWall_4x6m.tscn`

- [ ] **Step 1: 创建 PathSegment_3x6m.tscn**

```gdscript
# 3m × 6m 标准路径段预置体
# 可以首尾相接铺出连续路径

# PathSegment_3x6m (StaticBody3D)
# ├── Surface (MeshInstance3D) - BoxMesh(3, 0.15, 6)  # 路面
# ├── CollisionShape3D - BoxShape3D(3, 0.15, 6)
```

- [ ] **Step 2: 创建 StoneStep_3x0_5m.tscn**

```gdscript
# 3m 宽 × 0.5m 深 × 0.3m 高 石阶
# 用于路径坡度较陡时

# StoneStep_3x0_5m (StaticBody3D)
# ├── Surface (MeshInstance3D) - BoxMesh(3, 0.3, 0.5)
# └── CollisionShape3D - BoxShape3D(3, 0.3, 0.5)
```

- [ ] **Step 3: 创建 CliffWall_4x6m.tscn**

```gdscript
# 4m 宽 × 6m 高 × 2m 深 崖壁模块
# 用灰盒 BoxMesh 表示，后续可替换为岩石模型

# CliffWall_4x6m (StaticBody3D)
# ├── Surface (MeshInstance3D) - BoxMesh(4, 6, 2), 使用 mat_mountain_rock.tres
# └── CollisionShape3D - BoxShape3D(4, 6, 2)
```

### Task 2.2：在 Main.tscn 中组装连接走廊

- [ ] **Step 1: 计算路径坐标**

路径从小镇北门 (0, 0, -32) 出发，到山谷 (0, 20, -48)：
- 总距离约 16m 水平 + 20m 垂直抬升
- 水平段：' (0,0,-32) → (0,0,-42) 10m 平路（过渡区）
- 爬升段：从 (0,0,-42) 到 (0,20,-48) 用约 8 段石阶/坡道
- 阶梯布局：每段水平前移 0.75m，抬升 2.5m，共 8 段 → 水平 6m + 垂直 20m

或者更平缓：使用坡道 + 分段平台的方式，每 3m 水平抬升 2m（坡度约 33° 偏高），
更合理的方案：使用 Z 字形转向增加路径长度降低坡度。

建议简化方案：直线坡道 + 石阶混合，中间设 2 个停留平台。

- [ ] **Step 2: 在 Main.tscn 中添加 ConnectionCorridor 节点**

```gdscript
# ConnectionCorridor (Node3D) 位于 Main 场景
# 子节点：
# 1. 过渡段 (Node3D) - 从北门到山脚
#     ├── PathSegment_01 (PathSegment_3x6m 实例) at (0,0,-35)
#     ├── PathSegment_02 (PathSegment_3x6m 实例) at (0,0,-41)
#     ├── PathSegment_03 (PathSegment_3x6m 实例) at (0,2,-44)   # 开始抬升
#     └── PathSegment_04 (PathSegment_3x6m 实例) at (0,4,-47)
# 2. 爬升段 (Node3D) - 山路
#     ├── StoneStep_01~08 (StoneStep_3x0_5m 实例) 
#     │   布置在 Z=-47→-65 之间，逐步抬升 Y=4→20
#     ├── RestPlatform_01 (BoxMesh 4x0.2x4) at (0,10,-56)
#     └── RestPlatform_02 (BoxMesh 4x0.2x4) at (0,16,-62)
# 3. 崖壁 (Node3D) - 路径两侧
#     ├── CliffLeft_01~04 (CliffWall_4x6m 实例)
#     ├── CliffRight_01~04 (CliffWall_4x6m 实例)
#     └── 布置在路径两侧约 ±2.5m 处
```

### Task 2.3：添加瀑布地标（NPC 导航线索）

- [ ] **Step 1: 在连接走廊附近实例化 Waterfall.tscn**

```gdscript
# 从 Waterfall.tscn 预置体实例化
# 位置应在山路中段可见处 (18, 12, -50) 左右
# 酒馆老板 NPC 说："看到瀑布就到了"

# 在 ConnectionCorridor 中添加:
# WaterfallView (Waterfall 实例) at (18, 12, -50)
# 旋转使瀑布朝向路径方向
# 调整 scale 使瀑布在路径上清晰可见
```

- [ ] **Step 2: 调整 Waterfall 参数**

水帘尺寸调整到适合山景的比例（默认可能偏小），可放大到 1.5~2x。

- [ ] **Step 3: 验证瀑布在路径上可见**

在 Godot 编辑器中从路径各段观察瀑布的视线是否被阻挡。

- [ ] **Step 4: 运行动画检查**

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

---

## Phase 3：山谷试炼区实体化

将 MountainTrial.tscn 中的空 Node3D 替换为实际几何体。

### Task 3.1：创建山谷平台和战斗区

**Files:**
- Modify: `scenes/mountain/MountainTrial.tscn`
- Create: `scenes/prefabs/terrain/ValleyPlatform_12x12m.tscn`

- [ ] **Step 1: 创建 ValleyPlatform_12x12m.tscn**

```gdscript
# 12m × 12m 山谷主平台
# 包含地面 + 碰撞

# ValleyPlatform_12x12m (StaticBody3D)
# ├── Surface (MeshInstance3D) - BoxMesh(12, 0.2, 12)
# ├── CollisionShape3D - BoxShape3D(12, 0.2, 12)
```

- [ ] **Step 2: 创建 SealPlatform_8x8m.tscn**

```gdscript
# 8m × 8m 封印战斗平台
# 位于封印正下方，中心对齐

# SealPlatform_8x8m (StaticBody3D)
# ├── Surface (MeshInstance3D) - BoxMesh(8, 0.2, 8)
# └── CollisionShape3D - BoxShape3D(8, 0.2, 8)
```

- [ ] **Step 3: 修改 MountainTrial.tscn**

为现有的空节点添加几何体：
- `MountainPath` → 添加 ValleyPlatform_12x12m 实例（作为山谷入口平台）
- `SealEncounter` → 下方添加 SealPlatform_8x8m 实例
- 封印柱标记：在 SealPlatform 四周添加 4 个 BoxMesh(0.5, 3, 0.5) 作为封印柱
- `FlyingSword` → 下方添加 BoxMesh(2, 0.3, 2) 作为祭台底座
- `TrialSpirit` → 添加 BoxMesh(1, 0.1, 1) 作为脚下平台

### Task 3.2：添加山谷崖壁和围合

- [ ] **Step 1: 在山谷平台周围添加崖壁**

```gdscript
# 在 MountainTrial 中添加:
# SurroundingCliffs (Node3D)
# ├── Cliff_N (CliffWall_4x6m) at (0, 23, -54)  # 山谷北侧
# ├── Cliff_S (CliffWall_4x6m) at (0, 23, -42)  # 山谷南侧
# ├── Cliff_W (CliffWall_4x6m) at (-8, 23, -48) # 山谷西侧
# ├── Cliff_E (CliffWall_4x6m) at (8, 23, -48)  # 山谷东侧
# └── 多个崖壁拼接形成围合
```

- [ ] **Step 2: 创建远山预置体**

使用 BoxMesh 加 mat_mountain_rock.tres 材质制作远景山体轮廓。
暂时不使用 SceneLodGroup（Phase 7 中统一处理 LOD），先用简单几何体。

- [ ] **Step 3: 验证**

```bash
godot --headless --xr-mode off --path . --check-only --quit
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

---

## Phase 4：建筑壳体 + 区域标记替换

将 Town.tscn 中的 12 个 BoxMesh 区域标记替换为灰盒建筑。

### Task 4.1：确定建筑灰盒标准

**设计决策：** 建筑壳体使用 Godot 原生 BoxMesh，不加 .glb 模型。每个建筑壳体是一个 StaticBody3D + 多个 MeshInstance3D 组合。这使灰盒阶段快速迭代，后续替换模型时只需替换 MeshInstance3D 的 mesh 属性。

**Files:**
- Create: `scenes/prefabs/buildings/`（目录）

- [ ] **Step 1: 创建建筑壳体尺寸标准**

根据 `docs/art/3d-grid-size-standard.md`：
- 小型建筑：4m × 4m × 3m（摊位、铁匠铺、粮仓）
- 中型建筑：6m × 6m × 4m（衙门、码头建筑）
- 大型建筑：8m × 8m × 5m（寺庙、核心建筑）
- 远景建筑：4m × 4m × 6m（细长剪影）或 6m × 4m × 4m（扁平剪影）

- [ ] **Step 2: 创建通用建筑壳体预置体**

```gdscript
# SmallBuildingShell (StaticBody3D)
# ├── Walls (MeshInstance3D) - BoxMesh(4, 3, 4) 使用 mat_warm_wood.tres
# └── CollisionShape3D - BoxShape3D(4, 3, 4)

# MediumBuildingShell (StaticBody3D)
# ├── Walls (MeshInstance3D) - BoxMesh(6, 4, 6) 使用 mat_warm_wood.tres
# └── CollisionShape3D - BoxShape3D(6, 4, 6)

# LargeBuildingShell (StaticBody3D)
# ├── Walls (MeshInstance3D) - BoxMesh(8, 5, 8) 使用 mat_warm_wood.tres
# └── CollisionShape3D - BoxShape3D(8, 5, 8)

# DistantBuildingShell (StaticBody3D)
# ├── Walls (MeshInstance3D) - BoxMesh(4, 6, 3) 使用 mat_dark_roof_tile.tres
# └── (无碰撞或极简碰撞)

# 每个建筑壳体可加额外 Roof 子节点引用 Roof01~10 预置体
```

### Task 4.2：逐个替换 12 个区域标记

- [ ] **Step 1: 替换核心区域（高优先级）**

在 Town.tscn 中修改以下节点，将 `*Marker` 替换为对应的 BuildingShell 实例：

| 原标记 | 替换为 | 理由 |
|--------|--------|------|
| `WestDistrict/CanalMarker` (Box) | 移除标记，添加 RiverStraight 水面实例 | 视觉核心 |
| `WestDistrict/WaterwheelMarker` (Box) | MediumBuildingShell + 水车轮标记 | 西区视觉焦点 |
| `EastDistrict/YamenMarker` (Box) | MediumBuildingShell + 屋顶 | 东区地标 |
| `SouthEastDistrict/TempleMarker` (Box) | LargeBuildingShell + 特殊屋顶 | 天际线地标 |
| `EastDistrict/DockMarker` (Box) | SmallBuildingShell + Lake 水面实例 | 边缘视觉 |

- [ ] **Step 2: 替换次要区域**

| 原标记 | 替换为 |
|--------|--------|
| `NorthEastDistrict/GranaryMarker` (Box) | SmallBuildingShell |
| `NorthEastDistrict/BlacksmithMarker` (Box) | SmallBuildingShell |
| `WestDistrict/FarmlandWestMarker` (Box) | 3 个 SmallBuildingShell（农舍） |
| `WestDistrict/FarmlandNorthWestMarker` (Box) | 2 个 SmallBuildingShell |
| `WestDistrict/FarmlandSouthWestMarker` (Box) | 2 个 SmallBuildingShell |
| `NorthEastDistrict/ForestryMarker` (Box) | 移除，替换为树丛标记 |
| `NorthEastDistrict/FishingVillageMarker` (Box) | 3 个 SmallBuildingShell |

- [ ] **Step 3: 创建 CoreBuildingShells 节点**

添加 6 个核心建筑壳体，分布在客栈和酒馆之间填补天际线：
- Core_01 at (-4, 0, 2) — Small
- Core_02 at (4, 0, -4) — Medium
- Core_03 at (-8, 0, -12) — Small
- Core_04 at (6, 0, -8) — Small
- Core_05 at (-14, 0, 14) — Medium
- Core_06 at (16, 0, 4) — Small

- [ ] **Step 4: 创建 DistantBuildingShells**

12 个远景壳体，放置在城墙外侧周围一圈：
- 北墙外：D_01~03 at (15,0,-38), (-5,0,-38), (-20,0,-38)
- 西墙外：D_04~06 at (-28,0,0), (-28,0,10), (-28,0,20)
- 东墙外：D_07~09 at (28,0,-5), (28,0,5), (28,0,15)
- 南墙外：D_10~12 at (15,0,32), (-5,0,32), (-20,0,32)

使用 `SceneLodGroup` 包装，设置 25m mid / 70m far 切换距离。

### Task 4.3：修复 Inn.tscn 碰撞体

- [ ] **Step 1: 检查当前 Inn 碰撞体**

当前 Inn.tscn 的 CollisionShape3D 尺寸为 `Vector3(0.99428, 0.762061, 0.566659)`，远小于建筑体量。

- [ ] **Step 2: 更新 Inn.tscn 碰撞体**

将碰撞体尺寸改为匹配 Inn.glb 实际尺寸，约为 `Vector3(12, 6, 8)` 左右。
需在 Godot 编辑器中打开 Inn.glb 测量实际范围，或在场景中目测调整。

编辑 `scenes/prefabs/models/Inn/Inn.tscn`：

```gdscript
# 旧:
# size = Vector3(0.99428, 0.762061, 0.566659)
# 新:
size = Vector3(12, 6, 8)
# 位置调整到建筑中心:
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3, 0)
```

- [ ] **Step 3: 验证**

```bash
godot --headless --xr-mode off --path . --check-only --quit
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

---

## Phase 5：街景道具与植被

添加灯笼、招牌、木箱等街景道具，以及树木植被。

### Task 5.1：创建道具预置体

**Files:**
- Create: `scenes/prefabs/props/Lantern.tscn`
- Create: `scenes/prefabs/props/WoodenBox.tscn`
- Create: `scenes/prefabs/props/WineJar.tscn`
- Create: `scenes/prefabs/props/Signboard.tscn`
- Create: `scenes/prefabs/props/Tree.tscn`
- Create: `scenes/prefabs/props/PineTree.tscn`

- [ ] **Step 1: 创建 Lantern.tscn**

```gdscript
# 红灯笼预置体
# 使用 mat_lantern_red.tres（已有自发光材质）

# Lantern (Node3D)
# ├── Body (MeshInstance3D) - SphereMesh(radius=0.15) 使用 mat_lantern_red.tres
# ├── Top (MeshInstance3D) - BoxMesh(0.08, 0.05, 0.08) 黑色
# ├── String (MeshInstance3D) - CylinderMesh(radius=0.01, height=0.15)
# └── OmniLight3D（可选，增加氛围光照）
```

- [ ] **Step 2: 创建 WoodenBox.tscn**

```gdscript
# 木箱 0.8m × 0.6m × 0.8m
# WoodenBox (StaticBody3D)
# ├── Mesh (MeshInstance3D) - BoxMesh(0.8, 0.6, 0.8) 使用 mat_warm_wood.tres
# └── CollisionShape3D - BoxShape3D(0.8, 0.6, 0.8)
```

- [ ] **Step 3: 创建 Tree.tscn 和 PineTree.tscn**

```gdscript
# 简单树预置体（灰盒阶段使用 BoxMesh + CylinderMesh）
# 后续替换为低模树模型

# Tree (StaticBody3D)
# ├── Trunk (MeshInstance3D) - CylinderMesh(radius=0.1, height=2)
# ├── Canopy (MeshInstance3D) - SphereMesh(radius=1.5) 位置 (0, 3.5, 0)
# └── CollisionShape3D (简化碰撞，仅树干)
```

### Task 5.2：在 Town.tscn 中布置道具

- [ ] **Step 1: 灯笼布置**

在以下位置添加 Lantern 实例：
- 主街两侧：每隔 4m 一个，从北门到南门，Y=2.5m 高度
- 客栈入口两侧
- 酒馆入口两侧
- 集市摊位上方

- [ ] **Step 2: 木箱/酒坛布置**

- 集市摊位旁：2-3 个 WoodenBox
- 客栈后门：1-2 个 WoodenBox + 1-2 个 WineJar
- 酒馆门前：2 个 WineJar

- [ ] **Step 3: 树木布置**

- 小镇外围城墙内侧：8-10 棵树
- 城郊路径两侧：4-6 棵 PineTree
- 山谷入口：2-3 棵 PineTree

- [ ] **Step 4: 验证**

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

---

## Phase 6：水体实例化 + 飞行路线

### Task 6.1：在世界场景中实例化水体

- [ ] **Step 1: 添加城市运河**

在 Main.tscn 中添加 `WaterFeatures` 节点，实例化：
- `Canal` (RiverStraight 实例) at (-10, 0, 8) — 西区运河
- `TownLake` (Lake 实例) at (-22, 0, 4) — 西郊湖面（水车旁）
- `MountainStream` (RiverBend 实例) at (-6, 12, -55) — 山路溪流

- [ ] **Step 2: 调整水体参数**

```gdscript
# Canal:
#   position: (-10, 0, 8)
#   rotation: y 90度（依运河走向调整）
#   flow_speed: 0.15（慢速流动）

# TownLake:
#   position: (-22, 0, 4)
#   flow_speed: 0.05（近乎静止）

# MountainStream:
#   position: (-6, 12, -55)
#   flow_speed: 0.3（山间溪流较急）
```

### Task 6.2：创建飞行路线视觉

**Files:**
- Create: `scenes/prefabs/flight/RouteRing.tscn`
- Create: `scenes/prefabs/flight/AerialLantern.tscn`
- Create: `scenes/prefabs/flight/CloudWisp.tscn`

- [ ] **Step 1: 创建 RouteRing.tscn**

```gdscript
# 飞行路线环形标记（半透明环状）
# 用于标识飞行路径方向

# RouteRing (Node3D)
# ├── Ring (MeshInstance3D) - TorusMesh(inner_radius=2, outer_radius=2.2, height=0.1)
# │   使用 mat_spell_cyan.tres（已有青色自发光材质），透明度调低
# └── 可选：GPUParticles3D 环绕粒子
```

- [ ] **Step 2: 创建 AerialLantern.tscn**

```gdscript
# 空中灯笼（比街道灯笼稍大，带光晕）
# 复用 Lantern 的网格，增加发光效果

# AerialLantern (Node3D)
# ├── Body (MeshInstance3D) - SphereMesh(radius=0.25) 使用 mat_lantern_red.tres
# ├── Glow (OmniLight3D) - light_energy=0.5, range=8m
```

- [ ] **Step 3: 创建 CloudWisp.tscn**

```gdscript
# 云雾面片（半透明，缓慢浮动）

# CloudWisp (Node3D)
# ├── Cloud (MeshInstance3D) - PlaneMesh(4, 2) 使用 mat_mist_blue.tres
# │   旋转使其面向相机（或使用双面渲染）
```

- [ ] **Step 4: 组装飞行路线**

在 Main.tscn 中添加 `FlightRoute` 节点：

```gdscript
# FlightRoute (Node3D)
# 路线从山谷 (0, 25, -48) 到小镇返回触发区 (12, 15, 24)
# 路线途经西郊上空，沿途可见小镇全景

# 环形标记（RouteRing 实例）
# 间隔 8-10m 一个，沿路线排列：
# Ring_01 at (0, 25, -40)
# Ring_02 at (-2, 23, -30)
# Ring_03 at (-4, 21, -20)
# Ring_04 at (-2, 18, -10)
# Ring_05 at (2, 15, 0)
# Ring_06 at (6, 15, 10)
# Ring_07 at (10, 15, 20)

# 空中灯笼：沿路线两侧散布
# 云雾带：在 Z=-20~0 段添加，营造山谷云海效果
```

- [ ] **Step 5: 创建观景远景组合**

在 FlightRoute 中添加 AerialVistas 节点：
- `TownVista` — 从空中看小镇的全景组合（使用远景壳体实例）
- `MountainVista` — 从空中看山川的远景组合（使用远山模块）

使用 SceneLodGroup 包装远景，25m/70m 切换。

- [ ] **Step 6: 验证**

```bash
godot --headless --xr-mode off --path . --check-only --quit
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

---

## Phase 7：环境氛围 + LOD 整合

### Task 7.1：天空盒与雾气

- [ ] **Step 1: 创建简单渐变 Sky 材质**

```gdscript
# 使用 ProceduralSkyMaterial 创建渐变天空
# 或者使用 PanoramaSkyMaterial + 一张天空纹理

# 在 WorldEnvironment 中替换当前纯色背景:
# 旧: background_mode = BG_COLOR
# 新: background_mode = BG_SKY
#     sky = ProceduralSkyMaterial
#         sky_top_color = Color(0.35, 0.55, 0.75)  # 淡蓝
#         sky_horizon_color = Color(0.75, 0.70, 0.65)  # 暖灰
#         sky_curve = 0.15
#         ground_bottom_color = Color(0.30, 0.25, 0.20)  # 深褐
#         ground_horizon_color = Color(0.55, 0.50, 0.45)
#         ground_curve = 0.05
```

- [ ] **Step 2: 添加高度雾**

在 WorldEnvironment 中添加 Fog 配置或在 Main.tscn 中添加 FogVolume：

```gdscript
# 方式 A：WorldEnvironment Fog 属性（最简单）
# environment.fog_enabled = true
# environment.fog_light_color = Color(0.7, 0.75, 0.8)
# environment.fog_light_energy = 0.1
# environment.fog_density = 0.005  # 轻度雾
# environment.fog_height = 15.0    # 高度雾起始
# environment.fog_height_density = 0.5  # 高度雾密度

# 方式 B：FogVolume 节点（更精确的位置控制）
# FogVolume (FogVolume) at (0, 10, -40)  Size=(40, 10, 40)
# fog_material = FogMaterial
#   density = 0.02
#   height = 10.0
```

### Task 7.2：LOD 整合

- [ ] **Step 1: 审计需要 LOD 的场景元素**

| 元素 | 当前状态 | 需要 LOD? |
|------|----------|-----------|
| 小镇建筑壳体 | 灰盒 | 是，最多 25m 可见 |
| 远景建筑壳体 | 灰盒 | 是，25m/70m 切换 |
| 远山剪影 | 灰盒 | 是，25m/70m 切换 |
| 树木 | 灰盒 | 是，70m 消失 |
| 飞行路线标记 | 低模 | 默认可见，可设 100m 消失 |
| 封印/飞剑/NPC | 逻辑节点 | 否，保留在 LOD 外 |

- [ ] **Step 2: 为已创建的元素添加 SceneLodGroup 包装**

对 `DistantBuildingShells`、`DistantMountains`、`AerialVistas` 和树木集群，用 SceneLodGroup 做近/中/远三级切换：
- Near：完整灰盒
- Mid：简化几何体（合并面片）
- Far：不可见或空节点

```gdscript
# 示例：DistantMountains 的 LOD 结构
# SceneLodGroup
# ├── Near (Node3D) - 4 个远山模块 (4m size)
# ├── Mid (Node3D) - 2 个合并面片 (8m size)
# └── Far (Node3D) - 空节点（超过 70m 不可见）
```

### Task 7.3：环境光调校

- [ ] **Step 1: 检查 EnvironmentController 参数**

当前 EnvironmentController 的默认参数：
- `summer_light_energy = 1.35`
- `summer_sky_color = Color(0.48, 0.58, 0.68)`
- `time_of_day_hours = 16.0`（下午 4 点）

评估是否需要调整：
- 如果场景视觉偏暗，可提高 light_energy 到 1.5~1.8
- 如果 sky_color 与环境不协调，可微调色相

- [ ] **Step 2: 添加环境光探头**

在 Main 场景的关键位置添加 ReflectionProbe 或 LightmapGI：
- 小镇中心：捕捉建筑物之间的间接光照
- 山谷平台：捕捉天空和崖壁的反射

- [ ] **Step 3: 验证**

```bash
godot --headless --xr-mode off --path . --check-only --quit
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

---

## Phase 8：测试、修复与收尾

### Task 8.1：添加地形/世界相关测试

**Files:**
- Modify: `tests/test_terrain.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: 扩展地形测试**

```gdscript
# 在 test_terrain.gd 中添加:
func run(t) -> void:
    # 第一阶段：基本资源存在性
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/TownGround.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/SuburbGround.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/MountainGround.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/WorldBoundary.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/PathSegment_3x6m.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/StoneStep_3x0_5m.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/terrain/CliffWall_4x6m.tscn"))
    
    # 道具预置体
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/props/Lantern.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/props/WoodenBox.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/props/Tree.tscn"))
    
    # 飞行路线
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/flight/RouteRing.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/flight/AerialLantern.tscn"))
    
    # 建筑壳体
    var building_dir = "res://scenes/prefabs/buildings/"
    t.assert_true(ResourceLoader.exists(building_dir + "SmallBuildingShell.tscn"))
    t.assert_true(ResourceLoader.exists(building_dir + "MediumBuildingShell.tscn"))
    
    # 验证 Main 场景仍然可加载
    t.assert_true(ResourceLoader.exists("res://scenes/main/Main.tscn"))
    
    # 验证现有功能未损坏：所有原来的预置体仍然存在
    t.assert_true(ResourceLoader.exists("res://scenes/town/Town.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/mountain/MountainTrial.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/water/Lake.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/water/RiverStraight.tscn"))
    t.assert_true(ResourceLoader.exists("res://scenes/prefabs/water/Waterfall.tscn"))
```

- [ ] **Step 2: 在 test_runner.gd 中注册新测试**

在 `test_runner.gd` 的 `test_paths` 数组中添加 `"res://tests/test_terrain.gd"`。

- [ ] **Step 3: 运行完整测试**

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

期望输出：`TESTS PASSED: <N> assertions`，所有断言通过。

- [ ] **Step 4: 安全检查**

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

期望输出：exit 0，无错误。

### Task 8.2：问题修复和碰撞检查

- [ ] **Step 1: 步行穿墙检查**

在 Godot 编辑器中以桌面玩家模式运行，步行遍历所有路径：
- 小镇主街：可否顺畅行走？有无碰撞间隙？
- 客栈入口：碰撞体是否阻挡正确？
- 山路路径：每一步能否踩实？有无悬空或穿透？
- 山谷战斗区：玩家能否自由移动？

- [ ] **Step 2: 飞行碰撞检查**

飞行模式遍历飞行路线：
- 环形标记是否清晰可见？
- 飞行路径上是否有意外碰撞阻挡？
- 高度是否在舒适模式限制内（45m）？

- [ ] **Step 3: 修复发现问题**

对发现的问题逐一修复（碰撞缺失、位置错位、高度不一致等）。

### Task 8.3：文档更新

- [ ] **Step 1: 更新 town-layout.md**

将 `docs/art/town-layout.md` 中的坐标和布局信息更新为新的实际布局。

- [ ] **Step 2: 更新 progress.md**

在 `progress.md` 中记录世界构建的完成状态。

- [ ] **Step 3: 更新 3d-model-asset-checklist.md**

将已完成的灰盒建筑壳体标记为 `[~]`（灰盒阶段完成）。

---

## 执行顺序依赖图

```
Phase 1 (地形基础) ──→ Phase 2 (连接走廊) ──→ Phase 3 (山谷实体化)
      │                                              │
      │                                              ▼
      └──────────────────────┬───────────────── Phase 6 (飞行路线)
                             │
                             ▼
Phase 4 (建筑壳体) ──→ Phase 5 (道具植被) ──→ Phase 7 (环境+LOD)
                                                     │
                                                     ▼
                                              Phase 8 (测试收尾)
```

**关键依赖：**
- Phase 1 是所有后续的基础，必须先完成
- Phase 2 和 Phase 4 可并行
- Phase 3 依赖 Phase 2（路径接入）
- Phase 5 依赖 Phase 4（建筑布局完后才能放街景）
- Phase 6 依赖 Phase 2 + Phase 3（飞行路线两端连接 Town 和 Mountain）
- Phase 7 可与其他并行（LOD 包装不影响功能）
- Phase 8 是最终验证

---

## 预期成果

完成全部 8 个阶段后：

1. **地形**：从纯平地面变为 3 个高度层的世界（小镇 Y=0 → 城郊缓坡 → 山谷 Y=20+）
2. **路径**：从小镇北门经山脚、石阶、山路到山谷的连续可步行路径
3. **地标**：瀑布作为 NPC 导航线索在山路中可见
4. **天际线**：12 个区域标记替换为建筑壳体 + 6 个核心壳体 + 12 个远景壳体
5. **街景**：灯笼、木箱、酒坛、树木等道具填充场景
6. **飞行**：环形标记 + 灯笼 + 云雾组成的空中路线，两端连接山谷和小镇
7. **环境**：渐变天空盒 + 高度雾 + 水面实例
8. **验证**：测试全绿，检查无错误
