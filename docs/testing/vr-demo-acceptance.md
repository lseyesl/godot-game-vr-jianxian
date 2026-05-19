# VR Demo Acceptance Checklist

## Automated

- [x] `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd` passes.
- [x] `godot --headless --xr-mode off --path . --check-only --quit` exits 0.
- [ ] PCVR Windows export succeeds. Current machine is missing Godot Windows export templates.

## Main Flow

- [ ] Main menu opens.
- [ ] Comfort mode is default.
- [ ] Immersive mode can be selected.
- [ ] Player can enter town.
- [ ] Inn NPC advances objective to tavern.
- [ ] Tavern NPC advances objective to mountain.
- [ ] Trial trigger advances objective to seal encounter.
- [ ] Spirit bolt weakens the seal/demon encounter.
- [ ] Seal break finishes the seal encounter.
- [ ] Flying sword can be collected.
- [ ] Flight mode unlocks only after sword collection.
- [ ] Player can fly back to town.
- [ ] Return trigger completes the quest.
- [ ] Completion feedback appears and plays sound.

## VR Comfort

- [ ] Snap turn is active in comfort mode.
- [ ] Teleport or comfort movement is active in town.
- [ ] Flight speed is limited in comfort mode.
- [ ] Flight vignette or equivalent comfort effect is active.
- [ ] Smooth movement/turning is available in immersive mode.

## Scene Quality

- [ ] Inn and tavern are enterable.
- [ ] Town looks large from ground level.
- [ ] Town looks large from flight view.
- [ ] Mountain route has visible distant scenery.
- [ ] Flying route frames the town and mountains.
- [ ] No blocking collision traps were found during one full playthrough.

## Environment Notes

- Manual and headset checks are not completed in the current headless environment.
- Godot reports OpenXR/HMD unavailable during plain headless runs; automated CI/headless checks use `--xr-mode off`, and PCVR headset verification remains required later.
- `godot --headless --path . --export-release "PCVR Demo" builds/pcvr/VRXianxiaDemo.exe` was attempted and failed because `windows_debug_x86_64.exe` and `windows_release_x86_64.exe` export templates are not installed for Godot 4.6.2.
