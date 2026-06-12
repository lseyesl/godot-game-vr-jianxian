extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal damage_received(amount: int, source_id: String, current_health: int, max_health: int)
signal died(source_id: String)

@export var target_id := ""
@export var max_health := 3
@export var current_health := 3
@export var minimum_health := 0

var dead := false

func _ready() -> void:
	if current_health <= 0:
		current_health = max_health

func reset() -> void:
	current_health = max_health
	dead = current_health <= minimum_health
	health_changed.emit(current_health, max_health)
	_emit_event_bus_health_changed()

func is_alive() -> bool:
	return current_health > minimum_health

func apply_damage(amount: int, source_id: String = "") -> int:
	if amount <= 0:
		return current_health
	var previous_health := current_health
	current_health = maxi(minimum_health, current_health - amount)
	if current_health != previous_health:
		damage_received.emit(amount, source_id, current_health, max_health)
		health_changed.emit(current_health, max_health)
		_emit_event_bus_damage_received(amount)
		_emit_event_bus_health_changed()
	if previous_health > minimum_health and current_health <= minimum_health and not dead:
		dead = true
		died.emit(source_id)
		_emit_event_bus_died(source_id)
	return current_health

func heal(amount: int) -> int:
	if amount <= 0:
		return current_health
	current_health = mini(max_health, current_health + amount)
	if current_health > minimum_health:
		dead = false
	health_changed.emit(current_health, max_health)
	_emit_event_bus_health_changed()
	return current_health

func _emit_event_bus_damage_received(amount: int) -> void:
	var event_bus := _get_event_bus()
	if event_bus != null and event_bus.has_signal("damage_received"):
		event_bus.damage_received.emit(target_id, amount, current_health, max_health)

func _emit_event_bus_health_changed() -> void:
	var event_bus := _get_event_bus()
	if event_bus != null and event_bus.has_signal("health_changed"):
		event_bus.health_changed.emit(target_id, current_health, max_health)

func _emit_event_bus_died(source_id: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus == null:
		return
	if target_id == "player" and event_bus.has_signal("player_defeated"):
		event_bus.player_defeated.emit(source_id)

func _get_event_bus() -> Node:
	var local_bus := get_parent().get_node_or_null("EventBus") if get_parent() != null else null
	if local_bus != null:
		return local_bus
	if is_inside_tree():
		return get_node_or_null("/root/EventBus")
	return null
