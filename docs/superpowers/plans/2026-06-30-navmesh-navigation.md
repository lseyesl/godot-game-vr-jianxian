# NavMesh 导航系统 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace direct waypoint NPC movement with NavigationAgent3D pathfinding and add NavMesh coverage for both Terrain3D and TownGround surfaces.

**Architecture:** Two NavigationRegion3D nodes (one for Terrain3D via existing addon, one for TownGround flat surfaces) share the default navigation map. NPCs use NavigationAgent3D for pathfinding while keeping existing behavior tree structure intact. A lightweight editor plugin provides bake workflow.

**Tech Stack:** Godot 4.6, GDScript, NavigationServer3D, NavigationAgent3D, NavigationRegion3D, Terrain3D addon (baker.gd), Beehave

## Global Constraints

- All new scripts `extends RefCounted` for test-only classes
- Scene tree changes must pass `godot --headless --xr-mode off --path . --check-only --quit`
- All new/modified files must have matching `.uid` sidecar operations when moving/renaming
- NPC capsule radius = 0.32, height = 1.55 → NavMesh agent radius = 0.30, height = 1.55
- No `class_name` on headless-test-visible scripts (use `load() + .new()` pattern)
- Terrain3D addon's `baker.gd` must be used for terrain navmesh, NOT reimplemented
- Existing behavior tree structure (selector → 3 sequences) must remain unchanged
- Fallback to direct movement when NavigationAgent3D is unavailable
- Physics layers for navigation: use default layer 0 unless project.godot specifies otherwise
- All tests must pass with `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`
- Pre-existing test failures (61 assertions in `test_town_playability.gd`) are NOT to be fixed

---

### Task 1: Add NavigationRegion3D for Terrain3D

**Files:**
- Modify: `scenes/main/Main.tscn`
- New Resource: `assets/navigation/terrain_navmesh.tres` (NavigationMesh resource)
- Verify: `tests/test_navmesh_setup.gd`

**Interfaces:**
- Consumes: Terrain3D addon `baker.gd` `set_up_navigation()` / `bake_nav_mesh()`
- Produces: `NavigationRegion3D` node wrapping Terrain3D with baked navmesh in Main.tscn

The Terrain3D addon's `baker.gd` provides `set_up_navigation()` which:
1. Creates a `NavigationRegion3D` node
2. Creates a `NavigationMesh` resource on it
3. Reparents Terrain3D under NavigationRegion3D
4. Bakes the navmesh from terrain geometry

We run this in-editor once, then the scene file persists the result.

- [ ] **Step 1: Create navigtion asset directory**

```bash
mkdir -p assets/navigation
```

- [ ] **Step 2: Initialize Terrain3D navigation in editor**

This step is manual (can't be automated via CLI — requires editor). The process:
1. Open project in Godot editor
2. Select `Main/TerrainContainer/Terrain3D` node
3. Click Terrain3D menu → "Set Up Navigation"
4. After setup completes, the scene structure becomes:
   ```
   TerrainContainer
   └── NavigationRegion3D (terrain_nav)
       └── Terrain3D
   ```
5. Save Main.tscn

Resulting Main.tscn diff:
```diff
+[sub_resource type="NavigationMesh" id="NavigationMesh_terrain"]
+cell_size = 0.25
+cell_height = 0.2
+agent_radius = 0.3
+agent_height = 1.55
+agent_max_slope = 45.0
+agent_max_climb = 0.3
+
 [node name="TerrainContainer" type="Node3D"]
-[node name="Terrain3D" type="Terrain3D" parent="TerrainContainer"]
+[node name="NavigationRegion3D" type="NavigationRegion3D" parent="TerrainContainer"]
+navigation_mesh = SubResource("NavigationMesh_terrain")
+
+[node name="Terrain3D" type="Terrain3D" parent="TerrainContainer/NavigationRegion3D"]
```

- [ ] **Step 3: Write test for terrain navigation region**

Create `tests/test_navmesh_setup.gd`:

```gdscript
extends RefCounted

func run(t) -> void:
    # Test that Main.tscn has NavigationRegion3D for terrain
    var scene_path := "res://scenes/main/Main.tscn"
    t.assert_true(ResourceLoader.exists(scene_path), "Main.tscn exists")
    if not ResourceLoader.exists(scene_path):
        return
    var main_scene := load(scene_path) as PackedScene
    t.assert_true(main_scene != null, "Main.tscn is a valid PackedScene")
    if main_scene == null:
        return
    var main := main_scene.instantiate()
    t.assert_true(main != null, "Main.tscn instantiates")
    if main == null:
        return
    
    # Find NavigationRegion3D in TerrainContainer
    var terrain_container := main.get_node_or_null("TerrainContainer") as Node3D
    t.assert_true(terrain_container != null, "TerrainContainer exists")
    if terrain_container == null:
        main.free()
        return
    
    var nav_regions: Array = []
    for child in terrain_container.get_children():
        if child is NavigationRegion3D:
            nav_regions.append(child)
    t.assert_true(nav_regions.size() >= 1, "TerrainContainer has at least 1 NavigationRegion3D")
    
    if nav_regions.size() > 0:
        var nav_region := nav_regions[0] as NavigationRegion3D
        t.assert_true(nav_region.navigation_mesh != null, "NavigationRegion3D has navigation_mesh")
        if nav_region.navigation_mesh:
            t.assert_equal(nav_region.navigation_mesh.agent_radius, 0.3, "NavMesh agent_radius is 0.3")
            t.assert_equal(nav_region.navigation_mesh.agent_height, 1.55, "NavMesh agent_height is 1.55")
    
    main.free()
```

- [ ] **Step 4: Register test in test runner**

Read `tests/test_runner.gd` and add `"res://tests/test_navmesh_setup.gd"` to the `test_paths` array.

- [ ] **Step 5: Run validation**

```bash
godot --headless --xr-mode off --path . --check-only --quit
```
Expected: exit 0

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```
Expected: TESTS PASSED (with pre-existing + new assertions)

- [ ] **Step 6: Commit**

```bash
git add tests/test_navmesh_setup.gd tests/test_navmesh_setup.gd.uid assets/navigation/ tests/test_runner.gd scenes/main/Main.tscn scenes/main/Main.tscn.uid
git commit -m "feat: add NavigationRegion3D for Terrain3D with baked NavMesh"
```

---

### Task 2: Add NavigationRegion3D for TownGround

**Files:**
- Modify: `scenes/town/Town.tscn`
- New Resource: `assets/navigation/town_ground_navmesh.tres` (NavigationMesh resource)
- Test: Update `tests/test_navmesh_setup.gd`

**Interfaces:**
- Consumes: TownGround static geometry (StaticBody3D mesh instances)
- Produces: NavigationRegion3D covering town walkable area

TownGround uses `GROUPS_WITH_CHILDREN` source mode so we add TownGround nodes to `"nav_geometry"` group.

- [ ] **Step 1: Create NavigationMesh resource file**

Create `assets/navigation/town_ground_navmesh.tres`:
```gdscript
[NavigationMesh resource]
cell_size = 0.2
cell_height = 0.15
agent_radius = 0.3
agent_height = 1.55
agent_max_slope = 30.0
agent_max_climb = 0.15
region_min_size = 1.0
region_merge_size = 4.0
edge_max_length = 3.0
edge_max_error = 0.2
geometry_source_geometry_mode = 2
geometry_source_group_name = "nav_geometry"
```

This is an external `.tres` resource so it can be reused/referenced.

- [ ] **Step 2: Add NavigationRegion3D to Town.tscn**

Add the following to Town.tscn (after TownGround nodes):

```diff
+[ext_resource type="NavigationMesh" uid="uid://new_uid" path="res://assets/navigation/town_ground_navmesh.tres" id="32_nav"]
+
+[node name="TownGroundNav" type="NavigationRegion3D" parent="Town"]
+transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
+navigation_mesh = ExtResource("32_nav")
+
 [node name="TownGround" type="StaticBody3D" parent="Town"]
```

The TownGround StaticBody3D should be added to `"nav_geometry"` group so the NavigationRegion3D can find it.

For the specific TownGround nodes:
- `Town/Ground/Mesh_01` through `Mesh_04` (the actual mesh instances) need to be in `nav_geometry` group
- Or add the parent `TownGround` StaticBody3D to the group

The NavigationRegion3D will parse geometry from group members when baking. In the editor, use the "Bake NavMesh" button after adding the node.

- [ ] **Step 3: Update test to check Town NavigationRegion3D**

Add to `tests/test_navmesh_setup.gd`:

```gdscript
func run(t) -> void:
    # ... existing terrain test ...
    
    # Test Town.tscn has NavigationRegion3D
    var town_path := "res://scenes/town/Town.tscn"
    if not ResourceLoader.exists(town_path):
        return
    var town_scene := load(town_path) as PackedScene
    if town_scene == null:
        return
    var town := town_scene.instantiate()
    if town == null:
        return
    
    var ground_nav := town.get_node_or_null("TownGroundNav") as NavigationRegion3D
    t.assert_true(ground_nav != null, "Town has TownGroundNav NavigationRegion3D")
    if ground_nav:
        t.assert_true(ground_nav.navigation_mesh != null, "TownGroundNav has navigation_mesh")
        if ground_nav.navigation_mesh:
            t.assert_equal(ground_nav.navigation_mesh.agent_radius, 0.3, "Town navmesh agent_radius is 0.3")
    
    town.free()
```

- [ ] **Step 4: Run validation**

```bash
godot --headless --xr-mode off --path . --check-only --quit
```
Expected: exit 0

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```
Expected: TESTS PASSED

- [ ] **Step 5: Commit**

```bash
git add assets/navigation/town_ground_navmesh.tres scenes/town/Town.tscn scenes/town/Town.tscn.uid tests/test_navmesh_setup.gd tests/test_navmesh_setup.gd.uid
git commit -m "feat: add NavigationRegion3D for TownGround with NavMesh"
```

---

### Task 3: Add NavigationAgent3D to TownNpc scene

**Files:**
- Modify: `scenes/npc/TownNpc.tscn`
- Test: `tests/test_town_npc.gd` (update)

**Interfaces:**
- Produces: TownNpc scene with NavigationAgent3D node added as child
- Consumed by: TownNpc.gd in Task 4

- [ ] **Step 1: Add NavigationAgent3D node to TownNpc.tscn**

```diff
+[sub_resource type="NavigationMesh" id="NavigationMesh_npc_dummy"]
+cell_size = 0.2
+cell_height = 0.15
+agent_radius = 0.3
+agent_height = 1.55
+agent_max_slope = 45.0
+agent_max_climb = 0.3
+
 [node name="TownNpc" type="CharacterBody3D"]
 script = ExtResource("1")
 
+[node name="NavigationAgent3D" type="NavigationAgent3D" parent="."]
+radius = 0.3
+height = 1.55
+max_speed = 1.0
+
 [node name="CollisionShape3D" type="CollisionShape3D" parent="."]
 position = Vector3(0, 0.775, 0)
 shape = SubResource("CapsuleShape3D_1")
```

Note: NavigationAgent3D doesn't need its own NavigationMesh resource — it uses the navigation map from the world automatically when inside the scene tree.

- [ ] **Step 2: Update test to verify NavigationAgent3D exists**

In `tests/test_town_npc.gd`, add to `_test_town_npc_scene`:

```gdscript
# Verify NavigationAgent3D exists
var nav_agent := scene.get_node_or_null("NavigationAgent3D")
t.assert_true(nav_agent != null, "TownNpc has NavigationAgent3D node")
if nav_agent:
    # Check it's the right type using duck typing
    t.assert_true(nav_agent.get("radius") != null, "NavigationAgent3D has radius property")
    t.assert_equal(nav_agent.radius, 0.3, "NavigationAgent3D radius is 0.3")
    t.assert_equal(nav_agent.max_speed, 1.0, "NavigationAgent3D max_speed is 1.0")
```

- [ ] **Step 3: Run validation**

```bash
godot --headless --xr-mode off --path . --check-only --quit
```
Expected: exit 0

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```
Expected: TESTS PASSED

- [ ] **Step 4: Commit**

```bash
git add scenes/npc/TownNpc.tscn scenes/npc/TownNpc.tscn.uid tests/test_town_npc.gd tests/test_town_npc.gd.uid
git commit -m "feat: add NavigationAgent3D node to TownNpc scene"
```

---

### Task 4: Rewrite TownNpc navigation methods for NavigationAgent3D

**Files:**
- Modify: `scripts/npc/TownNpc.gd`
- Test: `tests/test_town_npc.gd` (add tests)

**Interfaces:**
- Consumes: `NavigationAgent3D` node from scene (Task 3)
- Produces: `move_to_next_waypoint(delta) -> bool`, `is_at_waypoint() -> bool` using NavAgent
- Consumed by: MoveToWaypointAction.gd (Task 5), IsAtWaypointCondition.gd (Task 5)

- [ ] **Step 1: Read current TownNpc.gd**

It's already loaded from earlier read. Current movement code is in `move_to_next_waypoint()` (lines 71-88) and `is_at_waypoint()` (lines 90-97).

- [ ] **Step 2: Rewrite TownNpc.gd**

```gdscript
extends CharacterBody3D
class_name TownNpc

@export var npc_role := "pedestrian"
@export var move_speed_mps := 1.0
@export var player_sense_radius_m := 2.5
@export var wait_duration_s := 1.5
@export var waypoints: Array[Vector3] = []

var current_waypoint_index := 0
var last_spoken_line := ""
var nearby_player: Node3D
var wait_remaining_s := 0.0

# NavigationAgent3D — may be null in tests
var _nav_agent: NavigationAgent3D
var _nav_target_reached := false


func _ready() -> void:
    var tree := $BehaviorTree as BeehaveTree
    if tree != null:
        tree.process_thread = BeehaveTree.ProcessThread.MANUAL
    if waypoints.is_empty():
        waypoints = [Vector3.ZERO]
    
    _nav_agent = $NavigationAgent3D as NavigationAgent3D
    if _nav_agent:
        _nav_agent.max_speed = move_speed_mps
        _nav_agent.target_reached.connect(_on_nav_target_reached)


func _physics_process(delta: float) -> void:
    var tree := $BehaviorTree as BeehaveTree
    if tree != null and tree.enabled:
        tree.blackboard.set_value("delta", delta, str(get_instance_id()))
        tree.tick()
    
    # Continuous navigation velocity update
    _update_nav_velocity()


func _update_nav_velocity() -> void:
    if _nav_agent == null:
        return
    if _nav_agent.is_navigation_finished():
        return
    var next_pos := _nav_agent.get_next_path_position()
    var current_pos := global_position
    var direction := (next_pos - current_pos).normalized()
    direction.y = 0.0
    velocity = direction * move_speed_mps
    move_and_slide()


func _on_nav_target_reached() -> void:
    _nav_target_reached = true
    velocity = Vector3.ZERO


func move_to_next_waypoint(delta: float) -> bool:
    if waypoints.is_empty():
        velocity = Vector3.ZERO
        return false
    
    if _nav_agent == null:
        return _legacy_move_to_next_waypoint(delta)
    
    if _nav_agent.is_navigation_finished() and not _nav_target_reached:
        # This frame, navigation just finished (before signal)
        _nav_target_reached = true
        velocity = Vector3.ZERO
        return true
    
    if not _nav_target_reached:
        # Still navigating
        return true
    
    # Target reached — advance waypoint happens in WaitAtWaypointAction
    # Return true (actor is "moving" in the sense that it has reached target)
    return true


func is_at_waypoint() -> bool:
    if _nav_agent == null:
        return _legacy_is_at_waypoint()
    return _nav_target_reached


# Legacy direct movement (fallback when NavigationAgent3D not available)
func _legacy_move_to_next_waypoint(delta: float) -> bool:
    if waypoints.is_empty():
        velocity = Vector3.ZERO
        return false
    var target: Vector3 = waypoints[current_waypoint_index]
    var current := global_position if is_inside_tree() else position
    var offset: Vector3 = target - current
    offset.y = 0.0
    if offset.length() <= 0.05:
        velocity = Vector3.ZERO
        return true
    var step: Vector3 = offset.normalized() * move_speed_mps
    velocity = step
    if is_inside_tree():
        move_and_slide()
    else:
        position += step * delta
    return true


func _legacy_is_at_waypoint() -> bool:
    if waypoints.is_empty():
        return true
    var current := global_position if is_inside_tree() else position
    var target: Vector3 = waypoints[current_waypoint_index]
    current.y = 0.0
    target.y = 0.0
    return current.distance_to(target) <= 0.1


# Remaining methods unchanged below:
func advance_waypoint() -> void:
    if not waypoints.is_empty():
        current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()

func start_waiting() -> void:
    wait_remaining_s = wait_duration_s

func tick_wait(delta: float) -> bool:
    wait_remaining_s = maxf(0.0, wait_remaining_s - delta)
    if wait_remaining_s <= 0.0:
        advance_waypoint()
        _nav_target_reached = false  # Reset for next waypoint
        return false
    return true

func look_at_player() -> bool:
    if not has_nearby_player():
        return false
    var target := nearby_player.global_position if nearby_player.is_inside_tree() else nearby_player.position
    var current := global_position if is_inside_tree() else position
    target.y = current.y
    if current.distance_to(target) <= 0.01:
        return false
    look_at(target, Vector3.UP)
    return true

func line_for_role() -> String:
    var lines: Array = LINES.get(npc_role, LINES["pedestrian"])
    if lines.is_empty():
        return ""
    var index := absi(hash(npc_role)) % lines.size()
    return lines[index]

func speak_context_line() -> String:
    last_spoken_line = line_for_role()
    return last_spoken_line

func set_nearby_player(player: Node) -> void:
    if player is Node3D and player.is_in_group("player"):
        nearby_player = player

func clear_nearby_player(player: Node) -> void:
    if player == nearby_player:
        nearby_player = null

func has_nearby_player() -> bool:
    return nearby_player != null and is_instance_valid(nearby_player)

func _on_sense_area_body_entered(body: Node3D) -> void:
    set_nearby_player(body)

func _on_sense_area_body_exited(body: Node3D) -> void:
    clear_nearby_player(body)

const LINES := {
    "vendor": [
        "新摘的灵草，熬汤最养气。",
        "少侠慢走，摊上的符纸都压过香灰。",
    ],
    "inn_owner": [
        "客栈还有热茶，出镇前歇一口气。",
        "昨夜剑光从屋脊掠过，镇里人都看见了。",
    ],
    "tavern_owner": [
        "山风带妖气，酒也压不住。",
        "听说北边旧祭台又亮了。",
    ],
    "pedestrian": [
        "今天集市比往常热闹。",
        "有人说山里传来钟声。",
    ],
}
```

- [ ] **Step 3: Add tests for NavigationAgent3D integration**

In `tests/test_town_npc.gd`, add after `_test_beehave_tree_ticks`:

```gdscript
func _test_nav_agent_integration(t) -> void:
    # Test that NavigationAgent3D is accessible from script
    var TownNpc := load("res://scripts/npc/TownNpc.gd")
    if not TownNpc.can_instantiate():
        return
    
    var npc = TownNpc.new()
    # Without nav agent in scene tree, should use fallback
    npc.waypoints = [Vector3.ZERO, Vector3(2, 0, 0)]
    npc.current_waypoint_index = 1
    npc.position = Vector3.ZERO
    t.assert_true(npc.move_to_next_waypoint(0.5), "Fallback move works without NavAgent")
    t.assert_true(npc.position.x > 0.0, "Fallback advances position")
    
    # Test is_at_waypoint fallback
    npc.position = Vector3(2, 0, 0)
    t.assert_true(npc.is_at_waypoint(), "Fallback is_at_waypoint true at target")
    npc.free()
    
    # Test state machine integration
    var walker = TownNpc.new()
    walker.waypoints = [Vector3.ZERO, Vector3(5, 0, 0)]
    walker._nav_target_reached = true  # Simulate NavAgent reaching target
    walker.current_waypoint_index = 1
    t.assert_true(walker.is_at_waypoint(), "is_at_waypoint returns true when _nav_target_reached")
    
    walker._nav_target_reached = false
    t.assert_false(walker.is_at_waypoint(), "is_at_waypoint returns false when target not reached")
    
    # Test tick_wait resets nav target reached
    walker._nav_target_reached = true
    walker.wait_remaining_s = 0.0
    walker.start_waiting()
    walker.tick_wait(1.6)  # Wait completes (1.5s default)
    t.assert_false(walker._nav_target_reached, "_nav_target_reached is reset after wait completes")
    walker.free()
```

- [ ] **Step 4: Run validation**

```bash
godot --headless --xr-mode off --path . --check-only --quit
```
Expected: exit 0

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```
Expected: TESTS PASSED

- [ ] **Step 5: Commit**

```bash
git add scripts/npc/TownNpc.gd scripts/npc/TownNpc.gd.uid tests/test_town_npc.gd tests/test_town_npc.gd.uid
git commit -m "refactor: migrate TownNpc navigation to NavigationAgent3D with fallback"
```

---

### Task 5: Update MoveToWaypointAction and IsAtWaypointCondition

**Files:**
- Modify: `scripts/npc/ai/MoveToWaypointAction.gd`
- Modify: `scripts/npc/ai/IsAtWaypointCondition.gd`
- No change: `WaitAtWaypointAction.gd` (wait logic unchanged)

**Interfaces:**
- Consumes: TownNpc's `move_to_next_waypoint()`, `is_at_waypoint()` (Task 4)
- Produces: Updated behavior tree leaf scripts

- [ ] **Step 1: Review current MoveToWaypointAction.gd**

Already read. Current code:
```gdscript
extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
    var delta: float = blackboard.get_value("delta", 0.016)
    if actor.has_method("move_to_next_waypoint") and actor.move_to_next_waypoint(delta):
        return RUNNING
    return FAILURE
```

- [ ] **Step 2: Update MoveToWaypointAction.gd**

The `move_to_next_waypoint()` signature hasn't changed — it still returns bool, still takes delta. The internal implementation changed in Task 4. So **no code change is actually needed** for this file. Verify:

The behavior:
- `move_to_next_waypoint` returns `true` → moving or reached → `RUNNING`
- `move_to_next_waypoint` returns `false` → failed → `FAILURE`

With the new implementation:
- Moving toward waypoint → returns true → `RUNNING` ✓
- Reached waypoint → returns true → `RUNNING` (next tick, IsAtWaypointCondition sees target reached, WaitBranch starts waiting) ✓
- No waypoints → returns false → `FAILURE` ✓

The interface is compatible. Mark this as verified-no-change-needed.

- [ ] **Step 3: Review IsAtWaypointCondition.gd**

Current code:
```gdscript
extends "res://addons/beehave/nodes/leaves/condition.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
    if actor.has_method("is_at_waypoint") and actor.is_at_waypoint():
        return SUCCESS
    return FAILURE
```

Same analysis — `is_at_waypoint()` signature unchanged. **No code change needed.** Verify only.

- [ ] **Step 4: Write test for behavior tree + NavAgent interaction**

Add test to verify MoveToWaypointAction calls actor's method:

```gdscript
func _test_behavior_tree_nav_integration(t) -> void:
    var Action := load("res://scripts/npc/ai/MoveToWaypointAction.gd")
    t.assert_true(Action.can_instantiate(), "MoveToWaypointAction can instantiate")
    if not Action.can_instantiate():
        return
    
    var action = Action.new()
    var TownNpc := load("res://scripts/npc/TownNpc.gd")
    if not TownNpc.can_instantiate():
        action.free()
        return
    
    var mock_actor = TownNpc.new()
    mock_actor.waypoints = [Vector3.ZERO, Vector3(1, 0, 0)]
    mock_actor.current_waypoint_index = 1
    
    var bb := Blackboard.new()
    bb.set_value("delta", 0.016, str(mock_actor.get_instance_id()))
    
    # Call tick - should return RUNNING (moving toward waypoint)
    var result := action.tick(mock_actor, bb)
    t.assert_equal(result, 1, "MoveToWaypointAction returns RUNNING while moving")  # 1 = RUNNING
    
    mock_actor.free()
    action.free()
    
    # Test IsAtWaypointCondition
    var Condition := load("res://scripts/npc/ai/IsAtWaypointCondition.gd")
    t.assert_true(Condition.can_instantiate(), "IsAtWaypointCondition can instantiate")
    if not Condition.can_instantiate():
        return
    
    var condition = Condition.new()
    var waiting_actor = TownNpc.new()
    waiting_actor._nav_target_reached = false
    
    var bb2 := Blackboard.new()
    bb2.set_value("delta", 0.016, str(waiting_actor.get_instance_id()))
    
    result = condition.tick(waiting_actor, bb2)
    t.assert_equal(result, 0, "IsAtWaypointCondition returns FAILURE when target not reached")  # 0 = FAILURE
    
    waiting_actor._nav_target_reached = true
    result = condition.tick(waiting_actor, bb2)
    t.assert_equal(result, 2, "IsAtWaypointCondition returns SUCCESS when target reached")  # 2 = SUCCESS
    
    waiting_actor.free()
    condition.free()
```

- [ ] **Step 5: Run validation**

```bash
godot --headless --xr-mode off --path . --check-only --quit
```
Expected: exit 0

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```
Expected: TESTS PASSED

- [ ] **Step 6: Commit**

```bash
git add tests/test_town_npc.gd tests/test_town_npc.gd.uid
git commit -m "test: verify behavior tree leaf nodes compatible with NavAgent navigation"
```

---

### Task 6: NavMesh Workflow Editor Plugin

**Files:**
- Create: `addons/navmesh_workflow/plugin.cfg`
- Create: `addons/navmesh_workflow/plugin.gd`
- Create: `addons/navmesh_workflow/icons/icon.png` (16x16 placeholder)
- Create: `addons/navmesh_workflow/panels/workflow_panel.tscn`
- Create: `addons/navmesh_workflow/panels/workflow_panel.gd`
- Create: `tests/test_navmesh_workflow.gd`

**Interfaces:**
- Consumes: `NavigationRegion3D` nodes in scene, Terrain3D addon `baker.gd`
- Produces: Bottom panel with bake workflow controls

- [ ] **Step 1: Create plugin scaffolding**

`addons/navmesh_workflow/plugin.cfg`:
```ini
[plugin]
name="NavMesh Workflow"
description="One-click NavMesh setup, baking, and coverage visualization for Terrain3D and TownGround"
author="Internal"
version="0.1"
```

`addons/navmesh_workflow/plugin.gd`:
```gdscript
@tool
extends EditorPlugin

const PANEL_NAME := "NavMesh Workflow"
var bottom_panel: Control
var workflow_panel: Control


func _enter_tree() -> void:
    var panel_scene := load("res://addons/navmesh_workflow/panels/workflow_panel.tscn") as PackedScene
    if panel_scene == null:
        push_error("NavMeshWorkflow: failed to load panel scene")
        return
    bottom_panel = panel_scene.instantiate() as Control
    if bottom_panel == null:
        push_error("NavMeshWorkflow: panel scene root is not a Control")
        return
    workflow_panel = bottom_panel
    add_control_to_bottom_panel(bottom_panel, PANEL_NAME)


func _exit_tree() -> void:
    if bottom_panel:
        remove_control_from_bottom_panel(bottom_panel)
        bottom_panel.queue_free()
        bottom_panel = null
        workflow_panel = null
```

Placeholder icon: create a minimal 16x16 PNG (solid cyan square is sufficient).

- [ ] **Step 2: Create workflow panel scene**

`addons/navmesh_workflow/panels/workflow_panel.tscn`:
```
[gd_scene format=3]

[node name="WorkflowPanel" type="VBoxContainer"]
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Title" type="Label" parent="."]
text = " NavMesh Workflow"
theme_type_variation = "HeaderSmall"

[node name="TerrainSection" type="VBoxContainer" parent="."]
[node name="TerrainLabel" type="Label" parent="TerrainSection"]
text = "🏔 Terrain3D Navigation"

[node name="TerrainSetupBtn" type="Button" parent="TerrainSection"]
text = "🔧 Setup Terrain NavMesh"
[node name="TerrainBakeBtn" type="Button" parent="TerrainSection"]
text = "🔄 Bake Terrain NavMesh"
[node name="TerrainStatus" type="Label" parent="TerrainSection"]
text = "Status: --"

[node name="TownSection" type="VBoxContainer" parent="."]
[node name="TownLabel" type="Label" parent="TownSection"]
text = "🏘 Town Ground Navigation"

[node name="TownSetupBtn" type="Button" parent="TownSection"]
text = "🔧 Setup Ground NavMesh"
[node name="TownBakeBtn" type="Button" parent="TownSection"]
text = "🔄 Bake Ground NavMesh"
[node name="TownStatus" type="Label" parent="TownSection"]
text = "Status: --"

[node name="GlobalSection" type="VBoxContainer" parent="."]

[node name="BakeAllBtn" type="Button" parent="GlobalSection"]
text = "🔥 Bake All Navigation Regions"
custom_minimum_size = Vector2(0, 40)

[node name="LastBakedLabel" type="Label" parent="GlobalSection"]
text = "Last baked: --"
```

- [ ] **Step 3: Create workflow panel script**

`addons/navmesh_workflow/panels/workflow_panel.gd`:
```gdscript
@tool
extends VBoxContainer

@onready var terrain_setup_btn: Button = %TerrainSetupBtn
@onready var terrain_bake_btn: Button = %TerrainBakeBtn
@onready var terrain_status: Label = %TerrainStatus
@onready var town_setup_btn: Button = %TownSetupBtn
@onready var town_bake_btn: Button = %TownBakeBtn
@onready var town_status: Label = %TownStatus
@onready var bake_all_btn: Button = %BakeAllBtn
@onready var last_baked_label: Label = %LastBakedLabel


func _ready() -> void:
    terrain_setup_btn.pressed.connect(_on_terrain_setup)
    terrain_bake_btn.pressed.connect(_on_terrain_bake)
    town_setup_btn.pressed.connect(_on_town_setup)
    town_bake_btn.pressed.connect(_on_town_bake)
    bake_all_btn.pressed.connect(_on_bake_all)
    refresh_status()


func refresh_status() -> void:
    var root := EditorInterface.get_edited_scene_root()
    if root == null:
        _set_status("--", "--")
        return
    
    var terrain_nav := _find_nav_region(root, func(n): return n.get_child_count() > 0 and n.get_child(0) is Terrain3D)
    var town_nav := _find_nav_region_by_name(root, "TownGroundNav")
    
    _set_status(
        _nav_status_text(terrain_nav),
        _nav_status_text(town_nav)
    )


func _set_status(terrain_text: String, town_text: String) -> void:
    terrain_status.text = "Status: " + terrain_text
    town_status.text = "Status: " + town_text


func _nav_status_text(nav: NavigationRegion3D) -> String:
    if nav == null:
        return "❌ Not set up"
    if nav.navigation_mesh == null:
        return "⚠️ No navmesh resource"
    var poly_count := nav.navigation_mesh.get_polygon_count()
    return "✅ %d polygons" % poly_count


func _find_nav_region(root: Node, filter: Callable) -> NavigationRegion3D:
    for child in root.find_children("", "NavigationRegion3D", true, true):
        if filter.call(child):
            return child as NavigationRegion3D
    return null


func _find_nav_region_by_name(root: Node, name: String) -> NavigationRegion3D:
    return root.get_node_or_null(NodePath(name)) as NavigationRegion3D


func _on_terrain_setup() -> void:
    var terrain := _find_terrain3d()
    if terrain == null:
        push_error("NavMeshWorkflow: No Terrain3D found in scene")
        return
    # Trigger the Terrain3D addon's set_up_navigation workflow
    terrain_setup_btn.disabled = true
    terrain_setup_btn.text = "⏳ Setup requires editor..."


func _find_terrain3d() -> Terrain3D:
    var root := EditorInterface.get_edited_scene_root()
    if root == null:
        return null
    for child in root.find_children("", "Terrain3D", true, true):
        return child as Terrain3D
    return null


func _on_terrain_bake() -> void:
    var root := EditorInterface.get_edited_scene_root()
    if root == null:
        return
    var terrain_nav := _find_nav_region(root, func(n): return n.get_child_count() > 0 and n.get_child(0) is Terrain3D)
    if terrain_nav == null:
        push_error("NavMeshWorkflow: Terrain NavigationRegion3D not found. Run Setup first.")
        return
    _bake_region(terrain_nav, "Terrain3D")


func _on_town_setup() -> void:
    var root := EditorInterface.get_edited_scene_root()
    if root == null:
        return
    # Check if already exists
    var existing := _find_nav_region_by_name(root, "TownGroundNav")
    if existing != null:
        push_warning("NavMeshWorkflow: TownGroundNav already exists. Use Bake instead.")
        return
    
    # Create NavigationRegion3D for town ground
    var town := root.get_node_or_null(NodePath("Town"))
    if town == null:
        push_error("NavMeshWorkflow: Town node not found in Main.tscn")
        return
    
    var nav_region := NavigationRegion3D.new()
    nav_region.name = "TownGroundNav"
    nav_region.navigation_mesh = NavigationMesh.new()
    nav_region.navigation_mesh.agent_radius = 0.3
    nav_region.navigation_mesh.agent_height = 1.55
    nav_region.navigation_mesh.agent_max_slope = 30.0
    nav_region.navigation_mesh.agent_max_climb = 0.15
    nav_region.navigation_mesh.cell_size = 0.2
    nav_region.navigation_mesh.cell_height = 0.15
    nav_region.navigation_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
    
    town.add_child(nav_region, true)
    nav_region.owner = EditorInterface.get_edited_scene_root()
    refresh_status()


func _on_town_bake() -> void:
    var root := EditorInterface.get_edited_scene_root()
    if root == null:
        return
    var town_nav := _find_nav_region_by_name(root, "TownGroundNav")
    if town_nav == null:
        push_error("NavMeshWorkflow: TownGroundNav not found. Run Setup first.")
        return
    _bake_region(town_nav, "TownGround")


func _on_bake_all() -> void:
    var root := EditorInterface.get_edited_scene_root()
    if root == null:
        return
    var baked_count := 0
    for child in root.find_children("", "NavigationRegion3D", true, true):
        var nav := child as NavigationRegion3D
        if nav != null and nav.navigation_mesh != null:
            _bake_region_internal(nav)
            baked_count += 1
    if baked_count > 0:
        var time_str := Time.get_datetime_string_from_system()
        last_baked_label.text = "Last baked: " + time_str
    refresh_status()


func _bake_region(nav: NavigationRegion3D, label: String) -> void:
    _bake_region_internal(nav)
    last_baked_label.text = "Last baked: " + Time.get_datetime_string_from_system()
    refresh_status()


func _bake_region_internal(nav: NavigationRegion3D) -> void:
    if nav.navigation_mesh == null:
        push_error("NavMeshWorkflow: NavigationRegion3D has no NavigationMesh")
        return
    var source_geo := NavigationMeshSourceGeometryData3D.new()
    NavigationServer3D.parse_source_geometry_data(nav.navigation_mesh, source_geo, nav)
    NavigationServer3D.bake_from_source_geometry_data(nav.navigation_mesh, source_geo)
    
    # Force debug update
    nav.set_navigation_mesh(null)
    nav.set_navigation_mesh(nav.navigation_mesh)
    
    # Save external resource
    if not nav.navigation_mesh.resource_path.is_empty():
        ResourceSaver.save(nav.navigation_mesh, nav.navigation_mesh.resource_path)
```

- [ ] **Step 4: Create test for editor plugin**

`tests/test_navmesh_workflow.gd`:
```gdscript
extends RefCounted

func run(t) -> void:
    var plugin_path := "res://addons/navmesh_workflow/plugin.cfg"
    t.assert_true(FileAccess.file_exists(plugin_path), "NavMesh workflow plugin.cfg exists")
    
    var plugin_script_path := "res://addons/navmesh_workflow/plugin.gd"
    t.assert_true(FileAccess.file_exists(plugin_script_path), "NavMesh workflow plugin.gd exists")
    
    var plugin_script := load(plugin_script_path)
    t.assert_true(plugin_script != null, "plugin.gd loads")
    # Can't instantiate EditorPlugin in headless — just verify script loads
    
    var panel_scene_path := "res://addons/navmesh_workflow/panels/workflow_panel.tscn"
    t.assert_true(ResourceLoader.exists(panel_scene_path), "Workflow panel scene exists")
    if ResourceLoader.exists(panel_scene_path):
        var panel_scene := load(panel_scene_path) as PackedScene
        t.assert_true(panel_scene is PackedScene, "Workflow panel scene is valid PackedScene")
        if panel_scene is PackedScene:
            var panel := panel_scene.instantiate()
            t.assert_true(panel != null, "Workflow panel instantiates")
            if panel:
                t.assert_true(panel is Control, "Workflow panel root is Control")
                panel.free()
    
    var panel_script_path := "res://addons/navmesh_workflow/panels/workflow_panel.gd"
    t.assert_true(FileAccess.file_exists(panel_script_path), "Workflow panel script exists")
    var panel_script := load(panel_script_path)
    t.assert_true(panel_script != null, "Workflow panel script loads")
```

Register in test_runner.gd: add `"res://tests/test_navmesh_workflow.gd"`.

- [ ] **Step 5: Run validation**

```bash
godot --headless --xr-mode off --path . --check-only --quit
```
Expected: exit 0

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```
Expected: TESTS PASSED

- [ ] **Step 6: Commit**

```bash
git add addons/navmesh_workflow/ \
       tests/test_navmesh_workflow.gd tests/test_navmesh_workflow.gd.uid \
       tests/test_runner.gd
git commit -m "feat: add NavMesh Workflow editor plugin for bake coverage management"
```

---

### Task 7: Final Integration & Verification

- [ ] **Step 1: Verify all tests pass**

```bash
godot --headless --xr-mode off --path . --check-only --quit && echo "CHECK OK"
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd && echo "TESTS OK"
```

- [ ] **Step 2: Verify scene structure integrity**

```bash
# Check NavigationRegion3D nodes exist
grep -r "NavigationRegion3D" scenes/ --include="*.tscn"
```

Expected output shows:
- `scenes/main/Main.tscn` has NavigationRegion3D in TerrainContainer
- `scenes/town/Town.tscn` has TownGroundNav NavigationRegion3D

- [ ] **Step 3: Commit if any fixes were made**

```bash
git add -A
git commit -m "fix: integration fixes from final verification"
```
