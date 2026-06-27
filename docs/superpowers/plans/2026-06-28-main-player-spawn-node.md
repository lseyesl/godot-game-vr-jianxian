# Main Player Spawn Node Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `PlayerSpawn` empty node to Main and make player spawning use that node by default.

**Architecture:** `Main.gd` will resolve a base spawn position from `player_spawn_path` first, then fall back to the existing `player_spawn_position`. Terrain height adjustment remains in `resolve_player_spawn_position()` so the player still lands above Terrain3D.

**Tech Stack:** Godot 4.6+, GDScript, `.tscn` scene resources, project headless test runner.

---

### Task 1: Cover PlayerSpawn Behavior

**Files:**
- Modify: `tests/test_player_mode.gd`

- [x] **Step 1: Add failing assertions**

Add assertions that `Main.gd` defaults to `PlayerSpawn`, the Main scene contains a `PlayerSpawn` node, and spawning uses a configured spawn node.

- [x] **Step 2: Run tests to verify failure**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Observed: failed on missing `player_spawn_path`, confirming the test covered new behavior.

### Task 2: Implement PlayerSpawn

**Files:**
- Modify: `scripts/main/Main.gd`
- Modify: `scenes/main/Main.tscn`

- [x] **Step 1: Add `player_spawn_path` and resolver**

Add:

```gdscript
@export var player_spawn_path: NodePath = ^"PlayerSpawn"
```

Then use a helper that returns the `Node3D` spawn node's global or local position when present, otherwise `player_spawn_position`.

- [x] **Step 2: Add Main scene node**

Add this node under the Main root:

```ini
[node name="PlayerSpawn" type="Node3D" parent="." unique_id=...]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 6)
```

- [x] **Step 3: Run tests**

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

Observed: PlayerSpawn assertions no longer failed. Full suite still failed on pre-existing dirty `Town.tscn`/`Main.tscn` structure changes and `TownNpc.waypoints`.

- [x] **Step 4: Run scene validation**

Run:

```bash
godot --headless --xr-mode off --path . --check-only --quit
```

Observed: exit 0, with existing Terrain3D mipmap warnings and Beehave debugger messages.
