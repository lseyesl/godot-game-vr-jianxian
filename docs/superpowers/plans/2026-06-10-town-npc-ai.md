# Town NPC AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Beehave-driven ambient town NPC AI for vendors, inn owner, tavern owner, and pedestrians while preserving existing quest NPC behavior.

**Architecture:** Add a reusable `TownNpc` script with testable role, sensing, speech, waiting, and waypoint movement methods. Add thin Beehave action/condition leaf scripts that call the actor API. Wire reusable `TownNpc.tscn` instances into `Town.tscn` under `TownNpcGroup`, keeping `Inn/Innkeeper` and `Tavern/TavernKeeper` unchanged.

**Tech Stack:** Godot 4.6+, GDScript, Beehave, `.tscn` scenes, headless Godot tests.

---

## File Structure

- Create: `scripts/npc/TownNpc.gd`
  - Reusable ambient NPC behavior script, autoload-safe, testable without scene tree dependencies.
- Create: `scripts/npc/ai/HasNearbyPlayerCondition.gd`
  - Beehave condition that succeeds when the actor has a nearby player.
- Create: `scripts/npc/ai/IsAtWaypointCondition.gd`
  - Beehave condition that succeeds when the actor is at its current waypoint.
- Create: `scripts/npc/ai/MoveToWaypointAction.gd`
  - Beehave action that moves the actor toward its current waypoint.
- Create: `scripts/npc/ai/WaitAtWaypointAction.gd`
  - Beehave action that ticks the actor's wait timer.
- Create: `scripts/npc/ai/LookAtPlayerAction.gd`
  - Beehave action that rotates the actor toward the nearby player.
- Create: `scripts/npc/ai/SpeakAmbientLineAction.gd`
  - Beehave action that records one role-specific ambient line.
- Create: `scenes/npc/TownNpc.tscn`
  - Reusable CharacterBody3D scene with mesh, collision, sense area, and Beehave tree.
- Create: `tests/test_town_npc.gd`
  - Unit tests for role lines, sensing, speech, waypoint movement, and wait timer behavior.
- Modify: `tests/test_runner.gd`
  - Add `res://tests/test_town_npc.gd`.
- Modify: `tests/test_town_showcase.gd`
  - Assert `TownNpcGroup` and representative role nodes exist while quest NPC IDs remain unchanged.
- Modify: `scenes/town/Town.tscn`
  - Add `TownNpc.tscn` as an ext_resource and place representative ambient NPC instances.

## Task 1: Failing Core TownNpc Tests

**Files:**
- Create: `tests/test_town_npc.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Write the failing test file**

Create `tests/test_town_npc.gd`:

```gdscript
extends RefCounted

func run(t) -> void:
	var path := "res://scripts/npc/TownNpc.gd"
	t.assert_true(FileAccess.file_exists(path), "TownNpc script exists")
	if not FileAccess.file_exists(path):
		return
	var TownNpc := load(path)
	t.assert_true(TownNpc.can_instantiate(), "TownNpc can instantiate")
	if not TownNpc.can_instantiate():
		return

	var vendor = TownNpc.new()
	vendor.npc_role = "vendor"
	t.assert_true(vendor.line_for_role().contains("灵草") or vendor.line_for_role().contains("符纸"), "vendor has market ambient line")
	t.assert_equal(vendor.speak_context_line(), vendor.last_spoken_line, "speaking records last spoken line")

	var inn_owner = TownNpc.new()
	inn_owner.npc_role = "inn_owner"
	t.assert_true(inn_owner.line_for_role().contains("客栈") or inn_owner.line_for_role().contains("剑光"), "inn owner has inn ambient line")

	var tavern_owner = TownNpc.new()
	tavern_owner.npc_role = "tavern_owner"
	t.assert_true(tavern_owner.line_for_role().contains("山风") or tavern_owner.line_for_role().contains("祭台"), "tavern owner has tavern ambient line")

	var pedestrian = TownNpc.new()
	pedestrian.npc_role = "unknown_role"
	t.assert_true(pedestrian.line_for_role().length() > 0, "unknown role falls back to pedestrian line")

	var player := Node3D.new()
	player.add_to_group("player")
	vendor.set_nearby_player(player)
	t.assert_true(vendor.has_nearby_player(), "nearby player is tracked")
	vendor.clear_nearby_player(player)
	t.assert_true(not vendor.has_nearby_player(), "nearby player is cleared")

	var walker = TownNpc.new()
	walker.waypoints = [Vector3.ZERO, Vector3(2, 0, 0)]
	walker.current_waypoint_index = 1
	walker.move_speed_mps = 1.0
	walker.position = Vector3.ZERO
	t.assert_true(walker.move_to_next_waypoint(0.5), "walker moves toward waypoint")
	t.assert_true(walker.position.x > 0.0, "walker advances on x axis")

	walker.start_waiting()
	t.assert_true(walker.tick_wait(0.25), "wait is running before duration")
	t.assert_true(not walker.tick_wait(walker.wait_duration_s), "wait completes after duration")

	vendor.free()
	inn_owner.free()
	tavern_owner.free()
	pedestrian.free()
	player.free()
	walker.free()
```

- [ ] **Step 2: Register the failing test**

Modify `tests/test_runner.gd` and insert the new path after `test_dialogue.gd`:

```gdscript
"res://tests/test_dialogue.gd",
"res://tests/test_town_npc.gd",
"res://tests/test_spell_caster.gd",
```

- [ ] **Step 3: Run tests and verify RED**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL because `res://scripts/npc/TownNpc.gd` does not exist.

## Task 2: Implement TownNpc Core

**Files:**
- Create: `scripts/npc/TownNpc.gd`
- Test: `tests/test_town_npc.gd`

- [ ] **Step 1: Add minimal TownNpc implementation**

Create `scripts/npc/TownNpc.gd`:

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

func move_to_next_waypoint(delta: float) -> bool:
	if waypoints.is_empty():
		velocity = Vector3.ZERO
		return false
	var target := waypoints[current_waypoint_index]
	var current := global_position if is_inside_tree() else position
	var offset := target - current
	offset.y = 0.0
	if offset.length() <= 0.05:
		velocity = Vector3.ZERO
		return true
	var step := offset.normalized() * move_speed_mps
	velocity = step
	if is_inside_tree():
		move_and_slide()
	else:
		position += step * delta
	return true

func is_at_waypoint() -> bool:
	if waypoints.is_empty():
		return true
	var current := global_position if is_inside_tree() else position
	var target := waypoints[current_waypoint_index]
	current.y = 0.0
	target.y = 0.0
	return current.distance_to(target) <= 0.1

func advance_waypoint() -> void:
	if not waypoints.is_empty():
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()

func start_waiting() -> void:
	wait_remaining_s = wait_duration_s

func tick_wait(delta: float) -> bool:
	wait_remaining_s = maxf(0.0, wait_remaining_s - delta)
	if wait_remaining_s <= 0.0:
		advance_waypoint()
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

func _on_sense_area_body_entered(body: Node3D) -> void:
	set_nearby_player(body)

func _on_sense_area_body_exited(body: Node3D) -> void:
	clear_nearby_player(body)
```

- [ ] **Step 2: Run tests and verify GREEN**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: all existing tests pass, including `test_town_npc.gd`.

## Task 3: Add Thin Beehave Nodes

**Files:**
- Create: `scripts/npc/ai/HasNearbyPlayerCondition.gd`
- Create: `scripts/npc/ai/IsAtWaypointCondition.gd`
- Create: `scripts/npc/ai/MoveToWaypointAction.gd`
- Create: `scripts/npc/ai/WaitAtWaypointAction.gd`
- Create: `scripts/npc/ai/LookAtPlayerAction.gd`
- Create: `scripts/npc/ai/SpeakAmbientLineAction.gd`

- [ ] **Step 1: Add condition scripts**

Create `scripts/npc/ai/HasNearbyPlayerCondition.gd`:

```gdscript
extends "res://addons/beehave/nodes/leaves/condition.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("has_nearby_player") and actor.has_nearby_player():
		return SUCCESS
	return FAILURE
```

Create `scripts/npc/ai/IsAtWaypointCondition.gd`:

```gdscript
extends "res://addons/beehave/nodes/leaves/condition.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("is_at_waypoint") and actor.is_at_waypoint():
		return SUCCESS
	return FAILURE
```

- [ ] **Step 2: Add action scripts**

Create `scripts/npc/ai/MoveToWaypointAction.gd`:

```gdscript
extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	var delta: float = blackboard.get_value("delta", 0.016)
	if actor.has_method("move_to_next_waypoint") and actor.move_to_next_waypoint(delta):
		return RUNNING
	return FAILURE
```

Create `scripts/npc/ai/WaitAtWaypointAction.gd`:

```gdscript
extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	var delta: float = blackboard.get_value("delta", 0.016)
	if "wait_remaining_s" in actor and actor.wait_remaining_s <= 0.0 and actor.has_method("start_waiting"):
		actor.start_waiting()
	if actor.has_method("tick_wait") and actor.tick_wait(delta):
		return RUNNING
	return SUCCESS
```

Create `scripts/npc/ai/LookAtPlayerAction.gd`:

```gdscript
extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("look_at_player") and actor.look_at_player():
		return SUCCESS
	return FAILURE
```

Create `scripts/npc/ai/SpeakAmbientLineAction.gd`:

```gdscript
extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("speak_context_line"):
		actor.speak_context_line()
		return SUCCESS
	return FAILURE
```

- [ ] **Step 3: Run syntax validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: exit 0.

## Task 4: Create Reusable TownNpc Scene

**Files:**
- Create: `scenes/npc/TownNpc.tscn`
- Modify: `tests/test_town_npc.gd`

- [ ] **Step 1: Add failing scene assertions**

Append this helper call in `tests/test_town_npc.gd` after the core behavior assertions:

```gdscript
	_test_town_npc_scene(t)
```

Add this helper:

```gdscript
func _test_town_npc_scene(t) -> void:
	var scene_path := "res://scenes/npc/TownNpc.tscn"
	t.assert_true(ResourceLoader.exists(scene_path), "TownNpc scene exists")
	if not ResourceLoader.exists(scene_path):
		return
	var packed_scene := load(scene_path)
	t.assert_true(packed_scene is PackedScene, "TownNpc scene loads")
	if not packed_scene is PackedScene:
		return
	var scene = packed_scene.instantiate()
	t.assert_true(scene is TownNpc, "TownNpc scene root uses TownNpc script")
	t.assert_true(scene.get_node_or_null("CollisionShape3D") is CollisionShape3D, "TownNpc has collision shape")
	t.assert_true(scene.get_node_or_null("Visual") is MeshInstance3D, "TownNpc has visible mesh")
	t.assert_true(scene.get_node_or_null("SenseArea") is Area3D, "TownNpc has sense area")
	t.assert_true(scene.get_node_or_null("BehaviorTree") != null, "TownNpc has Beehave tree")
	scene.free()
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL because `scenes/npc/TownNpc.tscn` does not exist.

- [ ] **Step 3: Create `scenes/npc/TownNpc.tscn`**

Use a `CharacterBody3D` root with `TownNpc.gd`, a capsule mesh, a capsule collision shape, a sphere sense area, and a Beehave tree with these branches:

```text
TownNpc
├── CollisionShape3D
├── Visual
├── SenseArea
│   └── CollisionShape3D
└── BehaviorTree
    └── RootSelector
        ├── PlayerBranch
        │   ├── HasNearbyPlayerCondition
        │   ├── LookAtPlayerAction
        │   └── SpeakAmbientLineAction
        ├── WaitBranch
        │   ├── IsAtWaypointCondition
        │   └── WaitAtWaypointAction
        └── PatrolBranch
            └── MoveToWaypointAction
```

Use the same Beehave scene structure style as `scenes/enemies/LesserDemon.tscn`.

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: all tests pass.

## Task 5: Add Town Scene NPC Placement Tests

**Files:**
- Modify: `tests/test_town_showcase.gd`

- [ ] **Step 1: Extend town showcase tests**

In `tests/test_town_showcase.gd`, call `_test_town_npc_ai_nodes(t, town)` from `run()` after `_test_npc_logic_nodes(t, town)`.

Add:

```gdscript
func _test_town_npc_ai_nodes(t, town: Node) -> void:
	t.assert_true(town.has_node("TownNpcGroup"), "TownNpcGroup exists")
	var expected_roles := {
		"TownNpcGroup/MarketVendorCenter": "vendor",
		"TownNpcGroup/MarketVendorLeft": "vendor",
		"TownNpcGroup/InnOwnerAmbient": "inn_owner",
		"TownNpcGroup/TavernOwnerAmbient": "tavern_owner",
		"TownNpcGroup/PedestrianA": "pedestrian",
		"TownNpcGroup/PedestrianB": "pedestrian",
	}
	for npc_path in expected_roles.keys():
		t.assert_true(town.has_node(npc_path), "%s exists" % npc_path)
		var npc = town.get_node_or_null(npc_path)
		t.assert_true(npc is TownNpc, "%s uses TownNpc script" % npc_path)
		if npc is TownNpc:
			t.assert_equal(npc.npc_role, expected_roles[npc_path], "%s has expected role" % npc_path)
	t.assert_equal(town.get_node("Inn/Innkeeper").npc_id, "innkeeper", "Innkeeper quest id remains intact after town AI placement")
	t.assert_equal(town.get_node("Tavern/TavernKeeper").npc_id, "tavern_keeper", "TavernKeeper quest id remains intact after town AI placement")
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: FAIL because `TownNpcGroup` does not exist.

## Task 6: Wire TownNpc Instances Into Town

**Files:**
- Modify: `scenes/town/Town.tscn`

- [ ] **Step 1: Add TownNpc ext_resource**

Add an ext_resource for the reusable town NPC scene:

```ini
[ext_resource type="PackedScene" path="res://scenes/npc/TownNpc.tscn" id="19"]
```

If Godot requires a different resource ID because of local ordering, use the next available ID and update the node instances consistently.

- [ ] **Step 2: Add TownNpcGroup and representative instances**

Add these nodes near the end of `scenes/town/Town.tscn`, before `TownAmbience`:

```ini
[node name="TownNpcGroup" type="Node3D" parent="."]

[node name="MarketVendorCenter" parent="TownNpcGroup" instance=ExtResource("19")]
transform = Transform3D(0.8660254, 0, 0.5, 0, 1, 0, -0.5, 0, 0.8660254, 0.8, 0, 5.2)
npc_role = "vendor"

[node name="MarketVendorLeft" parent="TownNpcGroup" instance=ExtResource("19")]
transform = Transform3D(0.70710677, 0, 0.70710677, 0, 1, 0, -0.70710677, 0, 0.70710677, -2.2, 0, 9.1)
npc_role = "vendor"

[node name="InnOwnerAmbient" parent="TownNpcGroup" instance=ExtResource("19")]
transform = Transform3D(-0.9396926, 0, 0.34202015, 0, 1, 0, -0.34202015, 0, -0.9396926, -10.7, 0, 8.0)
npc_role = "inn_owner"

[node name="TavernOwnerAmbient" parent="TownNpcGroup" instance=ExtResource("19")]
transform = Transform3D(-0.9396926, 0, -0.34202015, 0, 1, 0, 0.34202015, 0, -0.9396926, 8.7, 0, 14.0)
npc_role = "tavern_owner"

[node name="PedestrianA" parent="TownNpcGroup" instance=ExtResource("19")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2, 0, 2)
npc_role = "pedestrian"
waypoints = Array[Vector3]([Vector3(-2, 0, 2), Vector3(-2, 0, 12), Vector3(2, 0, 12), Vector3(2, 0, 2)])

[node name="PedestrianB" parent="TownNpcGroup" instance=ExtResource("19")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4, 0, 18)
npc_role = "pedestrian"
waypoints = Array[Vector3]([Vector3(4, 0, 18), Vector3(8, 0, 20), Vector3(8, 0, 25), Vector3(4, 0, 25)])
```

Keep these instances out of the 3 m main route center where possible. The vendor nodes sit near stalls; pedestrians use short loops along market edges and the south route.

- [ ] **Step 3: Run town tests and verify GREEN**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: all tests pass.

## Task 7: Final Validation and Cleanup

**Files:**
- Review all touched files.

- [ ] **Step 1: Run full test suite**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Expected: exit 0 with `TESTS PASSED: <N> assertions`.

- [ ] **Step 2: Run Godot syntax and scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Expected: exit 0.

- [ ] **Step 3: Inspect git diff**

Run:

```bash
git diff -- scripts/npc scenes/npc scenes/town/Town.tscn tests/test_runner.gd tests/test_town_npc.gd tests/test_town_showcase.gd
```

Expected:

- New `TownNpc.gd` owns town NPC behavior.
- New `scripts/npc/ai/*.gd` nodes are thin Beehave wrappers.
- Existing `NpcDialogue.gd` is unchanged unless a test failure forces a narrowly scoped compatibility fix.
- `Inn/Innkeeper` and `Tavern/TavernKeeper` remain present with original `npc_id` values.

- [ ] **Step 4: Commit implementation**

Run:

```bash
git add scripts/npc scenes/npc scenes/town/Town.tscn tests/test_runner.gd tests/test_town_npc.gd tests/test_town_showcase.gd docs/superpowers/plans/2026-06-10-town-npc-ai.md
git commit -m "feat: add town npc ai"
```

Expected: commit succeeds after tests and validation pass.

## Self-Review

- Spec coverage: Tasks cover reusable `TownNpc`, thin Beehave nodes, `TownNpc.tscn`, town scene placement, role-specific ambient lines, pedestrian waypoints, preservation of quest NPC IDs, and required headless verification.
- Placeholder scan: No implementation step is left incomplete or open-ended; scene resource IDs may be adjusted only if Godot requires a different ext_resource ID.
- Type consistency: The plan consistently uses `TownNpc`, `npc_role`, `last_spoken_line`, `nearby_player`, `waypoints`, `current_waypoint_index`, `move_to_next_waypoint(delta)`, and Beehave `tick(actor, blackboard)` signatures.
