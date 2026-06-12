# Playable Loop Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tighten the desktop playable loop by making main player spawning reliable, NPC interaction explicit, player defeat observable, and projectile casting failure non-destructive.

**Architecture:** Keep changes scoped to existing scripts and tests. Reuse the current EventBus pattern for defeat feedback and the existing input action map for `interact`.

**Tech Stack:** Godot 4.6 GDScript, headless test runner, project autoloads.

---

## Scope

- Main scene player spawning should match the safer PlayerTestArena lifecycle.
- NPCs should advance dialogue only when the player presses `interact` while in range.
- Player health reaching zero should emit a player defeat signal.
- Projectile spells should not consume cooldown if projectile creation cannot happen.

## Tasks

- [x] Add regression tests for all four behaviors.
- [x] Implement Main spawn cleanup and tree-safe positioning.
- [x] Implement explicit NPC interaction.
- [x] Add player defeat event emission.
- [x] Make projectile creation failure happen before cooldown consumption.
- [x] Run Godot test runner and scene validation.

## Verification

- `godot --headless --xr-mode off --path . --script res://tests/test_runner.gd`
- `godot --headless --xr-mode off --path . --check-only --quit`
