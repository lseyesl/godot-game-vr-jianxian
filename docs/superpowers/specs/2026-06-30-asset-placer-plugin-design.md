# Asset Placer Plugin — 设计文档

## 概述

一个 Godot 4.6+ 编辑器插件，在底部面板中列出项目的预制体资产，用户可选择后点击 3D 视口中的位置直接放置到场景中。旨在加速场景搭建工作流。

## 目标

- 在编辑器底部面板展示所有可放置的预制体
- 支持可配置的扫描目录（默认 `res://scenes/prefabs/`）
- 按分类过滤和搜索
- 选择预制体后进入 "放置模式"
- 鼠标在 3D 视口移动时显示半透明预览
- 左键点击将预制体实例化到鼠标指向位置
- 放置后用户可自由旋转/缩放调整

## 非目标

- 不处理运行时的物体放置（仅编辑器工具）
- 不提供内置的旋转/缩放 Gizmo（复用编辑器自带工具）
- 不处理 Terrain3D 以外的地形编辑

## 架构

### 文件结构

```
addons/asset_placer/
├── plugin.cfg                    # 插件元数据
├── plugin.gd                     # EditorPlugin 入口
├── icons/
│   └── icon.png                  # 插件图标
├── panels/
│   ├── asset_browser_panel.tscn  # 底部面板 UI 布局
│   └── asset_browser_panel.gd    # 面板逻辑（搜索/筛选/列表/交互）
└── scripts/
    ├── asset_scanner.gd          # 扫描目录解析预制体元数据
    ├── asset_placer.gd           # 放置模式状态机 + 射线检测 + 实例化
    └── ghost_preview.gd          # 半透明预览实例管理
```

### 目录命名说明

遵循项目 `addons/` 下其他插件（beehave、godot-xr-tools、terrain_3d）的风格：
- 根目录 `asset_placer/`
- `plugin.gd` + `plugin.cfg` 作为入口
- 功能模块分入 `scripts/`、`panels/`、`icons/`

## 模块设计

### 1. plugin.gd — EditorPlugin 入口

```gdscript
extends EditorPlugin

var bottom_panel: Control
var placer: AssetPlacer

func _enter_tree():
    # 1. 实例化 AssetScanner 扫描预制体
    # 2. 加载 asset_browser_panel.tscn
    # 3. add_control_to_bottom_panel() 注册到底部面板
    # 4. 实例化 AssetPlacer，传入面板的选择信号
    # 5. 连接面板的 "start_placing" 信号 → AssetPlacer.enter_placing_mode()

func _exit_tree():
    # remove_control_from_bottom_panel()
    # 清理资源

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
    if placer and placer.is_placing():
        return placer.handle_input(viewport_camera, event)
    return EditorPlugin.AFTER_GUI_INPUT_PASS
```

**关键 API：**
- `_enter_tree()` / `_exit_tree()` — 插件生命周期
- `add_control_to_bottom_panel()` — 注册底部面板
- `_forward_3d_gui_input()` — 拦截 3D 视口输入
- `EditorInterface.get_edited_scene_root()` — 获取当前编辑场景根节点

### 2. AssetScanner — 预制体扫描器

类：`class_name AssetScanner extends RefCounted`

**职责：**
- 遍历 `scan_paths`（默认 `["res://scenes/prefabs/"]`）
- 递归扫描所有 `.tscn` 文件
- 解析每个文件的元数据：
  - 文件名、路径
  - 从目录结构提取 `category`（一级目录）和 `subcategory`（二级目录）
  - 判断是否引用 `.glb`（读取文件头部 `ext_resource type="PackedScene"` + `.glb` 后缀）
  - 记录 `metadata/source_model_path`（如果存在）
- 支持运行时重新扫描

**数据结构：**
```gdscript
struct PrefabEntry:
    var name: String
    var path: String           # res:// 路径
    var category: String       # 如 "buildings", "models", "terrain"
    var subcategory: String    # 如 "vegetation", "props", "Gate"
    var has_glb: bool
    var scene: PackedScene     # 延迟加载
```

**扫描逻辑细节：**
1. 用 `DirAccess.get_files_at()` 列出目录中所有 `.tscn` 文件
2. 对于每个 `.tscn`，用 `FileAccess.open()` 读前 10-20 行
3. 用正则或字符串匹配定位 `ext_resource type="PackedScene"` 行，检查是否以 `.glb"` 结尾
4. 从路径的目录结构中提取分类信息
5. 缓存结果供面板显示

### 3. AssetBrowserPanel — 底部面板 UI

**场景结构（asset_browser_panel.tscn）：**
```
Control (HBoxContainer)
├── Panel (左侧：预制体列表，size_flags_horizontal=3)
│   ├── HBoxContainer (工具栏)
│   │   ├── LineEdit (搜索栏，placeholder="搜索预制体...")
│   │   ├── OptionButton (分类过滤，items=["全部","buildings","models/vegetation",...])
│   │   └── Button (刷新，icon=刷新图标)
│   ├── ItemList (预制体列表，select_mode=SINGLE)
│   │   └── 每项显示：分类图标 + 名称 + 分类标签 + GLB标识
│   └── Label (统计信息，"共 86 个预制体，显示 86 个")
└── Panel (右侧：预览/操作，size_flags_horizontal=1)
    ├── TextureRect (缩略图占位，后续可加)
    ├── Label (选中预制体名称)
    ├── Label (选中预制体路径)
    └── Button ("放置" — toggle按钮，放置模式时高亮)
```

**面板逻辑（asset_browser_panel.gd）：**
```gdscript
extends Control

signal prefab_selected(path: String)
signal start_placing(path: String)
signal stop_placing()

var scanner: AssetScanner
var all_entries: Array[PrefabEntry]
var filtered_entries: Array[PrefabEntry]

func _on_search_text_changed(text: String):
    # 实时过滤名称，更新列表

func _on_category_filter_selected(index: int):
    # 按分类过滤，更新列表

func _on_prefab_clicked(index: int):
    # 选中，更新右侧预览信息
    emit_signal("prefab_selected", entry.path)

func _on_place_button_toggled(button_pressed: bool):
    if button_pressed:
        emit_signal("start_placing", selected_path)
    else:
        emit_signal("stop_placing")
```

### 4. AssetPlacer — 放置核心

类：`class_name AssetPlacer extends RefCounted`

**状态机：**

```
IDLE → enter_placing_mode() → PLACING
PLACING → 鼠标移动 → 更新 GhostPreview
PLACING → 左键点击 → place_at()
PLACING → 右键/ESC → exit_placing_mode() → IDLE
PLACING → 面板再次点"放置" → exit_placing_mode() → IDLE
```

**核心方法：**

```gdscript
var state: enum {IDLE, PLACING}
var active_prefab_path: String
var ghost: GhostPreview

func enter_placing_mode(prefab_path: String):
    state = PLACING
    active_prefab_path = prefab_path
    ghost = GhostPreview.new()
    ghost.source_scene = load(prefab_path)
    EditorInterface.get_edited_scene_root().add_child(ghost)

func exit_placing_mode():
    state = IDLE
    if ghost:
        ghost.queue_free()
        ghost = null

func handle_input(camera: Camera3D, event: InputEvent) -> int:
    if event is InputEventMouseMotion:
        _update_ghost_position(camera, event.position)
        return EditorPlugin.AFTER_GUI_INPUT_STOP
    
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _place(camera, event.position)
        return EditorPlugin.AFTER_GUI_INPUT_STOP
    
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
        exit_placing_mode()
        return EditorPlugin.AFTER_GUI_INPUT_STOP
    
    return EditorPlugin.AFTER_GUI_INPUT_PASS
```

**射线检测：**
```gdscript
func _raycast(camera: Camera3D, mouse_pos: Vector2) -> Dictionary:
    var space = camera.get_world_3d().direct_space_state
    var origin = camera.project_ray_origin(mouse_pos)
    var normal = camera.project_ray_normal(mouse_pos)
    var query = PhysicsRayQueryParameters3D.create(origin, origin + normal * 1000.0)
    query.exclude = [ghost] if ghost else []
    return space.intersect_ray(query)
```

**实例化：**
```gdscript
func _place(camera: Camera3D, mouse_pos: Vector2):
    var result = _raycast(camera, mouse_pos)
    if result.is_empty():
        return
    
    var prefab = load(active_prefab_path) as PackedScene
    var instance = prefab.instantiate() as Node3D
    instance.global_position = result.position
    
    var root = EditorInterface.get_edited_scene_root()
    root.add_child(instance, true)
    instance.owner = root  # 使实例成为场景持久化的一部分
    
    # 选中新放置的节点
    EditorInterface.get_selection().clear()
    EditorInterface.get_selection().add_node(instance)
```

### 5. GhostPreview — 半透明预览

类：`class_name GhostPreview extends Node3D`

**职责：**
- 在 `source_scene` 首次设置时实例化预制体作为子节点
- 遍历所有 `MeshInstance3D`，对材质应用半透明覆盖
- 提供 `show_at(position, normal)` 和 `hide()` 方法
- 不参与物理碰撞（`query.exclude` 中排除）

**透明处理：**
```gdscript
func _apply_transparency(node: Node, alpha: float):
    for child in node.get_children():
        if child is MeshInstance3D:
            var mat = child.material_override
            if not mat:
                mat = child.mesh.surface_get_material(0).duplicate()
            if mat is BaseMaterial3D:
                mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                mat.albedo_color.a = alpha
                mat.disable_ambient_light = true  # 避免环境光影响预览
            child.material_override = mat
        _apply_transparency(child, alpha)
```

## 配置

扫描目录保存到 `ProjectSettings`：
```gdscript
const SETTING_PREFIX = "addons/asset_placer/"
const SCAN_PATHS_SETTING = SETTING_PREFIX + "scan_paths"

func _init_settings():
    if not ProjectSettings.has_setting(SCAN_PATHS_SETTING):
        ProjectSettings.set_setting(SCAN_PATHS_SETTING, ["res://scenes/prefabs/"])
        ProjectSettings.set_initial_value(SCAN_PATHS_SETTING, ["res://scenes/prefabs/"])
```

面板中的"目录设置"按钮弹出一个窗口，可添加/删除扫描路径。

## 边界情况

| 情况                     | 处理方式                                          |
| ------------------------ | ------------------------------------------------- |
| 没有打开场景             | 放置按钮禁用，提示"请先打开一个场景"              |
| 点击位置没有碰撞体       | 不放置（射线检测失败），无操作                    |
| 选中的预制体被删除了     | 重新扫描时移除，面板刷新                          |
| 同时打开多个编辑场景     | 放置到当前 `get_edited_scene_root()` 所在场景     |
| 放置模式中切换场景       | 退出放置模式，清理 ghost                          |
| 引用了不同引擎版本的场景 | 按 Godot 4.6+ 兼容性处理，`instantiate()` 时会失败则报错 |

## 未来扩展（本期不做）

- 预览缩略图生成
- 随机旋转/缩放选项
- 沿路径放置（批量）
- 放置历史/撤销支持
- 标签/收藏系统

## 实现顺序

1. `plugin.cfg` + `plugin.gd` 骨架（注册底部面板）
2. `AssetScanner` — 扫描目录，解析预制体列表
3. `AssetBrowserPanel` — 底部面板 UI（搜索、过滤、列表）
4. `GhostPreview` — 半透明预览
5. `AssetPlacer` — 放置核心（射线检测、实例化）
6. 集成测试 + 手动验证
