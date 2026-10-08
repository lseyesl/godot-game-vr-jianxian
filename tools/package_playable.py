#!/usr/bin/env python3
"""Create a source-only playable snapshot without LFS models or Terrain3D.

Usage: python3 tools/package_playable.py /path/to/new/output
The destination must not exist. No source files are modified.
"""
from pathlib import Path
import re
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
ENTRY_SCENES = [
    "scenes/menu/MainMenu.tscn", "scenes/main/PlayableJourney.tscn",
    "scenes/player/DesktopDebugPlayer.tscn", "scenes/player/XRPlayer.tscn",
    "scenes/items/FlyingSword.tscn", "scenes/interaction/SealEncounter.tscn",
    "scenes/spells/SpellProjectile.tscn", "scenes/spells/HitEffect.tscn",
    "scenes/ui/CompletionFeedback.tscn", "scenes/enemies/LesserDemon.tscn",
]

def package(destination: Path) -> None:
    if destination.exists():
        raise SystemExit("Destination already exists; choose a new directory.")
    selected = {"project.godot", "export_presets.cfg", "openxr_action_map.tres", "README.md", "LICENSE"}
    # Preserve global class registration, including XR Tools' class-based dependencies.
    for base in ["scripts", "addons/godot-xr-tools", "addons/beehave", "tests"]:
        for path in (ROOT / base).rglob("*"):
            if path.is_file() and (path.suffix in {".gd", ".uid", ".svg"} or path.name == "LICENSE"):
                selected.add(path.relative_to(ROOT).as_posix())
    for path in (ROOT / "docs").rglob("*.md"):
        selected.add(path.relative_to(ROOT).as_posix())
    for path in (ROOT / "assets/ui").glob("*.svg"):
        selected.add(path.relative_to(ROOT).as_posix())
    for path in (ROOT / "assets/materials").glob("*"):
        if path.name in {"mat_spell_projectile.tres", "mat_particle_glow.tres", "spell_projectile.gdshader"}:
            selected.add(path.relative_to(ROOT).as_posix())
    # Traverse scene/material references; these are all required and must exist.
    pending = ENTRY_SCENES[:]
    while pending:
        relative = pending.pop()
        if relative in selected:
            continue
        source = ROOT / relative
        if not source.is_file():
            raise SystemExit(f"Missing playable dependency: {relative}")
        selected.add(relative)
        if source.suffix in {".tscn", ".tres"}:
            pending.extend(re.findall(r'path="res://([^"\n]+)"', source.read_text()))
    for relative in selected:
        source = ROOT / relative
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    # Editor icon annotations are optional at runtime, but copied above for clean imports.
    print(f"Packaged {len(selected)} source files into {destination}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    package(Path(sys.argv[1]).resolve())
