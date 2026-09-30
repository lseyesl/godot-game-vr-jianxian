# Terrain3D 迁移资源缺口分析

> 生成时间: 2026-06-25
> 分析依据: `addons/terrain_3d/` demo 参考 + `scenes/prefabs/terrain/` 现有灰盒地形 + `scenes/main/Main.tscn` 当前布局

---

## 一、现状速览

| 项目 | 当前状态 |
|------|----------|
| 地形 | 10 个灰盒预置体 (BoxMesh/PlaneMesh + StaticBody3D) |
| 世界范围 | 120×60m，高度 Y=0(小镇)→Y=24(山谷) |
| 纹理 | `assets/textures/` 空目录（仅 `.gitkeep`） |
| 材质 | 仅 1 个 `mat_mountain_rock.tres` 用于 CliffWall |
| 碰撞 | 手动 BoxShape3D |
| 导航 | **不存在**（无 NavigationRegion3D / NavigationMesh） |
| Terrain3D | 已安装 v1.0.2 并启用，尚未使用 |
| 地形规划文档 | ✅ `docs/superpowers/plans/2026-06-16-terrain-world-building.md` |
| 3D 模型盘点 | ✅ `docs/art/3d-model-inventory.md` |

## 二、当前地形架构（灰盒待替换）

当前世界由平铺的 StaticBody3D 几何体构成：

| 区域 | 高度范围 | 构成 | 预置体 |
|------|----------|------|--------|
| 小镇 | Y=0 | 4× PlaneMesh (30×25m) = 60×50m 平地 | `TownGround.tscn` |
| 城郊 | Y=0→10 | 5× BoxMesh (20×0.2×6m) 阶梯抬高 | `SuburbGround.tscn` |
| 山路 | Y=10→20 | 5× BoxMesh 路径段 (3×0.2×6m) | `MountainGround.tscn` |
| 山谷 | Y=24 | ValleyPlatform (12m) + SealPlatform (8m) + RestPlatform (4m) | `MountainGround.tscn` |
| 世界边界 | Y=0→60 | 4面不可见碰撞墙包围 120×60m | `WorldBoundary.tscn` |

### Main.tscn 地形结构

```
Main (Node3D)
├── WorldEnvironment
├── DirectionalLight3D
├── EnvironmentController
├── TerrainContainer                    ← 将被 Terrain3D 节点替代
│   ├── TownGround (StaticBody3D)       ← 替换
│   ├── SuburbGround (StaticBody3D)     ← 替换
│   ├── MountainGround (StaticBody3D)   ← 替换
│   └── WorldBoundary (StaticBody3D)    ← 保留
├── ConnectionCorridor                  ← Path_01~06 + CliffWalls 需适配
├── WaterFeatures                       ← 水面高度需对齐地形
├── FlightRoute                         ← 不变（在空中）
├── Town (Town.tscn)                    ← 建筑/NPC 需投影到地形表面
├── MountainTrial (MountainTrial.tscn)  ← 封印/平台需适配
├── TaskHud
└── CompletionFeedback
```

## 三、Terrain3D 核心资源需求

从 addon 文档和 `demo/Demo.tscn` 分析，一个完整 Terrain3D 地形需要：

```
Terrain3D 节点
├── data_directory/                      ← 区域文件目录
│   ├── terrain3d_0_0.res               (高度图 + 控制图 + 颜色图)
│   └── terrain3d_0_1.res               (更多区域，可选)
├── material: Terrain3DMaterial          ← 着色器配置（auto_shader/noise等）
├── assets: Terrain3DAssets (.tres)      ← 纹理/网格资产注册表
│   ├── Terrain3DTextureAsset #0         (纹理集: 草地)
│   │   ├── albedo_texture              (RGB + 高度 in Alpha 通道)
│   │   └── normal_texture              (RGB 法线 + 粗糙度 in Alpha 通道)  
│   ├── Terrain3DTextureAsset #1         (纹理集: 岩石)
│   ├── Terrain3DTextureAsset #2         (纹理集: 泥土/路径)
│   ├── Terrain3DTextureAsset #3         (纹理集: 石板/砖地)
│   └── Terrain3DMeshAsset [...]         (可选: 植被/石头实例化)
├── collision (Terrain3DCollision)       ← 自动生成，可选碰撞模式
└── instancer (Terrain3DInstancer)       ← 可选: 草地/植被散布
```

## 四、纹理格式要求

Terrain3D 使用**纹理对**，每对 2 张 PNG：

| 文件 | 通道 | 内容 |
|------|------|------|
| `*_alb_ht.png` | RGB | 基础颜色 (Albedo) |
| | Alpha | 高度图 (Height) — 用于纹理高度混合 |
| `*_nrm_rgh.png` | RGB | 法线贴图 (Normal) |
| | Alpha | 粗糙度 (Roughness) |

**至少需要 2-4 组纹理对：**

| 纹理集 | 用途 | 对应地形区域 |
|--------|------|-------------|
| 草地 (grass) | 郊野、山坡、植被覆盖区 | 城郊 Suburb → Mountain 过渡 |
| 岩石 (rock) | 崖壁、山路、山谷 | CliffWall、MountainGround |
| 石板 (stone) | 硬质地面 | 小镇主街、广场 |
| 泥土 (dirt) | 路径、非植被裸露地面 | 连接路径 |

## 五、🔴 P0 — 阻止地形工作的致命缺失

| # | 缺失资源 | 说明 | 需要创建/获取 |
|---|----------|------|-------------|
| 1 | **地形纹理对 ×2-4 套** | Terrain3D 无纹理无法展示视觉 | `assets/textures/terrain/*_alb_ht.png` + `*_nrm_rgh.png` |
| 2 | **Terrain3DAssets 资源** | 定义可用的纹理/网格资产 | `data/terrain/assets.tres` |
| 3 | **地形数据目录** | 存放 .res 区域文件 | `data/terrain/` |
| 4 | **地形高度图** | 定义地面形状 | FastNoiseLite 生成或外部导入 |

**当前状态**：✅ 已从 Downloads 导入 13 组 4K PBR 材质，打包为 Terrain3D 格式 `*_alb_ht.png` + `*_nrm_rgh.png`
  - 草地: aerial_rocks_02, coast_sand_rocks_02, rocky_terrain, rocky_terrain_02
  - 岩石: dry_riverbed_rock, marble_cliff_03, marble_cliff_05
  - 泥土: gravel_road, red_laterite_soil_stones, terrain_red_01
  - 石板: medieval_blocks_05, monastery_stone_floor, rock_tile_floor
  - 资源文件: `assets/textures/terrain/terrain_assets.tres`（草地/岩石/泥土/石板 各选一组）

## 六、🟡 P1 — 场景重构所需

| # | 工作项 | 说明 |
|---|--------|------|
| 5 | **Terrain3D 节点替换 TerrainContainer** | 移除 TownGround/SuburbGround/MountainGround 实例化，添加 Terrain3D 节点覆盖整个世界区域 (120×60m) |
| 6 | **物理材质统一** | 当前 3 个 PhysicsMaterial (friction 0.8/0.9/0.8) 合并为 Terrain3D 的 physics_material 属性 |
| 7 | **建筑/道具高度对齐** | Inn、Tavern、Gate、NPC、灯笼、箱子、墙体屋顶等所有地面元素需投影到地形表面 |
| 8 | **水面高度对齐** | 4 水面预置体 (Lake/RiverStraight/RiverBend/Waterfall) Y 高度与地形对齐 |
| 9 | **世界边界保留** | WorldBoundary 需保持（Terrain3D 不处理世界边界碰撞） |
| 10 | **连接走廊适配** | PathSegment 序列 + CliffWalls 需重新对齐地形高度 |
| 11 | **测试重写** | `tests/test_terrain.gd` 和 `test_main_ground.gd` 断言需改为验证 Terrain3D 节点 |

### 可用的辅助工具

已随 addon 安装的现成工具：

- `addons/terrain_3d/utils/terrain_3d_objects.gd` — `get_height()` 获取地形高度，`set_object_height()` 放置物体到地形表面
- `addons/terrain_3d/extras/3rd_party/project_on_terrain3d.gd` — 将对象投影到地形表面

## 七、🟡 P2 — 导航与碰撞

| # | 工作项 | 说明 |
|---|--------|------|
| 12 | **NavigationRegion3D** | 当前完全无导航系统，地形重构后需烘焙 NavMesh |
| 13 | **碰撞层分离** | 当前全部默认 Layer 1，需定义 terrain/building/player/trigger 层 |
| 14 | **Terrain3D 碰撞模式选型** | DYNAMIC_EDITOR（开发）、DYNAMIC（运行时）、FULL（全碰撞）、NONE（无碰撞） |

## 八、🟢 P3 — 可选增强

| # | 已有资产 | Terrain3D 应用方式 |
|---|----------|-------------------|
| 15 | **植被模型 ×23**（assets/models/Vegetation/） | 注册为 Terrain3DMeshAsset → instancer.add_transforms() 散布 |
| 16 | **小山石、石灯笼** | 作为独立 MeshInstance3D 放置在地形上 |
| 17 | **Demo 参考代码** | `demo/src/CodeGenerated.gd` 是完整的运行时 Terrain3D 创建示例 |
| 18 | **Demo 纹理** | `demo/assets/textures/ground037_*.png` + `rock023_*.png` 可作为临时占位纹理 |

## 九、汇总与优先级

```
优先级矩阵：

立即需要（无此无法工作）:
  1. 地形纹理对 ×2-4       ← 最大缺口，阻断项
  2. Terrain3DAssets .tres
  3. 地形数据目录 + 初始区域

场景重构（中等工作量）:
  4. Terrain3D 节点替换灰盒地面
  5. 建筑/道具/水面高度对齐
  6. 测试更新

增强完善（可选，依赖以上完成）:
  7. NavigationRegion3D 烘焙
  8. 植被实例化 (23种植被模型)
  9. 碰撞层策略

推荐启动路径:
  Step 1: 拷贝 demo 纹理到项目 (ground037 + rock023)
  Step 2: 创建 Terrain3DAssets 引用纹理
  Step 3: 在 Main.tscn 添加 Terrain3D 节点，FastNoiseLite 生成初始高度
  Step 4: 雕刻地形（平地/缓坡/山路/山谷）
  Step 5: 用 project_on_terrain3d.gd 投影建筑到地形
```

## 十、参考文档

- Terrain3D 官方文档: https://terrain3d.readthedocs.io/
- 现有地形计划: `docs/superpowers/plans/2026-06-16-terrain-world-building.md`
- Demo 实现参考: `demo/Demo.tscn` + `demo/src/CodeGenerated.gd`
- 3D 模型盘点: `docs/art/3d-model-inventory.md`
- 网格尺寸标准: `docs/art/3d-grid-size-standard.md`
