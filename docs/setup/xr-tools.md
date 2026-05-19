# Godot XR Tools Setup

This repository keeps the local XR bridge scenes and scripts, but does not vendor the full Godot XR Tools addon as a git submodule.

Reason: in the current headless automation environment, importing the complete addon submodule caused Godot startup/check commands to hang for several minutes after cache cleanup. Keeping the addon external preserves reliable automated verification.

For interactive VR development:

1. Open the project in Godot 4.6+.
2. Install **Godot XR Tools** through AssetLib or clone `https://github.com/GodotVR/godot-xr-tools` into `addons/godot-xr-tools` locally.
3. Enable the addon in Project Settings.
4. Wire the movement/turn/vignette/flight provider nodes to `scenes/player/XRPlayer.tscn` and `scripts/player/XRPlayer.gd`.
5. Keep `scripts/player/XRPlayer.gd` as the bridge for comfort settings and sword flight state.
