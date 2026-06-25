# 高度图地形导入与生成计划

## Goal

导入用户提供的 `地形高度图.png`，在 Godot 中新增一个可由高度图生成网格的地形预置体，并接入主场景供后续替换灰盒地形使用。

## Scope

- 复制高度图到项目资源目录。
- 新增高度图地形生成脚本，运行时读取灰度高度并生成 `ArrayMesh`。
- 新增高度图地形预置体，默认启用视觉网格，碰撞可配置。
- 在 `Main.tscn` 的 `TerrainContainer` 中实例化高度图地形。
- 增加单元测试覆盖资源、脚本和主场景接入。

## Affected Files

- `assets/textures/terrain/heightmaps/terrain_heightmap.png`
- `scripts/world/HeightmapTerrain.gd`
- `scenes/prefabs/terrain/HeightmapTerrain.tscn`
- `scenes/main/Main.tscn`
- `tests/test_terrain.gd`

## Implementation

- [x] 复制高度图资源到项目内，使用稳定英文文件名，避免资源路径编码问题。
- [x] 实现 `HeightmapTerrain.gd`，支持导出高度图路径、世界尺寸、最大高度、采样步长、碰撞开关。
- [x] 创建 `HeightmapTerrain.tscn`，配置材质、尺度和高度参数。
- [x] 将预置体实例化到 `Main.tscn/TerrainContainer`，保留旧灰盒地形节点。
- [x] 更新 `tests/test_terrain.gd`，验证预置体存在、可实例化、网格可生成、主场景包含节点。
- [x] 运行 Godot 导入、测试和场景校验。

## Verification Results

- `godot --headless --xr-mode off --path . --import` exited 0.
- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` exited 0 with `TESTS PASSED: 923 assertions`.
- `godot --headless --xr-mode off --path . --check-only --quit` exited 0.

Known unrelated headless output remains: Beehave no-debugger messages, existing `TownNpc`/spell effect logs during tests, and invalid UID warnings on some model prefab scenes.

## Verification Criteria

- `godot --headless --xr-mode off --path . --import` 退出 0。
- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` 退出 0，并输出 `TESTS PASSED`。
- `godot --headless --xr-mode off --path . --check-only --quit` 退出 0。
