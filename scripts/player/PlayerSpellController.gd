extends Node
class_name PlayerSpellController

const SpellCasterScript := preload("res://scripts/spells/SpellCaster.gd")

@export var projectile_scene_path := "res://scenes/spells/SpellProjectile.tscn"

var spell_caster: SpellCaster
var last_cast_spell_id := ""
var last_spawned_projectile: Node
var spawned_projectiles: Array[Node] = []

func _ready() -> void:
	_ensure_spell_caster()

func _physics_process(delta: float) -> void:
	tick_cooldowns(delta)

func cast_spell(spell_id: String, origin: Vector3, forward: Vector3) -> bool:
	_ensure_spell_caster()
	if spell_caster == null or not spell_caster.cast(spell_id):
		return false
	last_cast_spell_id = spell_id
	if is_projectile_spell(spell_id):
		var projectile := _spawn_projectile(spell_id, origin, forward)
		if projectile == null:
			return false
	return true

func cast_spell_from_node(spell_id: String, emitter: Node3D) -> bool:
	if emitter == null:
		return false
	var origin := emitter.global_position if emitter.is_inside_tree() else emitter.position
	var forward := -emitter.global_transform.basis.z if emitter.is_inside_tree() else -emitter.transform.basis.z
	return cast_spell(spell_id, origin, forward)

func is_projectile_spell(spell_id: String) -> bool:
	return spell_id == "spirit_bolt" or spell_id == "seal_break"

func get_spawned_projectile_count() -> int:
	return spawned_projectiles.size()

func tick_cooldowns(delta: float) -> void:
	_ensure_spell_caster()
	if spell_caster != null:
		spell_caster.tick_cooldowns(delta)

func _ensure_spell_caster() -> void:
	if spell_caster == null:
		spell_caster = SpellCasterScript.new()
		add_child(spell_caster)

func _spawn_projectile(spell_id: String, origin: Vector3, forward: Vector3) -> Node:
	var packed_scene := load(projectile_scene_path)
	if packed_scene == null or not packed_scene is PackedScene:
		return null
	var projectile = packed_scene.instantiate()
	if "spell_id" in projectile:
		projectile.spell_id = spell_id
	var parent: Node = null
	if is_inside_tree():
		parent = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return null
	parent.add_child(projectile)
	if projectile.has_method("launch") and projectile.is_inside_tree():
		projectile.launch(origin, forward)
	else:
		if projectile is Node3D:
			projectile.position = origin
		if "direction" in projectile:
			projectile.direction = forward.normalized()
		if "age" in projectile:
			projectile.age = 0.0
	last_spawned_projectile = projectile
	spawned_projectiles.append(projectile)
	return projectile
