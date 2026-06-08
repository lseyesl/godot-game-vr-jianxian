# AGENTS.md — VR Xianxia Demo (Godot 4.6+)

## Project Overview

PCVR vertical-slice demo built in Godot 4.6+ with GDScript, OpenXR, and Godot XR Tools. Player is a novice sword cultivator who explores a town, receives NPC clues, completes a mountain trial with standing spellcasting, recovers a flying sword, and flies back. ~15 min play session. Chinese-language UI/dialogue throughout.

## Local Project Skills

- Project-local skills live under `agents/skills/`. AI CLI tools that support project skills should scan this directory in addition to their global skill locations.
- `archive-planning-files` is available at `agents/skills/archive-planning-files/SKILL.md`. Use it when the user asks to archive planning files, including triggers such as `归档`, `archive`, `清理规划文件`, or `存档`.

## Verification Commands

```bash
# Initialize or refresh Godot import metadata/cache before tests when assets changed
godot --headless --xr-mode off --path . --import
# Alternative if --import is insufficient in your local Godot version:
godot --headless --xr-mode off --path . --editor --quit

# Run headless unit tests (MUST pass before marking work complete)
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd

# Syntax and scene validation
godot --headless --xr-mode off --path . --check-only --quit
```

Both must exit 0. Expected test output: `TESTS PASSED: <N> assertions`.

**Always use `--xr-mode off`** in headless environments — OpenXR/HMD is unavailable and will emit warnings otherwise.

Run the import command whenever `.glb`, textures, or other imported assets are added or changed, or after `.godot/imported` has been cleaned. This regenerates local `.import` metadata and `.godot/imported` cache files so model resources can load as `PackedScene` in headless tests. Without this step, prefab tests may fail with missing metadata/import-cache errors even when the source `.glb` file exists.

## Architecture

### Autoloads (singleton order in project.godot)
- **EventBus** (`scripts/autoload/EventBus.gd`) — global signal bus. All cross-module communication uses these signals, NOT direct references between gameplay scripts.
- **Game** (`scripts/autoload/Game.gd`) — holds `save_state`, `comfort_settings`, `quest_state`. Provides `advance_quest()` and `apply_comfort_mode()`.

### Module Boundaries
| Directory | Purpose | Base Class |
|-----------|---------|------------|
| `scripts/core/` | QuestState, ComfortSettings, SaveState | RefCounted / Resource |
| `scripts/autoload/` | EventBus, Game singleton | Node |
| `scripts/spells/` | SpellCaster (cooldowns), SpellProjectile | Node / Area3D |
| `scripts/interaction/` | SealEncounter (seal/demon logic) | Node3D |
| `scripts/items/` | FlyingSword (unlock, flight state) | Node3D |
| `scripts/npc/` | NpcDialogue (line/event lookup by quest step) | Node |
| `scripts/player/` | XRPlayer (bridge), DesktopDebugPlayer | Node3D / CharacterBody3D |
| `scripts/ui/` | TaskHud, ComfortSettingsPanel, MainMenu | CanvasLayer / Control |
| `scripts/world/` | TrialTrigger, ReturnToTownTrigger | Area3D |
| `scenes/` | All .tscn scene files (menu, main, town, mountain, player, npc, spells, items, interaction, ui) | — |
| `assets/` | materials (.tres), audio, models, textures | — |
| `tests/` | Headless GDScript unit tests | RefCounted |

### Key Design Patterns

- **Autoload-safe access**: Scripts that may run outside the scene tree (tests, pure logic) use `get_node_or_null("/root/EventBus")` and `get_node_or_null("/root/Game")` with null guards — NEVER assume autoloads exist.
- **Quest FSM**: `QuestState` is a strict state machine. Steps: `start → ask_tavern → go_to_mountain → cleanse_seal → collect_sword → fly_back → complete`. Only valid transition events advance the quest; invalid calls return `false`.
- **Event-driven coupling**: Gameplay scripts emit EventBus signals. UI/listeners connect to EventBus. Avoid direct method calls between gameplay modules.
- **Player group**: Both player controllers add themselves to `"player"` group in `_ready()`. NPC/trigger scripts check `body.is_in_group("player")`.
- **`receive_spell(spell_id)` convention**: Spell targets (currently `SealEncounter`) implement this method. `SpellProjectile` calls it on body enter via `has_method("receive_spell")`.

## Quest State Machine IDs

| Event ID | Transition |
|----------|-----------|
| `talked_to_innkeeper` | start → ask_tavern |
| `talked_to_tavern_keeper` | ask_tavern → go_to_mountain |
| `entered_trial` | go_to_mountain → cleanse_seal |
| `seal_cleansed` | cleanse_seal → collect_sword |
| `sword_collected` | collect_sword → fly_back |
| `returned_to_town` | fly_back → complete |

## Spell IDs

- `spirit_bolt` — basic ranged, 1s cooldown, damages seal
- `guard_charm` — defense buff, 4s cooldown, no seal damage
- `seal_break` — task-specific, 2s cooldown, instantly clears seal

## NPC IDs

- `innkeeper` — advances `start` step
- `tavern_keeper` — advances `ask_tavern` step
- `trial_spirit` — provides hints at `cleanse_seal` step

## Comfort Modes

- `comfort` (default): snap turn, teleport movement, flight vignette on, speed limit 6 m/s, height limit 45 m
- `immersive`: smooth turn, smooth movement, vignette off, speed limit 9 m/s, height limit 60 m
- Unknown mode falls back to `comfort`

## 3D Asset Grid Standard

- Full 3D asset sizing rules live in `docs/art/3d-grid-size-standard.md`.
- Godot `1 unit = 1 meter`; large scene modules align to a 1 m grid, mid-sized props to 0.5 m, and fine non-blocking details to 0.25 m.
- Keep imported model node scale at `(1, 1, 1)` whenever possible; author dimensions in the model file instead of compensating with scene scale.
- VR comfort dimensions are mandatory on gameplay paths: main routes should be 3 m wide, minimum passable paths 1.5 m, and core door openings at least 1.5 m × 2.4 m.

## Test Runner Conventions

- Tests live in `tests/test_*.gd`, each `extends RefCounted` with a `run(t)` method.
- `t` is the test runner providing `assert_true()`, `assert_equal()`, `fail()`.
- Tests must work without autoloads — use `FileAccess.file_exists()` / `ResourceLoader.exists()` guards before loading scripts, and `can_instantiate()` checks before calling `.new()`.
- Node-based classes (extending Node3D, Area3D, etc.) must be `.free()`'d after use in tests.
- New test files must be added to the `test_paths` array in `tests/test_runner.gd`.

## Godot XR Tools Setup

The full Godot XR Tools addon is NOT tracked in this repo (it caused headless Godot startup hangs after cache cleanup). See `docs/setup/xr-tools.md` for local editor installation instructions. For interactive VR dev: install via AssetLib or clone `https://github.com/GodotVR/godot-xr-tools` into `addons/godot-xr-tools`, then enable the addon in Project Settings.

## PCVR Export

- Export preset name: `"PCVR Demo"` (Windows Desktop, x86_64)
- Output: `builds/pcvr/VRXianxiaDemo.exe`
- Export command: `godot --headless --path . --export-release "PCVR Demo" builds/pcvr/VRXianxiaDemo.exe`
- Requires Windows export templates installed for Godot 4.6+

## Headless Environment Limitations

- No HMD detected; OpenXR features untestable in CI/headless
- FPS and VR comfort cannot be measured without a headset
- Manual PCVR acceptance checklist lives in `docs/testing/vr-demo-acceptance.md`
- Performance notes are in `progress.md`

## Git Worktree Rule

All git worktrees MUST be created under `.worktrees/` at the project root:

```bash
git worktree add .worktrees/<branch-name> -b <branch-name>
```

NEVER create worktrees outside `.worktrees/` (e.g. `~/`, `/tmp/`, `~/.config/superpowers/worktrees/`, or any absolute path). This keeps all worktrees co-located with the repo, easy to find and clean up.

`.worktrees/` is gitignored — worktree contents will not pollute the main checkout's git status.

## Mandatory Planning

Requests are classified before planning:

| Classification | Criteria | Plan Required? |
|----------------|----------|----------------|
| **Trivial** | Single-line fix, typo, simple config/value change, one file affected | ❌ No plan needed — just do it |
| **Standard** | 2–4 steps, 1–3 files, clear scope, low risk | ✅ Plan required |
| **Complex** | 5+ steps, 3+ files, architecture impact, or unclear scope | ✅ Plan required |

When a plan is required:

1. **Create a plan** before writing any code.
2. **Persist the plan** to `docs/superpowers/plans/` as a markdown file. Naming convention: `YYYY-MM-DD-<slug>.md` (e.g. `2026-05-22-add-sword-trail.md`).
3. **Plan file must include**: Goal, scope, affected files, step-by-step implementation, and verification criteria.
4. **Update the plan** as work progresses — mark steps done, note deviations.
5. **No implementation without a plan file** — if `docs/superpowers/plans/` does not contain a matching plan, write one first.

## File Conventions

- `.gd` scripts use `class_name` declarations matching PascalCase filenames
- Scenes (.tscn) reference scripts via `ext_resource` paths starting with `res://`
- When moving, renaming, or deleting Godot project files, also check for a same-path `.uid` sidecar file and apply the same operation to it when present (for example, `scripts/main/Main.gd` ⇄ `scripts/main/Main.gd.uid`).
- `export_presets.cfg` IS tracked (not in .gitignore)
- `.godot/`, `.worktrees/`, `*.import`, `*.tmp`, `*.translation` are gitignored
- Asset placeholder dirs (`assets/audio/`, `assets/models/`, `assets/textures/`) contain `.gitkeep`
