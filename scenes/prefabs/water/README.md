# Water Prefabs

This folder contains reusable water prefabs for lake, river, and waterfall scenes. They are built from Godot-native meshes and runtime components, so they can be instanced directly in town, mountain, and future terrain scenes without external model assets.

## Prefabs

| Prefab | Use Case | Runtime Features |
| --- | --- | --- |
| `Lake.tscn` | Still or slow-moving ponds and lakes | Animated water shader, `WaterArea`, `AmbientAudio` |
| `RiverStraight.tscn` | Straight river/canal segments | Flow animation, `WaterArea`, `WaterAudio` |
| `RiverBend.tscn` | Turning river segments | Flow animation, `WaterArea`, `WaterAudio` |
| `Waterfall.tscn` | Falling water, mountain vistas, cliffs | Falling water animation, mist particles, splash particles, `WaterArea`, `SplashArea`, `WaterfallAudio` |

## Basic Usage

1. Instance the prefab into the target scene.
2. Move it so the root node sits on the local water origin.
3. Rotate the root node to align the prefab with the terrain or shoreline.
4. Adjust root scale only for broad layout fit. Prefer editing child mesh sizes for final authored variants if exact dimensions matter.
5. Keep `WaterArea` and `SplashArea` aligned with the visible water volume so gameplay detection matches the visual surface.

## Runtime Settings

Each prefab root uses `WaterBody.gd`.

| Property | Meaning |
| --- | --- |
| `water_type` | One of `lake`, `river`, or `waterfall`; used by tests and future gameplay hooks. |
| `flow_speed` | Controls how fast the shader flow phase advances. Use low values for lakes and higher values for rivers/waterfalls. |
| `flow_direction` | 2D shader direction in water UV space. Adjust when rotating or authoring custom river flow. |
| `audio_enabled` | Enables autoplay for child `AudioStreamPlayer3D` nodes when a stream is assigned. |
| `collision_enabled` | Enables/disables child `Area3D` monitoring and collision shapes. |

## Audio

The prefabs include named `AudioStreamPlayer3D` nodes, but no audio stream is assigned because the repository currently has no tracked water audio assets.

To add sound:

1. Import a loopable water sound into `assets/audio/`.
2. Assign it to the prefab audio node:
   - `Lake.tscn`: `AmbientAudio`
   - `RiverStraight.tscn`: `WaterAudio`
   - `RiverBend.tscn`: `WaterAudio`
   - `Waterfall.tscn`: `WaterfallAudio`
3. Tune `unit_size` and `max_distance` for the scene scale.

## Collision And Detection Areas

`WaterArea` is the main water interaction/detection volume. Use it for player overlap checks, water entry effects, or future gameplay reactions.

`Waterfall.tscn` also has `SplashArea`, intended for the waterfall impact zone. Use it for stronger sound, mist, or splash-specific gameplay effects.

These are `Area3D` nodes, not solid physics blockers. Add separate `StaticBody3D` collision if a scene needs physical blocking.

## Materials And Animation

All visible water surfaces use `assets/materials/mat_water_flow.tres`, backed by `assets/materials/water_flow.gdshader`. `WaterBody.gd` updates the shader's `flow_phase` and `flow_direction` parameters each frame.

Waterfall foam and mist visuals use `assets/materials/mat_water_foam.tres` and `GPUParticles3D` nodes.

## Testing

The prefab contract is covered by `tests/test_water_prefabs.gd`. Run:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```
