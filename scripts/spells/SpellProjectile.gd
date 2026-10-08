extends Area3D
class_name SpellProjectile

@export var spell_id := "spirit_bolt"
@export var speed_mps := 16.0
@export var lifetime_s := 3.0
@export var hit_effect_scene_path := "res://scenes/spells/HitEffect.tscn"

var direction := Vector3.FORWARD
var age := 0.0
var _hit := false

func launch(origin: Vector3, forward: Vector3) -> void:
	global_position = origin + forward.normalized() * 0.65
	direction = forward.normalized()
	age = 0.0
	_hit = false

func _physics_process(delta: float) -> void:
	if _hit:
		return
	var next_position := global_position + direction * speed_mps * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next_position, collision_mask)
	query.collide_with_areas = true
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		global_position = result.position
		_hit_target(result.collider)
	else:
		global_position = next_position
	age += delta
	if age >= lifetime_s:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_hit_target(body)

func _on_area_entered(area: Area3D) -> void:
	_hit_target(area)

func _hit_target(target: Node) -> void:
	if _hit or target.is_in_group("player"):
		return
	if target is Area3D and not target.has_method("receive_spell"):
		if target.get_parent() != null and target.get_parent().has_method("receive_spell"):
			target = target.get_parent()
		else:
			return
	_hit = true
	if target.has_method("receive_spell"):
		target.receive_spell(spell_id)
	_spawn_hit_effect()
	queue_free()

func _spawn_hit_effect() -> void:
	if not is_inside_tree(): return
	if not ResourceLoader.exists(hit_effect_scene_path):
		return
	var packed := load(hit_effect_scene_path) as PackedScene
	if packed == null:
		return
	var effect := packed.instantiate() as Node3D
	if effect == null:
		return
	var parent: Node = get_tree().current_scene if is_inside_tree() and get_tree() != null else null
	if parent == null:
		parent = get_parent()
	if parent == null:
		effect.free()
		return
	parent.add_child(effect)
	effect.global_position = global_position

