# Prefab Inspector Dashboard — 设计文档

> **版本:** v1.0
> **日期:** 2026-06-30
> **状态:** 草案

## 1. 为什么需要这个工具

当前所有 prefab 的状态是**不可见的**。要回答"哪个建筑缺碰撞体"这样的问题，需要逐个打开 `.tscn` 文件检查。100 个 prefab 分布在 `scenes/prefabs/` 下 7 个子目录里，手动审计一次需要 30-60 分钟。

这个工具把散落在文件里的元数据**汇总成一张可排序、可过滤、可操作的表格**，让质量和状态的审计变成"看一眼"的事。

## 2. 数据模型

对每个 prefab 场景，提取以下元数据：

### 基础信息

| 字段 | 来源 | 类型 | 示例 |
|---|---|---|---|
| `name` | 文件名（去掉 `.tscn`） | String | `lantern_01` |
| `category` | 目录深度第二层 | String | `models` |
| `subcategory` | 剩余目录路径 | String | `props/lantern_01` |
| `file_size` | `FileAccess.get_length()` | int (bytes) | 2048 |
| `last_modified` | `FileAccess.get_modified_time()` | int (unix ts) | 1751234567 |

### 结构信息（从 TSCN 文本解析）

| 字段 | 检测方法 | 状态值 |
|---|---|---|
| `has_glb` | `[ext_resource type="PackedScene" ... .glb"]` | ✅ ❌ |
| `has_collision` | `type="StaticBody3D"` 或 `CollisionShape3D` 或 `CollisionPolygon3D` | ✅ ❌ |
| `has_script` | `script = ExtResource(...)` 任意节点 | ✅ ❌ |
| `has_material_override` | `surface_material_override/` 或 `material = ExtResource(...)` | ✅ ❌ |
| `has_audio` | `type="AudioStreamPlayer3D"` | ✅ ❌ |
| `has_particles` | `type="GPUParticles3D"` 或 `type="CPUParticles3D"` | ✅ ❌ |
| `root_type` | 首行 `[node name="..." type="..."]` 的 type | `Node3D`, `StaticBody3D`, ... |
| `root_matches_filename` | 根节点 name == 文件名（去掉.tscn） | ✅ ❌ |
| `is_static_body` | 根节点或子节点是 StaticBody3D | ✅ ❌ |
| `has_lod_group` | `VisibilityNotifier3D` / `MultiMesh` 相关 | ✅ ❌ |

### 衍生指标

| 字段 | 计算方式 |
|---|---|
| `health_score` | (has_collision + has_glb + root_matches_filename + is_static_body) * 25 |
| `is_ready_for_placement` | has_collision == true && has_glb == true |
| `warnings` | 聚合的健康警告列表 |

## 3. 架构

```
addons/prefab_inspector/
├── plugin.cfg
├── plugin.gd                 # EditorPlugin 生命周期
├── icons/
│   └── icon.png
├── panels/
│   ├── inspector_panel.tscn   # 底部面板场景
│   └── inspector_panel.gd     # 面板逻辑
└── scripts/
    └── prefab_scanner.gd      # 扫描+解析引擎
```

### 组件职责

| 组件 | 职责 | 复用资产 |
|---|---|---|
| `PrefabScanner` | 扫描目录、解析 TSCN、提取元数据 | 完全复用 `AssetScanner` 的目录遍历 + 文本解析模式 |
| `InspectorPanel` | Tree 表格渲染、排序、过滤、右键菜单 | 新 UI（Tree 控件） |
| `plugin.gd` | 注册/销毁面板、bridge 连接 | 同 asset_placer 的 EditorPlugin 模式 |

### 与 Asset Placer 的关系

两个插件**独立但互补**：

```
Asset Placer:          "选择一个 prefab → 放到场景里"
Prefab Inspector:      "所有 prefab 的状态如何？哪些是完好的？"
                           ↑
                   只有完好的 prefab 才值得放置
```

Prefab Inspector 可以作为 Asset Placer 的**前置质量门**——先在 Inspector 里修好残缺 prefab，再到 Placer 里放心使用。

## 4. UI 设计

### 布局

```
┌─────────────────────────────────────────────────────────┐
│ [搜索框...             ] [分类 ▼] [严重度 ▼] [🔍 重新扫描] │  ← 工具栏
├─────────────────────────────────────────────────────────┤
│ Name        │ Cat  │ Collision │ GLB │ Script │ Mat │ 状态 │  ← 可点击排序
├─────────────────────────────────────────────────────────┤
│ 🟢 inn_01     │ bldg │ ✅         │ ✅   │ ❌     │ ❌  │ 100% │
│ 🟡 shop_02    │ bldg │ ❌         │ ✅   │ ❌     │ ❌  │  75% │
│ 🔴 lantern_01 │ prop │ ❌         │ ✅   │ ❌     │ ❌  │  50% │
│ 🟢 TownGround │ terr │ ✅         │ ❌   │ ❌     │ ✅  │  75% │
│ 🔴 Signboard  │ prop │ ❌         │ ❌   │ ❌     │ ❌  │  25% │
├─────────────────────────────────────────────────────────┤
│ 全部: 100  |  显示: 100  |  严重问题: 12  |  警告: 8   │  ← 状态栏
└─────────────────────────────────────────────────────────┘
```

### 交互

| 操作 | 行为 |
|---|---|
| **单击行** | 选中 prefab，在右侧（或底部）显示详细信息 |
| **双击行** | 在编辑器中打开该 prefab 场景（`EditorInterface.open_scene_from_path()`） |
| **点击列头** | 按该列排序（升序/降序/不排序 循环） |
| **搜索框** | 实时按 name/category 过滤 |
| **分类下拉** | 按目录过滤（全部 / buildings / models / props / terrain / water / flight） |
| **严重度下拉** | 全部 / 严重（缺碰撞体）/ 警告（缺 GLB）/ 健康（全部通过） |
| **右键菜单** | 见下方 |

### 右键菜单

```
┌─────────────────────────────────────┐
│ 在编辑器中打开                        │
│ 在文件管理器中定位                    │
│ ─────────────────────────────────    │
│ 🛠 快速修复                          │
│    ├─ 添加 StaticBody3D 碰撞体       │
│    ├─ 添加 CollisionShape3D          │
│    └─ 标记为"已审核"                 │
│ ───────────────────────────────────── │
│ 📋 复制文件路径                      │
│ ℹ️ 查看详情...                       │
└─────────────────────────────────────┘
```

### 颜色编码

| 健康度 | 颜色 | 条件 |
|---|---|---|
| 🟢 健康 | 绿色背景 | health_score == 100 |
| 🟡 警告 | 黄色背景 | health_score >= 50（但有一些非关键问题） |
| 🔴 严重 | 红色背景 | 缺碰撞体（无法在运行时交互） |

## 5. TSCN 解析策略

使用**字符串匹配**（而非完整 parser），因为：

1. TSCN 格式是结构化的文本，比 JSON 语法更简单
2. 我们只需要存在性检测，不需要理解值语义
3. 与现有 `AssetScanner._detect_glb_reference()` 的策略一致

### 检测规则

```gdscript
# has_glb
content.contains(".glb\"")
# 或: 检查[ext_resource] 行 type="PackedScene" 且 path 以 .glb 结尾

# has_collision
content.contains("type=\"CollisionShape3D\"")
# 或 content.contains("type=\"CollisionPolygon3D\"")
# 或 content.contains("type=\"StaticBody3D\"")

# has_script
# 查找所有 script = ExtResource("id") 不管在哪种节点下
# regex: script = ExtResource\("\d+"\)

# has_material_override
content.contains("surface_material_override")
# 或 content.contains("material = ExtResource(")
# 注意: sub_resource 内部的 material 不算 override

# has_audio
content.contains("type=\"AudioStreamPlayer3D\"")

# has_particles
content.contains("type=\"GPUParticles3D\"") or content.contains("type=\"CPUParticles3D\"")

# root_type
# 匹配第一个 [node name="..." type="..."]
# regex: ^\[node name=".*" type="([^"]+)"

# root_matches_filename
# 提取第一个 [node name="..." 的值，与文件名（去掉.tscn）比较
# regex: ^\[node name="([^"]+)"
```

## 6. 文件结构（详细）

### `scripts/prefab_scanner.gd`

```gdscript
class_name PrefabInspectorScanner
extends RefCounted

class PrefabEntry:
    var name: String
    var path: String
    var category: String
    var subcategory: String
    # 结构标志
    var has_glb: bool
    var has_collision: bool
    var has_script: bool
    var has_material_override: bool
    var has_audio: bool
    var has_particles: bool
    var root_type: String
    var root_matches_filename: bool
    # 文件元数据
    var file_size: int
    var last_modified: int

func scan() -> Array[PrefabEntry]: ...
func _scan_directory(dir_path, parent_category, result): ...
func _parse_tscn(full_path, category, result): ...
func _detect_glb_reference(content: String) -> bool: ...
func _detect_collision(content: String) -> bool: ...
func _detect_script(content: String) -> bool: ...
func _detect_material_override(content: String) -> bool: ...
func _detect_audio(content: String) -> bool: ...
func _detect_particles(content: String) -> bool: ...
func _extract_root_type(content: String) -> String: ...
func _extract_root_name(content: String) -> String: ...
func _compute_health_score(entry: PrefabEntry) -> int: ...
```

### `panels/inspector_panel.gd`

```gdscript
class_name PrefabInspectorPanel
extends Control

signal prefab_selected(path: String)

var scanner: PrefabInspectorScanner
var _all_entries: Array[PrefabInspectorScanner.PrefabEntry]
var _filtered_entries: Array[PrefabInspectorScanner.PrefabEntry]

@onready var _search_box: LineEdit = %SearchBox
@onready var _category_filter: OptionButton = %CategoryFilter
@onready var _severity_filter: OptionButton = %SeverityFilter
@onready var _prefab_tree: Tree = %PrefabTree
@onready var _status_label: Label = %StatusLabel
@onready var _scan_btn: Button = %ScanButton

# 排序状态
var _sort_column: int = 0
var _sort_ascending: bool = true
```

**Tree 控件设置**：
- 列数: 7（Name, Category, Collision, GLB, Script, Material, Status）
- 列是可点击的标题，点击触发排序
- 每行的 `set_cell_metadata(col, entry)` 存储完整 entry 引用

### `panels/inspector_panel.tscn`

场景结构使用 `Control > HBoxContainer > Tree + VBoxContainer（筛选+状态栏）` 布局，与 asset_browser_panel.tscn 同风格。

列宽度：Name=3, Category=1, Collision=1, GLB=1, Script=1, Material=1, Status=1

### `plugin.gd`

```gdscript
@tool
extends EditorPlugin

const PANEL_NAME := "Prefab Inspector"

var bottom_panel: Control
var inspector_panel: PrefabInspectorPanel
var scanner: PrefabInspectorScanner

func _enter_tree() -> void:
    scanner = PrefabInspectorScanner.new()
    var panel_scene := load("res://addons/prefab_inspector/panels/inspector_panel.tscn") as PackedScene
    bottom_panel = panel_scene.instantiate() as Control
    inspector_panel = bottom_panel as PrefabInspectorPanel
    inspector_panel.scanner = scanner
    add_control_to_bottom_panel(bottom_panel, PANEL_NAME)

func _exit_tree() -> void:
    if bottom_panel:
        remove_control_from_bottom_panel(bottom_panel)
        bottom_panel.queue_free()
        bottom_panel = null
        inspector_panel = null
    scanner = null
```

## 7. 测试策略

| 测试 | 内容 |
|---|---|
| `test_scanner_parsing` | 给定 TSCN 文本字符串，验证 `_detect_*` 方法返回正确值 |
| `test_scanner_real_files` | 扫描 `scenes/prefabs/props/` 验证结果数量 >= N |
| `test_scanner_glb_detection` | 已知有 GLB 的 prefab 返回 true |
| `test_scanner_collision_detection` | 已知有碰撞体的 prefab 返回 true |
| `test_panel_creation` | 验证面板 UI 控件存在 |
| `test_health_scoring` | 验证 health_score 计算正确 |

## 8. 扩展性设计

### 未来可添加的列

只需在 `PrefabEntry` 加字段、在 `_parse_tscn` 里加解析逻辑、在 `Tree` 里加一列：

| 潜在列 | 检测方法 |
|---|---|
| `has_lod_group` | `VisibilityNotifier3D` / `LOD` 相关节点 |
| `has_navigation` | `NavigationRegion3D` 节点 |
| `vertex_count` | 需要加载 Mesh 实例（较慢） |
| `git_last_modified` | 调用 `git log` 获取最后修改提交 |
| `has_uid` | 文件系统是否存在 `.uid` 侧车文件 |

### Git 集成（未来）

可选的 CI 模式：在 `lefthook.yml` 中添加 pre-commit 检查，阻止无碰撞体的 prefab 被提交：

```yaml
pre-commit:
  jobs:
    - name: prefab-health-check
      glob: "scenes/prefabs/**/*.tscn"
      run: |
        godot --headless --xr-mode off --path . --script res://addons/prefab_inspector/check_prefab_health.gd -- {staged_files}
```

## 9. 实现工作量估算

| 步骤 | 文件 | 估算 |
|---|---|---|
| 1. 插件脚手架 | plugin.cfg, plugin.gd, icon | ~15 分钟 |
| 2. PrefabScanner | scripts/prefab_scanner.gd | ~40 分钟 |
| 3. InspectorPanel 场景+脚本 | panels/inspector_panel.tscn + .gd | ~45 分钟 |
| 4. 集成 wiring | plugin.gd（最终版） | ~15 分钟 |
| 5. 测试 | tests/test_prefab_inspector.gd | ~30 分钟 |
| **总计** | | **~2.5 小时** |
