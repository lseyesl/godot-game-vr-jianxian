# Main Flow Acceptance and Completion Feedback Design

## Goal

Make the demo's primary quest flow verifiably complete from first NPC clue through returning to town, and add a lightweight task completion feedback path that can be tested in headless Godot.

## Scope

This pass covers the main quest flow and completion feedback only. It does not add final VR hand action bindings, detailed VFX, authored sound assets, large art replacement, or headset-only comfort acceptance. Those remain later validation and polish passes.

## Current Context

The project already has the strict quest FSM in `QuestState`, event-driven advancement through `Game.advance_quest()`, NPC dialogue events, trial trigger, seal cleansing, flying sword collection, return trigger, spell casting, and player health/combat support.

The remaining gap is that the flow is not covered by one focused acceptance test, and entering the `complete` quest step only changes the objective text. There is no explicit completion event or reusable feedback listener for the main scene.

## Architecture

`Game.advance_quest()` remains the single authority for quest transitions. When a valid event advances the quest into `complete`, `Game` emits explicit completion signals through `EventBus`.

`EventBus` gains completion-focused signals:

- `quest_completed()`
- `completion_feedback_requested(title: String, message: String)`

A new `CompletionFeedback` UI script listens for `completion_feedback_requested`, displays a concise Chinese completion message, records whether feedback has been shown, and optionally triggers an attached audio player if a stream is available. This keeps feedback testable without requiring tracked audio assets.

`Main.tscn` instantiates the completion feedback scene next to `TaskHud`. Existing gameplay modules keep using `Game.advance_quest()` and do not directly reference UI.

## Acceptance Behavior

The automated acceptance test should prove:

- the main quest event sequence advances through every expected step;
- invalid or duplicate completion events do not re-complete the quest;
- objective text reaches `试炼完成，飞剑已归鞘`;
- completing the return step emits exactly one `quest_completed`;
- completing the return step requests feedback with a Chinese title and message;
- the main scene includes both task HUD and completion feedback UI.

The feedback UI test should prove:

- feedback starts hidden;
- calling the request handler updates title and message labels;
- the feedback panel becomes visible;
- repeated completion requests update the same panel rather than creating duplicate UI.

## Error Handling

If `EventBus` is not available, tests and isolated nodes should still instantiate safely. `Game.advance_quest()` already depends on the autoload in normal runtime, so this pass keeps autoload usage in `Game` direct and uses null-guarded access only in UI scripts.

If the feedback scene has no audio stream assigned, it should still display the visual completion state and skip playback without errors.

## Testing

Add focused headless tests:

- `tests/test_main_flow_acceptance.gd` for quest completion signals and main-scene wiring.
- `tests/test_completion_feedback.gd` for the UI feedback component.

Both tests must be registered in `tests/test_runner.gd`. Final verification remains:

```bash
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
godot --headless --xr-mode off --path . --check-only --quit
```

## Out of Scope

- Manual headset validation.
- Windows PCVR export template installation.
- Final authored completion sound.
- Spell VFX and cooldown HUD.
- Large art pass for town, mountain, NPCs, seal, or flying sword.

## Self-Review

- No placeholders remain.
- The design preserves the existing EventBus/Game architecture.
- Completion feedback is explicit, testable, and does not introduce direct gameplay-to-UI references.
- Scope is small enough for one implementation plan.
