# VR 剑仙小镇 / VR Xianxia Demo

A PCVR vertical-slice demo built with **Godot 4.6+**, **OpenXR**, and **Godot XR Tools**. You play as a novice sword cultivator — explore a mountain-foot town, follow NPC clues to a valley trial, cast spells to break a demon seal, recover your flying sword, and ride it home.

**Language:** Chinese UI and dialogue throughout.

## Prerequisites

- [Godot 4.6+](https://godotengine.org/) editor
- A PCVR headset (SteamVR / OpenXR runtime) for VR play
- Godot XR Tools addon — install via AssetLib or clone into `addons/godot-xr-tools` (see [docs/setup/xr-tools.md](docs/setup/xr-tools.md))

## Running

The project is **VR-first**: art scale, interaction distance, comfort rules, and performance targets are designed for PCVR. Day-to-day development can use the desktop simulation player for faster code iteration and basic flow testing, but VR headset checks remain the final acceptance path for comfort, interaction feel, and performance.

```bash
# Open in Godot editor
godot --path .

# Headless test suite
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd

# Syntax / scene validation
godot --headless --xr-mode off --path . --check-only --quit
```

`scenes/main/Main.tscn` selects the active player through `scripts/main/Main.gd`:

- `desktop_simulation` loads `scenes/player/DesktopDebugPlayer.tscn` for non-HMD development.
- `vr` loads `scenes/player/XRPlayer.tscn` for headset testing and PCVR validation.

## Export (PCVR)

```bash
godot --headless --path . --export-release "PCVR Demo" builds/pcvr/VRXianxiaDemo.exe
```

Requires Godot 4.6+ Windows export templates.

## Project Layout

| Path | Contents |
|------|----------|
| `scripts/core/` | Quest state machine, comfort settings, save state |
| `scripts/autoload/` | EventBus (global signals), Game (runtime state) |
| `scripts/main/` | Main scene bootstrapping and player mode selection |
| `scripts/spells/` | Spellcasting cooldowns and projectiles |
| `scripts/interaction/` | Seal encounter logic |
| `scripts/items/` | Flying sword unlock and flight |
| `scripts/npc/` | NPC dialogue by quest step |
| `scripts/player/` | XR player bridge, desktop simulation controller |
| `scripts/ui/` | Task HUD, comfort settings panel, main menu |
| `scripts/world/` | Area triggers (trial, return-to-town) |
| `scenes/` | Godot scene files (.tscn) |
| `assets/` | Materials, audio, models, textures |
| `tests/` | Headless GDScript unit tests |

## Controls

| Action | VR | Desktop Simulation |
|--------|----|---------------|
| Move | XR Tools locomotion | WASD / Arrow keys |
| Fly (after sword unlock) | Flight provider | Space = ascend |
| Cast spell | Controller buttons | — |

## Comfort Modes

- **Comfort** (default): snap turn, teleport, flight vignette, 6 m/s speed cap, 45 m height cap
- **Immersive**: smooth turn, smooth movement, no vignette, 9 m/s speed cap, 60 m height cap

## Documentation

- [Design spec](docs/superpowers/specs/2026-05-19-vr-xianxia-demo-design.md)
- [Implementation plan](docs/superpowers/plans/2026-05-19-vr-xianxia-demo-implementation.md)
- [3D asset grid-size standard](docs/art/3d-grid-size-standard.md)
- [3D model asset checklist](docs/art/3d-model-asset-checklist.md)
- [XR Tools setup](docs/setup/xr-tools.md)
- [VR acceptance checklist](docs/testing/vr-demo-acceptance.md)
- [Agent instructions](AGENTS.md)

## License

This project is licensed under the [MIT License](LICENSE).
