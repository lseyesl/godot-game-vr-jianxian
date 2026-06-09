extends CharacterBody3D
class_name LesserDemon

@export var enemy_id := "lesser_demon"
@export var health_component_path: NodePath = ^"HealthComponent"
@export var sight_range_m := 8.0
@export var attack_range_m := 1.5
@export var move_speed_mps := 2.0
@export var attack_damage := 1
@export var attack_cooldown_s := 1.5

var target: Node3D
var attack_cooldown_remaining := 0.0
var defeated := false

func _ready() -> void:
	var health := get_health_component()
	if health != null and health.has_signal("died"):
		health.died.connect(_on_health_died)

func _physics_process(delta: float) -> void:
	tick_attack_cooldown(delta)

func get_health_component() -> Node:
	return get_node_or_null(health_component_path)

func get_spell_damage(spell_id: String) -> int:
	match spell_id:
		"spirit_bolt":
			return 1
		"seal_break":
			return 3
		_:
			return 0

func receive_spell(spell_id: String) -> void:
	var amount := get_spell_damage(spell_id)
	if amount > 0:
		receive_damage(amount, spell_id)

func receive_damage(amount: int, source_id: String = "") -> int:
	var health := get_health_component()
	if health == null or not health.has_method("apply_damage"):
		return 0
	var current: int = health.apply_damage(amount, source_id)
	if current <= 0:
		_on_health_died(source_id)
	return current

func set_target(new_target: Node3D) -> void:
	target = new_target

func find_target() -> bool:
	if target != null and is_instance_valid(target):
		return true
	if not is_inside_tree():
		return false
	var players := get_tree().get_nodes_in_group("player")
	for candidate in players:
		if candidate is Node3D:
			target = candidate
			return true
	return false

func has_target() -> bool:
	return target != null and is_instance_valid(target)

func can_see_target() -> bool:
	return has_target() and _self_position().distance_to(_target_position()) <= sight_range_m

func is_in_attack_range() -> bool:
	return has_target() and _self_position().distance_to(_target_position()) <= attack_range_m

func move_toward_target(delta: float) -> bool:
	if not can_see_target() or is_defeated():
		velocity = Vector3.ZERO
		return false
	var to_target := _target_position() - _self_position()
	to_target.y = 0.0
	if to_target.length() <= attack_range_m:
		velocity = Vector3.ZERO
		return true
	velocity = to_target.normalized() * move_speed_mps
	if is_inside_tree():
		move_and_slide()
	else:
		global_position += velocity * delta
	return true

func try_attack_target() -> bool:
	if is_defeated() or not is_in_attack_range() or attack_cooldown_remaining > 0.0:
		return false
	if target.has_method("receive_damage"):
		target.receive_damage(attack_damage, enemy_id)
	attack_cooldown_remaining = attack_cooldown_s
	return true

func tick_attack_cooldown(delta: float) -> void:
	attack_cooldown_remaining = maxf(0.0, attack_cooldown_remaining - delta)

func is_defeated() -> bool:
	var health := get_health_component()
	if health != null and health.has_method("is_alive"):
		return not health.is_alive()
	return defeated

func _on_health_died(source_id: String = "") -> void:
	if defeated:
		return
	defeated = true
	velocity = Vector3.ZERO
	if not is_inside_tree():
		return
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("enemy_defeated"):
		event_bus.enemy_defeated.emit(enemy_id)

func _self_position() -> Vector3:
	return global_position if is_inside_tree() else position

func _target_position() -> Vector3:
	if target == null:
		return Vector3.ZERO
	return target.global_position if target.is_inside_tree() else target.position
