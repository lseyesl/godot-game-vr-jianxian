# Water Prefabs Design

## Goal

Add reusable water prefabs for lake, river, and waterfall scenes that support runtime water motion, waterfall particles, 3D audio attachment points, and collision/detection areas.

## Scope

Create code-native prefabs under `scenes/prefabs/water/` using Godot built-in meshes, materials, particles, audio players, and areas. The prefabs are intended for placement in town, mountain, and future terrain scenes without requiring external GLB, texture, or audio assets.

Real audio files are out of scope because `assets/audio/` currently has no tracked water audio assets. Each prefab will include a named `AudioStreamPlayer3D` node with tuned defaults and an empty `stream`, so imported audio can be assigned later without restructuring the scenes.

## Architecture

`scripts/world/WaterBody.gd` is the shared runtime component. It exposes water type, flow speed, flow direction, and optional collision/audio toggles. During `_process()`, it advances a `flow_phase` value and pushes it to any material that exposes a `flow_phase` shader parameter.

The visual water surfaces use a shared shader material. The shader creates subtle procedural wave and color motion using `flow_phase`, so rivers and waterfalls visibly move at runtime while lake motion remains slower.

## Prefabs

- `Lake.tscn`: horizontal water surface, broad `WaterArea`, and `AmbientAudio`.
- `RiverStraight.tscn`: rectangular flowing river segment, `WaterArea`, and `WaterAudio`.
- `RiverBend.tscn`: compact bend segment built from two water surfaces, `WaterArea`, and `WaterAudio`.
- `Waterfall.tscn`: vertical falling water sheet, receiving pool, mist/splash particles, `WaterArea`, `SplashArea`, and `WaterfallAudio`.

## Testing

Add `tests/test_water_prefabs.gd` and register it in `tests/test_runner.gd`. Tests verify every prefab loads as a `PackedScene`, instantiates as `Node3D`, has a `WaterBody` script, contains an area with a collision shape, has a 3D audio player, and uses the water material. The waterfall test also verifies particle nodes exist and are enabled.

## Verification

Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```
